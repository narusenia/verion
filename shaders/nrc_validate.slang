// Where the neural radiance cache can be trusted (M7 item 5). Each thread takes a random pixel of one tile of a 32 x 32
// grid, follows the path of nrc_collect up to the vertex q where the renderer asks the cache, and adds two estimates of
// the light that reaches q after at least one more scattering: the cache's value, and a physical one that follows
// NRC_VAL_BOUNCES more bounces without the cache. The host compares their means per tile and sends the tiles where they
// differ back to the physical path tracer (params 49..80, one bit per tile).
// params[31] is the samples per tile, params[6] the call number.

#include "include/pt_core.slang"
#include "include/nrc_trace.slang"

static const uint NRC_VAL_BOUNCES = 6;

RWStructuredBuffer<float> nrcVal; // 20: per tile, cache sum, physical sum and sample count, 3 floats

[shader("compute")]
[numthreads(64, 1, 1)]
void nrc_validate(uint3 tid : SV_DispatchThreadID)
{
    uint per = params[31];
    if (tid.x >= 1024u * per)
        return;
    uint tile = tid.x / per;
    Rng rng;
    rng.state = pcg(tid.x ^ pcg(params[6] * 0x9E3779B9u + params[43] * 0x68E31DA4u + 0x7B1D3A5Fu));
    uint w = params[0];
    uint h = params[1];
    uint px = min(uint((float(tile % 32u) + rng.next()) * float(w) / 32.0), w - 1);
    uint py = min(uint((float(tile / 32u) + rng.next()) * float(h) / 32.0), h - 1);
    PathState st = generatePathFor(px, py, params[6] * 1024u * per + tid.x);
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
    float3 cache = nrcQuery(q.p, q.n);
    float3 phys = float3(0.0);
    float3 thr = float3(1.0);
    float3 at = q.p;
    float3 an = q.n;
    for (uint j = 0; j < NRC_VAL_BOUNCES; j++)
    {
        float3 d = cosineDir(an, rng);
        Hit hh = traceClosest(at, d);
        if (!hh.hit)
        {
            phys += thr * float3(pf(20), pf(21), pf(22));
            break;
        }
        NrcVertex r = nrcVertex(hh, at, d);
        if (!r.eligible)
            return; // not comparable: the cache does not cover what follows
        phys += thr * r.albedo * nrcDirect(r, rng);
        thr *= r.albedo;
        at = r.p;
        an = r.n;
    }
    __atomic_add(nrcVal[3 * tile], lum(cache));
    __atomic_add(nrcVal[3 * tile + 1], lum(phys));
    __atomic_add(nrcVal[3 * tile + 2], 1.0);
}
