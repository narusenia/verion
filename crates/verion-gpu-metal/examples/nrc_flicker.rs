//! M7 item 8: the cost of the neural radiance cache's first frame (warm-up) and how much its picture moves from frame
//! to frame, against the physical path tracer at the same samples per frame. Each frame is a fresh accumulation with
//! its own random stream, as in a viewer that restarts on every camera move; the network keeps learning across frames.
//! Run: cargo run --release -p verion-gpu-metal --example nrc_flicker SCENE.gltf [frames] [spp per frame]

use verion_gpu::{Accumulation as _, NrcSettings, RayTracingBackend as _};
use verion_gpu_metal::{MetalContext, Renderer};
use verion_render_io::load_gltf_in;
use verion_scene::{Camera, ColorSpace};

fn lum(p: &[f32; 3]) -> f64 {
    f64::from(0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2])
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let path = args
        .first()
        .expect("usage: nrc_flicker SCENE.gltf [frames] [spp]");
    let frames: usize = args.get(1).and_then(|a| a.parse().ok()).unwrap_or(40);
    let spp: u32 = args.get(2).and_then(|a| a.parse().ok()).unwrap_or(4);
    let mut scene = load_gltf_in(std::path::Path::new(path), ColorSpace::LinearRec709)
        .expect("load")
        .scene;
    if *scene.camera() == Camera::default() {
        scene.frame_camera();
    }
    let ctx = MetalContext::new().expect("Metal GPU");
    let mut r = Renderer::new(&ctx, &scene).expect("renderer");
    for nrc in [None, Some(NrcSettings::default())] {
        r.set_nrc(nrc).expect("nrc");
        let mut images = Vec::new();
        let (mut gpu, mut first_train, mut later_train) = (0.0, 0.0, 0.0);
        for i in 0..frames {
            r.set_seed(i as u32 + 1);
            let mut acc = r.new_accumulation(256, 192, false).expect("accumulation");
            r.accumulate(&mut acc, spp).expect("accumulate");
            gpu += acc.gpu_seconds();
            if i == 0 {
                first_train = acc.train_seconds();
            } else {
                later_train += acc.train_seconds();
            }
            images.push(acc.mean());
        }
        // After the first quarter of the frames, so the warm-up is over.
        let from = frames / 4;
        let pairs = &images[from..];
        let flicker = pairs
            .windows(2)
            .map(|w| {
                let mean = w[0].iter().map(lum).sum::<f64>() / w[0].len() as f64;
                w[0].iter()
                    .zip(&w[1])
                    .map(|(a, b)| (lum(a) - lum(b)).abs())
                    .sum::<f64>()
                    / w[0].len() as f64
                    / mean
            })
            .sum::<f64>()
            / (pairs.len() - 1) as f64;
        let means: Vec<f64> = pairs
            .iter()
            .map(|f| f.iter().map(lum).sum::<f64>() / f.len() as f64)
            .collect();
        let avg = means.iter().sum::<f64>() / means.len() as f64;
        let cv = (means.iter().map(|m| (m - avg).powi(2)).sum::<f64>() / means.len() as f64).sqrt()
            / avg;
        println!(
            "{}: frame render {:.1} ms, first-frame training {:.1} ms, later training {:.1} ms per frame, \
             pixel flicker {:.3} of the mean, whole-image mean varies {:.2}%",
            if nrc.is_some() { "nrc    " } else { "physical" },
            gpu / frames as f64 * 1e3,
            first_train * 1e3,
            later_train / (frames - 1) as f64 * 1e3,
            flicker,
            cv * 100.0
        );
    }
}
