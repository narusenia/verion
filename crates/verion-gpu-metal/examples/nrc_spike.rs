//! M7 item 2: times the NRC network on this GPU and checks that it learns. The target is a smooth function of
//! position and normal (a stand-in for irradiance), so the numbers are about the network, not the renderer.
//! Run: cargo run --release -p verion-gpu-metal --example nrc_spike [samples per step] [steps]

use verion_gpu_metal::{MetalContext, NRC_SAMPLE_WORDS, NrcNet};

fn target(p: [f32; 3], n: [f32; 3]) -> [f32; 3] {
    let s = 0.5 + 0.5 * (3.0 * p[0]).sin() * (2.0 * p[2]).cos();
    let up = 0.5 + 0.5 * n[1];
    [s * up, 0.5 + 0.12 * p[1] * up, 0.2 + 0.4 * s]
}

fn batch(rng: &mut u32, n: usize) -> Vec<[f32; NRC_SAMPLE_WORDS]> {
    let mut next = || {
        *rng = rng.wrapping_mul(747_796_405).wrapping_add(2_891_336_453);
        (*rng >> 8) as f32 / 16_777_216.0
    };
    (0..n)
        .map(|_| {
            let p = [next() * 4.0 - 2.0, next() * 4.0 - 2.0, next() * 4.0 - 2.0];
            let (z, a) = (next() * 2.0 - 1.0, next() * std::f32::consts::TAU);
            let r = (1.0 - z * z).sqrt();
            let nrm = [r * a.cos(), z, r * a.sin()];
            let t = target(p, nrm);
            [
                p[0], p[1], p[2], nrm[0], nrm[1], nrm[2], t[0], t[1], t[2], 1.0, 0.0,
                0.0, // word 9: valid
            ]
        })
        .collect()
}

fn main() {
    let args: Vec<usize> = std::env::args()
        .skip(1)
        .filter_map(|a| a.parse().ok())
        .collect();
    let (per_step, steps) = (
        args.first().copied().unwrap_or(16384),
        args.get(1).copied().unwrap_or(300),
    );
    let ctx = MetalContext::new().expect("Metal GPU");
    let mut nrc = NrcNet::new(&ctx, [-2.0; 3], 4.0).expect("nrc");
    let mut rng = 1u32;
    let mut train_s = Vec::new();
    for step in 1..=steps {
        let s = nrc.train(&batch(&mut rng, per_step)).expect("train");
        train_s.push(s);
        if step % 50 == 0 || step == steps {
            let test = batch(&mut 999, 4096);
            let (y, _) = nrc.infer(&test).expect("infer");
            let rel: f64 = test
                .iter()
                .zip(&y)
                .map(|(q, y)| {
                    (0..3)
                        .map(|c| f64::from((y[c] - q[6 + c]).powi(2) / (y[c] * y[c] + 0.01)))
                        .sum::<f64>()
                        / 3.0
                })
                .sum::<f64>()
                / test.len() as f64;
            println!(
                "step {step:4}: relMSE {rel:.5}, train step {:.3} ms",
                s * 1e3
            );
        }
    }
    train_s.sort_by(f64::total_cmp);
    println!(
        "train step (batch {per_step}): median {:.3} ms",
        train_s[train_s.len() / 2] * 1e3
    );
    let q = batch(&mut 7, 512 * 384);
    let mut inf: Vec<f64> = (0..5).map(|_| nrc.infer(&q).expect("infer").1).collect();
    inf.sort_by(f64::total_cmp);
    println!(
        "inference of {} queries: median {:.3} ms",
        q.len(),
        inf[2] * 1e3
    );
    let t = batch(&mut 5, 6);
    let (y, _) = nrc.infer(&t).expect("infer");
    for (q, y) in t.iter().zip(&y) {
        println!("target {:?} got {:?}", &q[6..9], y);
    }
    println!("network memory: {:.1} MB", nrc.bytes() as f64 / 1e6);
}
