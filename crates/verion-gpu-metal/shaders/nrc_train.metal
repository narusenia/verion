#include <metal_stdlib>
#include <metal_math>
#include <metal_texture>
using namespace metal;

#line 23 "shaders/include/nrc_net.slang"
struct KernelContext_0
{
    uint device* nrcCfg_0;
    float device* trainSamples_0;
    float device* nrcP_0;
    float device* nrcG_0;
};


#line 28
float nrcF_0(uint i_0, KernelContext_0 thread* kernelContext_0)
{

#line 28
    return (as_type<float>((kernelContext_0->nrcCfg_0[i_0])));
}


#line 59
float3 nrcUnit_0(float3 p_0, KernelContext_0 thread* kernelContext_1)
{

#line 59
    float _S1 = nrcF_0(2U, kernelContext_1);

#line 59
    float _S2 = nrcF_0(3U, kernelContext_1);

#line 59
    float _S3 = nrcF_0(4U, kernelContext_1);

#line 59
    float3 _S4 = p_0 - float3(_S1, _S2, _S3);

#line 59
    float _S5 = nrcF_0(5U, kernelContext_1);

#line 59
    return saturate(_S4 * float3(_S5) );
}


#line 35
float nrcLevelRes_0(uint l_0)
{

#line 35
    return floor(16.0f * pow(1.5f, float(l_0)));
}


#line 30
uint nrcHash_0(uint3 c_0, uint level_0)
{
    return ((((c_0.x) ^ (c_0.y * 2654435761U)) ^ (c_0.z * 805459861U)) ^ (level_0 * 2654435761U)) & 32767U;
}


#line 47
void nrcCorner_0(float3 u_0, uint level_1, uint k_0, uint thread* slot_0, float thread* w_0)
{

    float3 s_0 = u_0 * float3(nrcLevelRes_0(level_1)) ;
    float3 f_0 = floor(s_0);
    float3 t_0 = s_0 - f_0;
    uint _S6 = k_0 & 1U;

#line 53
    uint _S7 = (k_0 >> 1U) & 1U;

#line 53
    uint _S8 = (k_0 >> 2U) & 1U;
    uint3 c_1 = uint3(f_0) + uint3(_S6, _S7, _S8);

#line 54
    float _S9;
    if(_S6 != 0U)
    {

#line 55
        _S9 = t_0.x;

#line 55
    }
    else
    {

#line 55
        _S9 = 1.0f - t_0.x;

#line 55
    }

#line 55
    float _S10;

#line 55
    if(_S7 != 0U)
    {

#line 55
        _S10 = t_0.y;

#line 55
    }
    else
    {

#line 55
        _S10 = 1.0f - t_0.y;

#line 55
    }

#line 55
    float _S11 = _S9 * _S10;

#line 55
    if(_S8 != 0U)
    {

#line 55
        _S9 = t_0.z;

#line 55
    }
    else
    {

#line 55
        _S9 = 1.0f - t_0.z;

#line 55
    }

#line 55
    *w_0 = _S11 * _S9;
    *slot_0 = (level_1 * 32768U + nrcHash_0(c_1, level_1)) * 2U;
    return;
}


float nrcSoftplus_0(float x_0)
{

#line 61
    float _S12;

#line 61
    if(x_0 > 20.0f)
    {

#line 61
        _S12 = x_0;

#line 61
    }
    else
    {

#line 61
        _S12 = log(1.0f + exp(x_0));

#line 61
    }

#line 61
    return _S12;
}


#line 37
struct NrcAct_0
{
    array<float, int(19)> x_1;
    array<float, int(32)> a1_0;
    array<float, int(32)> a2_0;
    array<float, int(3)> pre3_0;
    float3 y_0;
};


#line 63
NrcAct_0 nrcForward_0(float3 p_1, float3 n_0, KernelContext_0 thread* kernelContext_2)
{

#line 63
    uint k_1;

#line 63
    float f0_0;

    thread NrcAct_0 a_0;

#line 65
    float3 _S13 = nrcUnit_0(p_1, kernelContext_2);

#line 65
    uint l_1 = 0U;

    for(;;)
    {

#line 67
        if(l_1 < 8U)
        {
        }
        else
        {

#line 67
            break;
        }

#line 67
        k_1 = 0U;

#line 67
        f0_0 = 0.0f;

#line 67
        float f1_0 = 0.0f;


        for(;;)
        {

#line 70
            if(k_1 < 8U)
            {
            }
            else
            {

#line 70
                break;
            }
            thread uint slot_1;
            thread float w_1;
            nrcCorner_0(_S13, l_1, k_1, &slot_1, &w_1);
            float f0_1 = f0_0 + w_1 * *(kernelContext_2->nrcP_0+slot_1);
            float f1_1 = f1_0 + w_1 * *(kernelContext_2->nrcP_0+(slot_1 + 1U));

#line 70
            k_1 = k_1 + 1U;

#line 70
            f0_0 = f0_1;

#line 70
            f1_0 = f1_1;

#line 70
        }

#line 78
        uint _S14 = 2U * l_1;

#line 78
        (&a_0)->x_1[_S14] = f0_0;
        (&a_0)->x_1[_S14 + 1U] = f1_0;

#line 67
        l_1 = l_1 + 1U;

#line 67
    }

#line 67
    k_1 = 0U;

#line 81
    for(;;)
    {

#line 81
        if(k_1 < 3U)
        {
        }
        else
        {

#line 81
            break;
        }

#line 82
        (&a_0)->x_1[16U + k_1] = n_0[k_1];

#line 81
        k_1 = k_1 + 1U;

#line 81
    }

#line 81
    uint j_0 = 0U;

    for(;;)
    {

#line 83
        if(j_0 < 32U)
        {
        }
        else
        {

#line 83
            break;
        }
        float device* _S15 = kernelContext_2->nrcP_0+(524896U + j_0);

#line 85
        k_1 = 0U;

#line 85
        f0_0 = *_S15;
        for(;;)
        {

#line 86
            if(k_1 < 19U)
            {
            }
            else
            {

#line 86
                break;
            }

#line 87
            float s_1 = f0_0 + *(kernelContext_2->nrcP_0+(524288U + j_0 * 19U + k_1)) * (&a_0)->x_1[k_1];

#line 86
            k_1 = k_1 + 1U;

#line 86
            f0_0 = s_1;

#line 86
        }

        (&a_0)->a1_0[j_0] = max(f0_0, 0.0f);

#line 83
        j_0 = j_0 + 1U;

#line 83
    }

#line 83
    j_0 = 0U;

#line 90
    for(;;)
    {

#line 90
        if(j_0 < 32U)
        {
        }
        else
        {

#line 90
            break;
        }
        float device* _S16 = kernelContext_2->nrcP_0+(525952U + j_0);

#line 92
        k_1 = 0U;

#line 92
        f0_0 = *_S16;
        for(;;)
        {

#line 93
            if(k_1 < 32U)
            {
            }
            else
            {

#line 93
                break;
            }

#line 94
            float s_2 = f0_0 + *(kernelContext_2->nrcP_0+(524928U + j_0 * 32U + k_1)) * (&a_0)->a1_0[k_1];

#line 93
            k_1 = k_1 + 1U;

#line 93
            f0_0 = s_2;

#line 93
        }

        (&a_0)->a2_0[j_0] = max(f0_0, 0.0f);

#line 90
        j_0 = j_0 + 1U;

#line 90
    }

#line 90
    uint o_0 = 0U;

#line 97
    for(;;)
    {

#line 97
        if(o_0 < 3U)
        {
        }
        else
        {

#line 97
            break;
        }
        float device* _S17 = kernelContext_2->nrcP_0+(526080U + o_0);

#line 99
        k_1 = 0U;

#line 99
        f0_0 = *_S17;
        for(;;)
        {

#line 100
            if(k_1 < 32U)
            {
            }
            else
            {

#line 100
                break;
            }

#line 101
            float s_3 = f0_0 + *(kernelContext_2->nrcP_0+(525984U + o_0 * 32U + k_1)) * (&a_0)->a2_0[k_1];

#line 100
            k_1 = k_1 + 1U;

#line 100
            f0_0 = s_3;

#line 100
        }

        (&a_0)->pre3_0[o_0] = f0_0;
        (&a_0)->y_0[o_0] = nrcSoftplus_0(f0_0);

#line 97
        o_0 = o_0 + 1U;

#line 97
    }

#line 105
    return a_0;
}



void nrcAddWave_0(uint index_0, float v_0, bool valid_0, KernelContext_0 thread* kernelContext_3)
{

#line 110
    float _S18;

    if(valid_0)
    {

#line 112
        _S18 = v_0;

#line 112
    }
    else
    {

#line 112
        _S18 = 0.0f;

#line 112
    }

#line 112
    float s_4 = simd_sum(_S18);
    bool _S19 = simd_is_first();

#line 113
    if(_S19)
    {

#line 114
        float _S20 = atomic_fetch_add_explicit(((atomic_float device*)(kernelContext_3->nrcG_0+index_0)), s_4, memory_order_relaxed);

#line 113
    }

    return;
}


void nrcTrainSample_0(float3 p_2, float3 n_1, float3 target_0, bool valid_1, KernelContext_0 thread* kernelContext_4)
{

#line 119
    float sig_0;

#line 119
    float _S21;

#line 119
    uint j_1;

#line 119
    NrcAct_0 _S22 = nrcForward_0(p_2, n_1, kernelContext_4);


    float _S23 = 1.0f / max(float(kernelContext_4->nrcCfg_0[int(0)]), 1.0f);
    thread array<float, int(3)> dy_0;

#line 123
    uint o_1 = 0U;
    for(;;)
    {

#line 124
        if(o_1 < 3U)
        {
        }
        else
        {

#line 124
            break;
        }


        float g_0 = 2.0f * (_S22.y_0[o_1] - target_0[o_1]) / (_S22.y_0[o_1] * _S22.y_0[o_1] + 0.0099999997764825821f) * _S23;

#line 124
        uint _S24 = o_1;

#line 129
        if((_S22.pre3_0[o_1]) > 20.0f)
        {

#line 129
            sig_0 = 1.0f;

#line 129
        }
        else
        {

#line 129
            sig_0 = 1.0f / (1.0f + exp(- _S22.pre3_0[_S24]));

#line 129
        }

#line 129
        uint _S25 = o_1;
        if(valid_1)
        {

#line 130
            _S21 = g_0 * sig_0;

#line 130
        }
        else
        {

#line 130
            _S21 = 0.0f;

#line 130
        }

#line 130
        dy_0[_S25] = _S21;

#line 124
        o_1 = o_1 + 1U;

#line 124
    }

#line 132
    thread array<float, int(32)> d2_0;

#line 132
    uint i_1 = 0U;
    for(;;)
    {

#line 133
        if(i_1 < 32U)
        {
        }
        else
        {

#line 133
            break;
        }

#line 133
        o_1 = 0U;

#line 133
        sig_0 = 0.0f;


        for(;;)
        {

#line 136
            if(o_1 < 3U)
            {
            }
            else
            {

#line 136
                break;
            }

#line 137
            float s_5 = sig_0 + dy_0[o_1] * *(kernelContext_4->nrcP_0+(525984U + o_1 * 32U + i_1));

#line 136
            o_1 = o_1 + 1U;

#line 136
            sig_0 = s_5;

#line 136
        }

#line 136
        uint _S26 = i_1;

        if((_S22.a2_0[i_1]) > 0.0f)
        {

#line 138
            _S21 = sig_0;

#line 138
        }
        else
        {

#line 138
            _S21 = 0.0f;

#line 138
        }

#line 138
        d2_0[_S26] = _S21;

#line 133
        i_1 = i_1 + 1U;

#line 133
    }

#line 133
    o_1 = 0U;

#line 140
    for(;;)
    {

#line 140
        if(o_1 < 3U)
        {
        }
        else
        {

#line 140
            break;
        }

#line 140
        uint _S27 = o_1;

#line 140
        nrcAddWave_0(526080U + o_1, dy_0[_S27], valid_1, kernelContext_4);

#line 140
        i_1 = 0U;


        for(;;)
        {

#line 143
            if(i_1 < 32U)
            {
            }
            else
            {

#line 143
                break;
            }

#line 143
            nrcAddWave_0(525984U + o_1 * 32U + i_1, dy_0[_S27] * _S22.a2_0[i_1], valid_1, kernelContext_4);

#line 143
            i_1 = i_1 + 1U;

#line 143
        }

#line 140
        o_1 = o_1 + 1U;

#line 140
    }

#line 146
    thread array<float, int(32)> d1_0;

#line 146
    i_1 = 0U;
    for(;;)
    {

#line 147
        if(i_1 < 32U)
        {
        }
        else
        {

#line 147
            break;
        }

#line 147
        j_1 = 0U;

#line 147
        sig_0 = 0.0f;


        for(;;)
        {

#line 150
            if(j_1 < 32U)
            {
            }
            else
            {

#line 150
                break;
            }

#line 151
            float s_6 = sig_0 + d2_0[j_1] * *(kernelContext_4->nrcP_0+(524928U + j_1 * 32U + i_1));

#line 150
            j_1 = j_1 + 1U;

#line 150
            sig_0 = s_6;

#line 150
        }

#line 150
        uint _S28 = i_1;

        if((_S22.a1_0[i_1]) > 0.0f)
        {

#line 152
            _S21 = sig_0;

#line 152
        }
        else
        {

#line 152
            _S21 = 0.0f;

#line 152
        }

#line 152
        d1_0[_S28] = _S21;

#line 147
        i_1 = i_1 + 1U;

#line 147
    }

#line 147
    j_1 = 0U;

#line 154
    for(;;)
    {

#line 154
        if(j_1 < 32U)
        {
        }
        else
        {

#line 154
            break;
        }

#line 154
        uint _S29 = j_1;

#line 154
        nrcAddWave_0(525952U + j_1, d2_0[_S29], valid_1, kernelContext_4);

#line 154
        i_1 = 0U;


        for(;;)
        {

#line 157
            if(i_1 < 32U)
            {
            }
            else
            {

#line 157
                break;
            }

#line 157
            nrcAddWave_0(524928U + j_1 * 32U + i_1, d2_0[_S29] * _S22.a1_0[i_1], valid_1, kernelContext_4);

#line 157
            i_1 = i_1 + 1U;

#line 157
        }

#line 154
        j_1 = j_1 + 1U;

#line 154
    }

#line 160
    thread array<float, int(16)> dx_0;

#line 160
    i_1 = 0U;
    for(;;)
    {

#line 161
        if(i_1 < 16U)
        {
        }
        else
        {

#line 161
            break;
        }

#line 162
        dx_0[i_1] = 0.0f;

#line 161
        i_1 = i_1 + 1U;

#line 161
    }

#line 161
    j_1 = 0U;

    for(;;)
    {

#line 163
        if(j_1 < 32U)
        {
        }
        else
        {

#line 163
            break;
        }

#line 163
        uint _S30 = j_1;

#line 163
        nrcAddWave_0(524896U + j_1, d1_0[_S30], valid_1, kernelContext_4);

#line 163
        i_1 = 0U;


        for(;;)
        {

#line 166
            if(i_1 < 19U)
            {
            }
            else
            {

#line 166
                break;
            }
            uint _S31 = 524288U + j_1 * 19U + i_1;

#line 168
            nrcAddWave_0(_S31, d1_0[_S30] * _S22.x_1[i_1], valid_1, kernelContext_4);
            if(i_1 < 16U)
            {

#line 170
                dx_0[i_1] = dx_0[i_1] + d1_0[_S30] * *(kernelContext_4->nrcP_0+_S31);

#line 169
            }

#line 166
            i_1 = i_1 + 1U;

#line 166
        }

#line 163
        j_1 = j_1 + 1U;

#line 163
    }

#line 173
    if(!valid_1)
    {

#line 174
        return;
    }

#line 174
    float3 _S32 = nrcUnit_0(p_2, kernelContext_4);

#line 174
    uint l_2 = 0U;

    for(;;)
    {

#line 176
        if(l_2 < 8U)
        {
        }
        else
        {

#line 176
            break;
        }

#line 176
        uint k_2 = 0U;

        for(;;)
        {

#line 178
            if(k_2 < 8U)
            {
            }
            else
            {

#line 178
                break;
            }
            thread uint slot_2;
            thread float w_2;
            nrcCorner_0(_S32, l_2, k_2, &slot_2, &w_2);
            uint _S33 = 2U * l_2;

#line 183
            float _S34 = atomic_fetch_add_explicit(((atomic_float device*)(kernelContext_4->nrcG_0+slot_2)), w_2 * dx_0[_S33], memory_order_relaxed);
            float _S35 = atomic_fetch_add_explicit(((atomic_float device*)(kernelContext_4->nrcG_0+(slot_2 + 1U))), w_2 * dx_0[_S33 + 1U], memory_order_relaxed);

#line 178
            k_2 = k_2 + 1U;

#line 178
        }

#line 176
        l_2 = l_2 + 1U;

#line 176
    }

#line 187
    return;
}


#line 8 "shaders/nrc_train.slang"
[[kernel]] void nrc_train(uint3 tid_0 [[thread_position_in_grid]], uint device* nrcCfg_1 [[buffer(4)]], float device* trainSamples_1 [[buffer(5)]], float device* nrcP_1 [[buffer(0)]], float device* nrcG_1 [[buffer(1)]])
{

#line 8
    thread KernelContext_0 kernelContext_5;

#line 8
    (&kernelContext_5)->nrcCfg_0 = nrcCfg_1;

#line 8
    (&kernelContext_5)->trainSamples_0 = trainSamples_1;

#line 8
    (&kernelContext_5)->nrcP_0 = nrcP_1;

#line 8
    (&kernelContext_5)->nrcG_0 = nrcG_1;

    uint _S36 = tid_0.x;

#line 10
    bool valid_2 = _S36 < nrcCfg_1[int(0)];
    uint b_0 = _S36 * 12U;

#line 11
    float3 p_3;
    if(valid_2)
    {

#line 12
        p_3 = float3((&kernelContext_5)->trainSamples_0[b_0], (&kernelContext_5)->trainSamples_0[b_0 + 1U], (&kernelContext_5)->trainSamples_0[b_0 + 2U]);

#line 12
    }
    else
    {

#line 12
        p_3 = float3(0.0f, 0.0f, 0.0f);

#line 12
    }

#line 12
    float3 n_2;
    if(valid_2)
    {

#line 13
        n_2 = float3((&kernelContext_5)->trainSamples_0[b_0 + 3U], (&kernelContext_5)->trainSamples_0[b_0 + 4U], (&kernelContext_5)->trainSamples_0[b_0 + 5U]);

#line 13
    }
    else
    {

#line 13
        n_2 = float3(0.0f, 1.0f, 0.0f);

#line 13
    }

#line 13
    float3 t_1;
    if(valid_2)
    {

#line 14
        t_1 = float3((&kernelContext_5)->trainSamples_0[b_0 + 6U], (&kernelContext_5)->trainSamples_0[b_0 + 7U], (&kernelContext_5)->trainSamples_0[b_0 + 8U]);

#line 14
    }
    else
    {

#line 14
        t_1 = float3(0.0f, 0.0f, 0.0f);

#line 14
    }

#line 14
    nrcTrainSample_0(p_3, n_2, t_1, valid_2, &kernelContext_5);

    return;
}

