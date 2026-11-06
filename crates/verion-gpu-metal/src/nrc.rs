//! Neural radiance cache network (M7, REQ-ACC-004): the hash grid and MLP of `shaders/include/nrc_net.slang`,
//! with its training step and batch inference. The path tracer reads the same buffers inline.

use objc2_metal::{
    MTLBuffer, MTLCommandBuffer, MTLCommandEncoder, MTLCommandQueue, MTLComputeCommandEncoder,
    MTLComputePipelineState, MTLDevice, MTLResourceOptions, MTLSize,
};

use crate::{
    Error, MetalContext, Obj,
    renderer::{pipeline, upload},
};

const TRAIN_MSL: &str = include_str!("../shaders/nrc_train.metal");
const ADAM_MSL: &str = include_str!("../shaders/nrc_adam.metal");
const INFER_MSL: &str = include_str!("../shaders/nrc_infer.metal");

/// Floats per training sample or query: position, normal, target (queries ignore it), 3 pad.
pub const NRC_SAMPLE_WORDS: usize = 12;
// Mirrors the constants of nrc_net.slang.
const LEVELS: usize = 8;
const TABLE: usize = 32768;
const F: usize = 2;
const IN: usize = LEVELS * F + 3;
const H: usize = 32;
const GRID: usize = LEVELS * TABLE * F;
const W1: usize = GRID;
const PARAMS: usize = W1 + H * IN + H + H * H + H + 3 * H + 3;
const LR_TABLE: f32 = 1e-2;
const LR_MLP: f32 = 1e-2;

pub struct NrcNet {
    ctx: MetalContext,
    p: Obj<dyn MTLBuffer>,
    g: Obj<dyn MTLBuffer>,
    m: Obj<dyn MTLBuffer>,
    v: Obj<dyn MTLBuffer>,
    train: Obj<dyn MTLComputePipelineState>,
    adam: Obj<dyn MTLComputePipelineState>,
    infer: Obj<dyn MTLComputePipelineState>,
    bounds: [f32; 4],
    step: u32,
}

fn zeros(ctx: &MetalContext, floats: usize) -> Result<Obj<dyn MTLBuffer>, Error> {
    let len = floats * 4;
    ctx.check_fits(len)?;
    ctx.device
        .newBufferWithLength_options(len, MTLResourceOptions::StorageModeShared)
        .ok_or(Error::Resource("nrc buffer"))
}

impl NrcNet {
    /// A fresh network for points inside the cube from `min` with side `extent` (points outside are clamped to it).
    pub fn new(ctx: &MetalContext, min: [f32; 3], extent: f32) -> Result<Self, Error> {
        // Deterministic init: tiny grid features, He-uniform MLP weights, zero biases (the output's start low).
        let mut state = 0x1234_5678u32;
        let mut uniform = move || {
            state = state.wrapping_mul(747_796_405).wrapping_add(2_891_336_453);
            (state >> 8) as f32 / 16_777_216.0 * 2.0 - 1.0
        };
        let mut init = vec![0f32; PARAMS];
        for x in &mut init[..GRID] {
            *x = uniform() * 1e-4;
        }
        let mut at = W1;
        for (fan_in, weights, biases) in [(IN, H * IN, H), (H, H * H, H), (H, 3 * H, 3)] {
            let bound = (6.0 / fan_in as f32).sqrt();
            for x in &mut init[at..at + weights] {
                *x = uniform() * bound;
            }
            at += weights + biases;
        }
        // The output is a softplus; start it near zero, as light is, rather than at 0.69.
        init[PARAMS - 3..].fill(-3.0);
        Ok(Self {
            ctx: ctx.clone(),
            p: upload(ctx, &init)?,
            g: zeros(ctx, PARAMS)?,
            m: zeros(ctx, PARAMS)?,
            v: zeros(ctx, PARAMS)?,
            train: pipeline(ctx, TRAIN_MSL, "nrc_train")?,
            adam: pipeline(ctx, ADAM_MSL, "nrc_adam")?,
            infer: pipeline(ctx, INFER_MSL, "nrc_infer")?,
            bounds: [min[0], min[1], min[2], 1.0 / extent],
            step: 0,
        })
    }

    /// The parameters, which the path tracer binds where the ReSTIR reservoirs would go.
    pub(crate) fn params(&self) -> &Obj<dyn MTLBuffer> {
        &self.p
    }

    /// The step the next `train_buffer` call takes (from 1); the collect kernel uses it to vary its random numbers.
    pub(crate) fn next_step(&self) -> u32 {
        self.step + 1
    }

    /// GPU memory of the network, the gradients and the optimizer state.
    pub fn bytes(&self) -> usize {
        4 * PARAMS * 4
    }

    fn cfg(&self, count: usize, step: u32) -> Result<Obj<dyn MTLBuffer>, Error> {
        let b = self.bounds;
        upload(
            &self.ctx,
            &[
                count as u32,
                step,
                b[0].to_bits(),
                b[1].to_bits(),
                b[2].to_bits(),
                b[3].to_bits(),
                LR_TABLE.to_bits(),
                LR_MLP.to_bits(),
            ],
        )
    }

    fn dispatch(
        &self,
        pipe: &Obj<dyn MTLComputePipelineState>,
        buffers: &[(usize, &Obj<dyn MTLBuffer>)],
        threads: usize,
    ) -> Result<f64, Error> {
        let cb = self
            .ctx
            .queue
            .commandBuffer()
            .ok_or(Error::Resource("command buffer"))?;
        let enc = cb
            .computeCommandEncoder()
            .ok_or(Error::Resource("compute encoder"))?;
        enc.setComputePipelineState(pipe);
        // SAFETY: indices follow the declaration order of the Slang kernels (P, G, M, V, cfg, then the kernel's own).
        unsafe {
            for (i, b) in buffers {
                enc.setBuffer_offset_atIndex(Some(b), 0, *i);
            }
        }
        enc.dispatchThreads_threadsPerThreadgroup(
            MTLSize {
                width: threads,
                height: 1,
                depth: 1,
            },
            MTLSize {
                width: 64,
                height: 1,
                depth: 1,
            },
        );
        enc.endEncoding();
        cb.commit();
        cb.waitUntilCompleted();
        Ok(cb.GPUEndTime() - cb.GPUStartTime())
    }

    /// One Adam step on a batch of samples (target = the cache's value there). Returns the GPU seconds.
    pub fn train(&mut self, samples: &[[f32; NRC_SAMPLE_WORDS]]) -> Result<f64, Error> {
        let data = upload(&self.ctx, samples)?;
        self.train_buffer(&data, samples.len())
    }

    /// `train` on `count` samples already in a GPU buffer (invalid ones, word 9 below 0.5, are skipped).
    pub(crate) fn train_buffer(
        &mut self,
        data: &Obj<dyn MTLBuffer>,
        count: usize,
    ) -> Result<f64, Error> {
        self.step += 1;
        let cfg = self.cfg(count, self.step)?;
        let t = self.dispatch(
            &self.train,
            &[(0, &self.p), (1, &self.g), (4, &cfg), (5, data)],
            count.next_multiple_of(64),
        )?;
        let a = self.dispatch(
            &self.adam,
            &[
                (0, &self.p),
                (1, &self.g),
                (2, &self.m),
                (3, &self.v),
                (4, &cfg),
            ],
            PARAMS,
        )?;
        Ok(t + a)
    }

    /// The network's value at each query (position and normal used). Returns it with the GPU seconds.
    pub fn infer(
        &self,
        queries: &[[f32; NRC_SAMPLE_WORDS]],
    ) -> Result<(Vec<[f32; 3]>, f64), Error> {
        let cfg = self.cfg(queries.len(), 0)?;
        let data = upload(&self.ctx, queries)?;
        let out = zeros(&self.ctx, queries.len() * 3)?;
        let t = self.dispatch(
            &self.infer,
            // nrc_infer declares only P, cfg, queries, out, so Slang numbers them 0..3.
            &[(0, &self.p), (1, &cfg), (2, &data), (3, &out)],
            queries.len(),
        )?;
        let mut v = vec![[0f32; 3]; queries.len()];
        // SAFETY: `out` is shared memory of 3 floats per query, finished by the wait above.
        unsafe {
            std::ptr::copy_nonoverlapping(
                out.contents().as_ptr().cast::<[f32; 3]>(),
                v.as_mut_ptr(),
                v.len(),
            );
        }
        Ok((v, t))
    }
}
