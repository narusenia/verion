// Training samples for the neural radiance cache (M7, REQ-ACC-004). One thread follows one short path the way the
// renderer reaches the cache: a camera ray hits a diffuse surface, a cosine-sampled bounce reaches the vertex q (where
// the renderer asks the cache), and q is the sample's location. Its target is what reaches q after at least one more
// scattering: a few more cosine-sampled bounces, each vertex adding the light sampled there (never its own emission, which
// the renderer's light sampling at q covers) and the last one the cache's value (self-learning: the cache bootstraps on
// itself, the light sampling supplies the new information); the uniform sky when a bounce leaves the scene. A thread whose path
// meets a surface the cache does not cover (metal, glass, coat, sheen) writes an invalid sample. params[31] is the
// thread count, params[6] the step; the network is bound where ReSTIR's reservoirs would be (see pt_core.slang).

#include "include/pt_core.slang"
#include "include/nrc_trace.slang"

static const uint NRC_TRAIN_BOUNCES = 4;

RWStructuredBuffer<float> nrcSamples; // 20: 12 words per thread (position, normal, target rgb, word 9 = 1 when valid)

[shader("compute")]
[numthreads(64, 1, 1)]
void nrc_collect(uint3 tid : SV_DispatchThreadID)
{
    uint t = tid.x;
    if (t >= params[31])
        return;
    uint o = t * NRC_SAMPLE_WORDS;
    nrcSamples[o + 9] = 0.0;
    Rng rng;
    rng.state = pcg(t ^ pcg(params[6] * 0x9E3779B9u + params[43] * 0x68E31DA4u + 0x2545F491u));
    uint px = min(uint(rng.next() * float(params[0])), params[0] - 1);
    uint py = min(uint(rng.next() * float(params[1])), params[1] - 1);
    PathState st = generatePathFor(px, py, params[6] * params[31] + t);
    Hit h0 = traceClosest(st.org, st.dir);
    if (!h0.hit)
        return;
    NrcVertex v0 = nrcVertex(h0, st.org, st.dir);
    if (!v0.eligible)
        return;
    float3 d1 = cosineDir(v0.n, rng);
    Hit h1 = traceClosest(v0.p, d1);
    if (!h1.hit)
        return;
    NrcVertex q = nrcVertex(h1, v0.p, d1);
    if (!q.eligible)
        return;
    // From q the path goes on for NRC_TRAIN_BOUNCES bounces: each vertex adds the light sampled there (weighted by the
    // albedos passed so far), and the cache stands in for the rest at the last one. Every bounce the path unrolls
    // multiplies the cache's own error by one more albedo, which is what keeps a bright closed room from running away.
    float3 target = float3(0.0);
    float3 thr = float3(1.0);
    float3 at = q.p;
    float3 an = q.n;
    for (uint j = 0; j < NRC_TRAIN_BOUNCES; j++)
    {
        float3 d = cosineDir(an, rng);
        Hit h = traceClosest(at, d);
        if (!h.hit)
        {
            target += thr * float3(pf(20), pf(21), pf(22));
            break;
        }
        NrcVertex r = nrcVertex(h, at, d);
        if (!r.eligible)
            return;
        target += thr * r.albedo * nrcDirect(r, rng);
        thr *= r.albedo;
        at = r.p;
        an = r.n;
        if (j + 1 == NRC_TRAIN_BOUNCES)
            target += thr * nrcQuery(r.p, r.n);
    }
    for (uint k = 0; k < 3; k++)
    {
        nrcSamples[o + k] = q.p[k];
        nrcSamples[o + 3 + k] = q.n[k];
        nrcSamples[o + 6 + k] = target[k];
    }
    nrcSamples[o + 9] = 1.0;
}
