// Neural radiance cache network (M7, REQ-ACC-004): a multiresolution hash grid (NRC_LEVELS levels, NRC_F features each)
// feeding a small MLP (NRC_IN -> NRC_H -> NRC_H -> 3) that maps a point and its normal to the diffuse-weighted
// indirect incident radiance there (E / pi, view independent). Everything is fp32 in flat float buffers so Metal and
// Vulkan run the same source. Training is Adam on a relative L2 loss; the gradients of one batch are summed with
// float atomics (wave sums first for the MLP weights) and applied by nrc_adam.

static const uint NRC_LEVELS = 8;
static const uint NRC_F = 2;
static const uint NRC_TABLE = 32768;                       // entries per level (power of two)
static const uint NRC_IN = NRC_LEVELS * NRC_F + 3;         // grid features and the normal
static const uint NRC_H = 32;
static const uint NRC_GRID_FLOATS = NRC_LEVELS * NRC_TABLE * NRC_F;
static const uint NRC_W1 = NRC_GRID_FLOATS;
static const uint NRC_B1 = NRC_W1 + NRC_H * NRC_IN;
static const uint NRC_W2 = NRC_B1 + NRC_H;
static const uint NRC_B2 = NRC_W2 + NRC_H * NRC_H;
static const uint NRC_W3 = NRC_B2 + NRC_H;
static const uint NRC_B3 = NRC_W3 + 3 * NRC_H;
static const uint NRC_PARAMS = NRC_B3 + 3;
static const uint NRC_SAMPLE_WORDS = 12;                   // position xyz, normal xyz, target rgb, 3 pad

RWStructuredBuffer<float> nrcP;  // network parameters: hash tables, then W1 b1 W2 b2 W3 b3 (row-major, [out][in])
RWStructuredBuffer<float> nrcG;  // gradient sums of the batch, same layout
RWStructuredBuffer<float> nrcM;  // Adam first moment
RWStructuredBuffer<float> nrcV;  // Adam second moment
StructuredBuffer<uint> nrcCfg;   // 0 sample count, 1 step (from 1), 2..4 bounds min xyz, 5 inverse extent, 6 table lr, 7 mlp lr (floats as bits)

float nrcF(uint i) { return asfloat(nrcCfg[i]); }

uint nrcHash(uint3 c, uint level)
{
    return ((c.x * 1u) ^ (c.y * 2654435761u) ^ (c.z * 805459861u) ^ (level * 0x9E3779B1u)) & (NRC_TABLE - 1u);
}

float nrcLevelRes(uint l) { return floor(16.0 * pow(1.5, float(l))); }

struct NrcAct
{
    float x[NRC_IN];
    float a1[NRC_H];
    float a2[NRC_H];
    float pre3[3];
    float3 y;
};

// Trilinear weights and table slots of one level, for a point in the unit cube.
void nrcCorner(float3 u, uint level, uint k, out uint slot, out float w)
{
    float res = nrcLevelRes(level);
    float3 s = u * res;
    float3 f = floor(s);
    float3 t = s - f;
    uint3 o = uint3(k & 1u, (k >> 1) & 1u, (k >> 2) & 1u);
    uint3 c = uint3(f) + o;
    w = (o.x != 0 ? t.x : 1.0 - t.x) * (o.y != 0 ? t.y : 1.0 - t.y) * (o.z != 0 ? t.z : 1.0 - t.z);
    slot = (level * NRC_TABLE + nrcHash(c, level)) * NRC_F;
}

float3 nrcUnit(float3 p) { return saturate((p - float3(nrcF(2), nrcF(3), nrcF(4))) * nrcF(5)); }

float nrcSoftplus(float x) { return x > 20.0 ? x : log(1.0 + exp(x)); }

NrcAct nrcForward(float3 p, float3 n)
{
    NrcAct a;
    float3 u = nrcUnit(p);
    for (uint l = 0; l < NRC_LEVELS; l++)
    {
        float f0 = 0.0, f1 = 0.0;
        for (uint k = 0; k < 8; k++)
        {
            uint slot;
            float w;
            nrcCorner(u, l, k, slot, w);
            f0 += w * nrcP[slot];
            f1 += w * nrcP[slot + 1];
        }
        a.x[2 * l] = f0;
        a.x[2 * l + 1] = f1;
    }
    for (uint i = 0; i < 3; i++)
        a.x[NRC_LEVELS * NRC_F + i] = n[i];
    for (uint j = 0; j < NRC_H; j++)
    {
        float s = nrcP[NRC_B1 + j];
        for (uint i = 0; i < NRC_IN; i++)
            s += nrcP[NRC_W1 + j * NRC_IN + i] * a.x[i];
        a.a1[j] = max(s, 0.0);
    }
    for (uint j = 0; j < NRC_H; j++)
    {
        float s = nrcP[NRC_B2 + j];
        for (uint i = 0; i < NRC_H; i++)
            s += nrcP[NRC_W2 + j * NRC_H + i] * a.a1[i];
        a.a2[j] = max(s, 0.0);
    }
    for (uint o = 0; o < 3; o++)
    {
        float s = nrcP[NRC_B3 + o];
        for (uint i = 0; i < NRC_H; i++)
            s += nrcP[NRC_W3 + o * NRC_H + i] * a.a2[i];
        a.pre3[o] = s;
        a.y[o] = nrcSoftplus(s);
    }
    return a;
}

float3 nrcQuery(float3 p, float3 n) { return nrcForward(p, n).y; }

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
    float invN = 1.0 / max(float(nrcCfg[0]), 1.0);
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
