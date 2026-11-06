// One NRC training batch: forward and backward of nrcCfg[0] samples, gradients summed into nrcG (then nrc_adam).
RWStructuredBuffer<float> nrcP;  // network parameters
RWStructuredBuffer<float> nrcG;  // gradient sums of the batch, same layout
RWStructuredBuffer<float> nrcM;  // Adam first moment (nrc_adam)
RWStructuredBuffer<float> nrcV;  // Adam second moment (nrc_adam)
StructuredBuffer<uint> nrcCfg;   // 0 sample count, 1 step (from 1), 2..4 bounds min xyz, 5 inverse extent, 6 table lr, 7 mlp lr (floats as bits)
float4 nrcBounds() { return float4(asfloat(nrcCfg[2]), asfloat(nrcCfg[3]), asfloat(nrcCfg[4]), asfloat(nrcCfg[5])); }
uint nrcCount() { return nrcCfg[0]; }
#include "include/nrc_net.slang"
#include "include/nrc_backward.slang"

StructuredBuffer<float> trainSamples; // 12 words per sample: position, normal, target rgb, word 9 = 1 when valid

[shader("compute")]
[numthreads(64, 1, 1)]
void nrc_train(uint3 tid : SV_DispatchThreadID)
{
    bool valid = tid.x < nrcCfg[0] && trainSamples[tid.x * NRC_SAMPLE_WORDS + 9] > 0.5;
    uint b = tid.x * NRC_SAMPLE_WORDS;
    float3 p = valid ? float3(trainSamples[b], trainSamples[b + 1], trainSamples[b + 2]) : float3(0, 0, 0);
    float3 n = valid ? float3(trainSamples[b + 3], trainSamples[b + 4], trainSamples[b + 5]) : float3(0, 1, 0);
    float3 t = valid ? float3(trainSamples[b + 6], trainSamples[b + 7], trainSamples[b + 8]) : float3(0, 0, 0);
    nrcTrainSample(p, n, t, valid);
}
