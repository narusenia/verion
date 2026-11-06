// NRC backward pass (M7): the gradients of one batch into nrcG. The includer declares nrcG and `uint nrcCount()`
// (the batch size) and includes nrc_net.slang before this file.

void nrcAddWave(uint index, float v, bool valid)
{
    float s = WaveActiveSum(valid ? v : 0.0);
    if (WaveIsFirstLane())
        __atomic_add(nrcG[index], s);
}

// Forward and backward of one training sample. All lanes of the wave must call it (the sums are wave-wide);
// `valid` false contributes nothing.
void nrcTrainSample(float3 p, float3 n, float3 target, bool valid)
{
    NrcAct a = nrcForward(p, n);
    float invN = 1.0 / max(float(nrcCount()), 1.0);
    float dy[3];
    for (uint o = 0; o < 3; o++)
    {
        // Relative L2: (y - t)^2 / (y^2 + 0.01), the denominator held constant as in the NRC paper.
        float d = a.y[o] - target[o];
        float g = 2.0 * d / (a.y[o] * a.y[o] + 0.01) * invN;
        float sig = a.pre3[o] > 20.0 ? 1.0 : 1.0 / (1.0 + exp(-a.pre3[o]));
        dy[o] = valid ? g * sig : 0.0;
    }
    float d2[NRC_H];
    for (uint i = 0; i < NRC_H; i++)
    {
        float s = 0.0;
        for (uint o = 0; o < 3; o++)
            s += dy[o] * nrcP[NRC_W3 + o * NRC_H + i];
        d2[i] = a.a2[i] > 0.0 ? s : 0.0;
    }
    for (uint o = 0; o < 3; o++)
    {
        nrcAddWave(NRC_B3 + o, dy[o], valid);
        for (uint i = 0; i < NRC_H; i++)
            nrcAddWave(NRC_W3 + o * NRC_H + i, dy[o] * a.a2[i], valid);
    }
    float d1[NRC_H];
    for (uint i = 0; i < NRC_H; i++)
    {
        float s = 0.0;
        for (uint j = 0; j < NRC_H; j++)
            s += d2[j] * nrcP[NRC_W2 + j * NRC_H + i];
        d1[i] = a.a1[i] > 0.0 ? s : 0.0;
    }
    for (uint j = 0; j < NRC_H; j++)
    {
        nrcAddWave(NRC_B2 + j, d2[j], valid);
        for (uint i = 0; i < NRC_H; i++)
            nrcAddWave(NRC_W2 + j * NRC_H + i, d2[j] * a.a1[i], valid);
    }
    float dx[NRC_LEVELS * NRC_F];
    for (uint i = 0; i < NRC_LEVELS * NRC_F; i++)
        dx[i] = 0.0;
    for (uint j = 0; j < NRC_H; j++)
    {
        nrcAddWave(NRC_B1 + j, d1[j], valid);
        for (uint i = 0; i < NRC_IN; i++)
        {
            nrcAddWave(NRC_W1 + j * NRC_IN + i, d1[j] * a.x[i], valid);
            if (i < NRC_LEVELS * NRC_F)
                dx[i] += d1[j] * nrcP[NRC_W1 + j * NRC_IN + i];
        }
    }
    if (!valid)
        return;
    float3 u = nrcUnit(p);
    for (uint l = 0; l < NRC_LEVELS; l++)
    {
        for (uint k = 0; k < 8; k++)
        {
            uint slot;
            float w;
            nrcCorner(u, l, k, slot, w);
            __atomic_add(nrcG[slot], w * dx[2 * l]);
            __atomic_add(nrcG[slot + 1], w * dx[2 * l + 1]);
        }
    }
}
