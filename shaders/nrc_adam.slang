// Adam step over every NRC parameter; clears the gradient for the next batch.
RWStructuredBuffer<float> nrcP;
RWStructuredBuffer<float> nrcG;
RWStructuredBuffer<float> nrcM;
RWStructuredBuffer<float> nrcV;
StructuredBuffer<uint> nrcCfg;   // as in nrc_train
float4 nrcBounds() { return float4(asfloat(nrcCfg[2]), asfloat(nrcCfg[3]), asfloat(nrcCfg[4]), asfloat(nrcCfg[5])); }
#include "include/nrc_net.slang"

[shader("compute")]
[numthreads(64, 1, 1)]
void nrc_adam(uint3 tid : SV_DispatchThreadID)
{
    uint i = tid.x;
    if (i >= NRC_PARAMS)
        return;
    float g = nrcG[i];
    nrcG[i] = 0.0;
    float step = float(nrcCfg[1]);
    float lr = asfloat(nrcCfg[i < NRC_GRID_FLOATS ? 6 : 7]);
    float m = 0.9 * nrcM[i] + 0.1 * g;
    float v = 0.999 * nrcV[i] + 0.001 * g * g;
    nrcM[i] = m;
    nrcV[i] = v;
    float mh = m / (1.0 - pow(0.9, step));
    float vh = v / (1.0 - pow(0.999, step));
    nrcP[i] -= lr * mh / (sqrt(vh) + 1e-8);
}
