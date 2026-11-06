// One NRC training batch: forward and backward of nrcCfg[0] samples, gradients summed into nrcG (then nrc_adam).
#include "include/nrc_net.slang"

StructuredBuffer<float> trainSamples;

[shader("compute")]
[numthreads(64, 1, 1)]
void nrc_train(uint3 tid : SV_DispatchThreadID)
{
    bool valid = tid.x < nrcCfg[0];
    uint b = tid.x * NRC_SAMPLE_WORDS;
    float3 p = valid ? float3(trainSamples[b], trainSamples[b + 1], trainSamples[b + 2]) : float3(0, 0, 0);
    float3 n = valid ? float3(trainSamples[b + 3], trainSamples[b + 4], trainSamples[b + 5]) : float3(0, 1, 0);
    float3 t = valid ? float3(trainSamples[b + 6], trainSamples[b + 7], trainSamples[b + 8]) : float3(0, 0, 0);
    nrcTrainSample(p, n, t, valid);
}
