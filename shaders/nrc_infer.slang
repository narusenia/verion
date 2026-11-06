// Batch inference of the NRC for nrcCfg[0] queries (position, normal), 12 words each; writes rgb to inferOut.
#include "include/nrc_net.slang"

StructuredBuffer<float> inferQueries;
RWStructuredBuffer<float> inferOut;

[shader("compute")]
[numthreads(64, 1, 1)]
void nrc_infer(uint3 tid : SV_DispatchThreadID)
{
    if (tid.x >= nrcCfg[0])
        return;
    uint b = tid.x * NRC_SAMPLE_WORDS;
    float3 y = nrcQuery(float3(inferQueries[b], inferQueries[b + 1], inferQueries[b + 2]), float3(inferQueries[b + 3], inferQueries[b + 4], inferQueries[b + 5]));
    for (uint o = 0; o < 3; o++)
        inferOut[3 * tid.x + o] = y[o];
}
