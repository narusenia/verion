#!/bin/sh
# Time to quality on scenes where indirect light dominates (M7 item 1, REQ-ACC-004, REQ-PERF-001): renders each scene
# with the variants below over a ladder of sample counts and SEEDS random streams (16 by default), compares every image
# with a high-sample reference render (exr_diff mae/mean) next to its GPU time, and reports the mean and the 95%
# confidence interval over the seeds. The time to quality is the time to the error the physical path tracer has at
# 128 spp. A variant that trains (NRC) writes `train_s` into its metrics; it is added to the time, and the report
# shows the peak GPU memory next to it.
# Needs a Metal GPU; not run in CI.
# Variants: reference, interactive+gi (ReSTIR GI), nrc (--mode interactive --nrc).
# Usage: eval_nrc.sh [reference spp]. Env: SEEDS (16), VARIANTS (default "reference interactive+gi nrc"), SCENES, APPEND=1
# (keep the runs already in runs.csv, to add one variant).
# Output: target/eval-nrc/{runs.csv,report.md}
set -eu
out=target/eval-nrc
ref_spp=${1:-16384}
seeds=${SEEDS:-16}
variants=${VARIANTS:-"reference interactive+gi nrc"}
scenes=${SCENES:-"scenes/indoor.gltf scenes/cornell_diffuse.gltf scenes/cornell_box.gltf scenes/many_lights.gltf"}
size="--width 512 --height 384"
mkdir -p "$out"
cargo build --release -q -p verion-render-cli
cargo build --release -q -p verion-render-io --example exr_diff
cli=./target/release/render-cli
diff() { ./target/release/examples/exr_diff "$1" "$2" | grep -o 'mae/mean [^ ]*' | awk '{print $2}'; }
[ -n "${APPEND:-}" ] || echo "scene,variant,spp,seed,gpu_s,train_s,peak_bytes,mae" > "$out/runs.csv"
for scene in $scenes; do
  name=$(basename "$scene" .gltf)
  # The reference has its own stream (seed 1000), so it is not correlated with the seeds under test.
  [ -f "$out/$name-ref.exr" ] || $cli "$scene" -o "$out/$name-ref.exr" $size --spp "$ref_spp" --seed 1000
  for spp in 4 16 64 128 256; do
    for variant in $variants; do
      mode=${variant%+gi}; flag=
      [ "$variant" = interactive+gi ] && flag=--restir-gi
      [ "$variant" = nrc ] && { mode=interactive; flag=--nrc; }
      seed=1
      while [ "$seed" -le "$seeds" ]; do
        f="$out/run"
        $cli "$scene" -o "$f.exr" $size --spp "$spp" --mode "$mode" $flag --seed "$seed" --metrics "$f.json"
        echo "$name,$variant,$spp,$seed,$(jq -r '[.gpu_s, (.train_s // 0), .gpu_peak_bytes] | @csv' "$f.json"),$(diff "$out/$name-ref.exr" "$f.exr")" >> "$out/runs.csv"
        seed=$((seed + 1))
      done
    done
  done
done
python3 -I - "$out/runs.csv" <<'PY' | tee "$out/report.md"
import csv, math, statistics, sys
from collections import defaultdict

T95 = {1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571, 6: 2.447, 7: 2.365, 8: 2.306, 9: 2.262, 10: 2.228,
       11: 2.201, 12: 2.179, 13: 2.160, 14: 2.145, 15: 2.131, 20: 2.086, 30: 2.042}  # Student t, two-sided 95%
rows = defaultdict(list)
for r in csv.DictReader(open(sys.argv[1])):
    rows[(r["scene"], r["variant"], int(r["spp"]))].append(
        (float(r["gpu_s"]) + float(r["train_s"]), float(r["mae"]), float(r["peak_bytes"])))

def stat(xs):
    n = len(xs)
    if n < 2:
        return statistics.fmean(xs), 0.0
    t = T95.get(n - 1) or T95[min((k for k in T95 if k >= n - 1), default=30)]
    return statistics.fmean(xs), t * statistics.stdev(xs) / math.sqrt(n)

def reach(curve, target):
    """Time at which the (spp-ordered) curve of (time, error) reaches `target`, log-log interpolated; None if never."""
    for (t0, e0), (t1, e1) in zip(curve, curve[1:]):
        if e0 >= target >= e1:
            f = (math.log(e0) - math.log(target)) / (math.log(e0) - math.log(e1))
            return math.exp(math.log(t0) + f * (math.log(t1) - math.log(t0)))
    return None

scenes = sorted({k[0] for k in rows})
variants = sorted({k[1] for k in rows}, key=lambda v: (v != "reference", v))
spps = sorted({k[2] for k in rows})
print("| scene | variant | spp | time s (mean ± 95% CI) | mae/mean (mean ± 95% CI) | peak MB |")
print("|---|---|---|---|---|---|")
curves = {}
for s in scenes:
    for v in variants:
        pts = []
        for spp in spps:
            xs = rows[(s, v, spp)]
            (t, tc), (e, ec), peak = stat([x[0] for x in xs]), stat([x[1] for x in xs]), max(x[2] for x in xs)
            pts.append((t, e, ec))
            print(f"| {s} | {v} | {spp} | {t:.4f} ± {tc:.4f} | {e:.4f} ± {ec:.4f} | {peak / 1e6:.0f} |")
        curves[(s, v)] = pts
print()
print("Time to the error the physical path tracer has at 128 spp (the interval takes the error's own interval; the ratio is against that same time of the physical path tracer):")
print()
print("| scene | variant | time s | range s | speedup |")
print("|---|---|---|---|---|")
for s in scenes:
    ref = curves[(s, "reference")]
    i = spps.index(128)
    target, base = ref[i][1], ref[i][0]
    for v in variants:
        c = curves[(s, v)]
        mid = reach([(t, e) for t, e, _ in c], target)
        lo = reach([(t, e - ec) for t, e, ec in c], target)  # error at its lowest: reached sooner
        hi = reach([(t, e + ec) for t, e, ec in c], target)
        if mid is None:
            print(f"| {s} | {v} | not reached | | |")
        else:
            rng = f"{lo:.3f} to {hi:.3f}" if lo and hi else "open"
            print(f"| {s} | {v} | {mid:.3f} | {rng} | {base / mid:.2f}x |")
PY
