#include <metal_stdlib>
#include <metal_math>
#include <metal_texture>
using namespace metal;

#line 3 "shaders/nrc_train.slang"
struct KernelContext_0
{
    uint device* nrcCfg_0;
    float device* trainSamples_0;
    float device* nrcP_0;
    float device* nrcG_0;
};


#line 7
float4 nrcBounds_0(KernelContext_0 thread* kernelContext_0)
{

#line 7
    return float4((as_type<float>((kernelContext_0->nrcCfg_0[int(2)]))), (as_type<float>((kernelContext_0->nrcCfg_0[int(3)]))), (as_type<float>((kernelContext_0->nrcCfg_0[int(4)]))), (as_type<float>((kernelContext_0->nrcCfg_0[int(5)]))));
}


#line 53 "shaders/include/nrc_net.slang"
float3 nrcUnit_0(float3 p_0, KernelContext_0 thread* kernelContext_1)
{

#line 53
    float4 _S1 = nrcBounds_0(kernelContext_1);

#line 53
    return saturate((p_0 - _S1.xyz) * float3(_S1.w) );
}


#line 29
float nrcLevelRes_0(uint l_0)
{

#line 29
    return floor(16.0f * pow(1.5f, float(l_0)));
}


#line 24
uint nrcHash_0(uint3 c_0, uint level_0)
{
    return ((((c_0.x) ^ (c_0.y * 2654435761U)) ^ (c_0.z * 805459861U)) ^ (level_0 * 2654435761U)) & 32767U;
}


#line 41
void nrcCorner_0(float3 u_0, uint level_1, uint k_0, uint thread* slot_0, float thread* w_0)
{

    float3 s_0 = u_0 * float3(nrcLevelRes_0(level_1)) ;
    float3 f_0 = floor(s_0);
    float3 t_0 = s_0 - f_0;
    uint _S2 = k_0 & 1U;

#line 47
    uint _S3 = (k_0 >> 1U) & 1U;

#line 47
    uint _S4 = (k_0 >> 2U) & 1U;
    uint3 c_1 = uint3(f_0) + uint3(_S2, _S3, _S4);

#line 48
    float _S5;
    if(_S2 != 0U)
    {

#line 49
        _S5 = t_0.x;

#line 49
    }
    else
    {

#line 49
        _S5 = 1.0f - t_0.x;

#line 49
    }

#line 49
    float _S6;

#line 49
    if(_S3 != 0U)
    {

#line 49
        _S6 = t_0.y;

#line 49
    }
    else
    {

#line 49
        _S6 = 1.0f - t_0.y;

#line 49
    }

#line 49
    float _S7 = _S5 * _S6;

#line 49
    if(_S4 != 0U)
    {

#line 49
        _S5 = t_0.z;

#line 49
    }
    else
    {

#line 49
        _S5 = 1.0f - t_0.z;

#line 49
    }

#line 49
    *w_0 = _S7 * _S5;
    *slot_0 = (level_1 * 32768U + nrcHash_0(c_1, level_1)) * 2U;
    return;
}


float nrcSoftplus_0(float x_0)
{

#line 55
    float _S8;

#line 55
    if(x_0 > 20.0f)
    {

#line 55
        _S8 = x_0;

#line 55
    }
    else
    {

#line 55
        _S8 = log(1.0f + exp(x_0));

#line 55
    }

#line 55
    return _S8;
}


#line 31
struct NrcAct_0
{
    array<float, int(19)> x_1;
    array<float, int(32)> a1_0;
    array<float, int(32)> a2_0;
    array<float, int(3)> pre3_0;
    float3 y_0;
};


#line 57
NrcAct_0 nrcForward_0(float3 p_1, float3 n_0, KernelContext_0 thread* kernelContext_2)
{

#line 57
    uint k_1;

#line 57
    float f0_0;

    thread NrcAct_0 a_0;

#line 59
    float3 _S9 = nrcUnit_0(p_1, kernelContext_2);

#line 59
    uint l_1 = 0U;

    for(;;)
    {

#line 61
        if(l_1 < 8U)
        {
        }
        else
        {

#line 61
            break;
        }

#line 61
        k_1 = 0U;

#line 61
        f0_0 = 0.0f;

#line 61
        float f1_0 = 0.0f;


        for(;;)
        {

#line 64
            if(k_1 < 8U)
            {
            }
            else
            {

#line 64
                break;
            }
            thread uint slot_1;
            thread float w_1;
            nrcCorner_0(_S9, l_1, k_1, &slot_1, &w_1);
            float f0_1 = f0_0 + w_1 * *(kernelContext_2->nrcP_0+slot_1);
            float f1_1 = f1_0 + w_1 * *(kernelContext_2->nrcP_0+(slot_1 + 1U));

#line 64
            k_1 = k_1 + 1U;

#line 64
            f0_0 = f0_1;

#line 64
            f1_0 = f1_1;

#line 64
        }

#line 72
        uint _S10 = 2U * l_1;

#line 72
        (&a_0)->x_1[_S10] = f0_0;
        (&a_0)->x_1[_S10 + 1U] = f1_0;

#line 61
        l_1 = l_1 + 1U;

#line 61
    }

#line 61
    k_1 = 0U;

#line 75
    for(;;)
    {

#line 75
        if(k_1 < 3U)
        {
        }
        else
        {

#line 75
            break;
        }

#line 76
        (&a_0)->x_1[16U + k_1] = n_0[k_1];

#line 75
        k_1 = k_1 + 1U;

#line 75
    }

#line 75
    uint j_0 = 0U;

    for(;;)
    {

#line 77
        if(j_0 < 32U)
        {
        }
        else
        {

#line 77
            break;
        }
        float device* _S11 = kernelContext_2->nrcP_0+(524896U + j_0);

#line 79
        k_1 = 0U;

#line 79
        f0_0 = *_S11;
        for(;;)
        {

#line 80
            if(k_1 < 19U)
            {
            }
            else
            {

#line 80
                break;
            }

#line 81
            float s_1 = f0_0 + *(kernelContext_2->nrcP_0+(524288U + j_0 * 19U + k_1)) * (&a_0)->x_1[k_1];

#line 80
            k_1 = k_1 + 1U;

#line 80
            f0_0 = s_1;

#line 80
        }

        (&a_0)->a1_0[j_0] = max(f0_0, 0.0f);

#line 77
        j_0 = j_0 + 1U;

#line 77
    }

#line 77
    j_0 = 0U;

#line 84
    for(;;)
    {

#line 84
        if(j_0 < 32U)
        {
        }
        else
        {

#line 84
            break;
        }
        float device* _S12 = kernelContext_2->nrcP_0+(525952U + j_0);

#line 86
        k_1 = 0U;

#line 86
        f0_0 = *_S12;
        for(;;)
        {

#line 87
            if(k_1 < 32U)
            {
            }
            else
            {

#line 87
                break;
            }

#line 88
            float s_2 = f0_0 + *(kernelContext_2->nrcP_0+(524928U + j_0 * 32U + k_1)) * (&a_0)->a1_0[k_1];

#line 87
            k_1 = k_1 + 1U;

#line 87
            f0_0 = s_2;

#line 87
        }

        (&a_0)->a2_0[j_0] = max(f0_0, 0.0f);

#line 84
        j_0 = j_0 + 1U;

#line 84
    }

#line 84
    uint o_0 = 0U;

#line 91
    for(;;)
    {

#line 91
        if(o_0 < 3U)
        {
        }
        else
        {

#line 91
            break;
        }
        float device* _S13 = kernelContext_2->nrcP_0+(526080U + o_0);

#line 93
        k_1 = 0U;

#line 93
        f0_0 = *_S13;
        for(;;)
        {

#line 94
            if(k_1 < 32U)
            {
            }
            else
            {

#line 94
                break;
            }

#line 95
            float s_3 = f0_0 + *(kernelContext_2->nrcP_0+(525984U + o_0 * 32U + k_1)) * (&a_0)->a2_0[k_1];

#line 94
            k_1 = k_1 + 1U;

#line 94
            f0_0 = s_3;

#line 94
        }

        (&a_0)->pre3_0[o_0] = f0_0;
        (&a_0)->y_0[o_0] = nrcSoftplus_0(f0_0);

#line 91
        o_0 = o_0 + 1U;

#line 91
    }

#line 99
    return a_0;
}


#line 8 "shaders/nrc_train.slang"
uint nrcCount_0(KernelContext_0 thread* kernelContext_3)
{

#line 8
    return kernelContext_3->nrcCfg_0[int(0)];
}


#line 4 "shaders/include/nrc_backward.slang"
void nrcAddWave_0(uint index_0, float v_0, bool valid_0, KernelContext_0 thread* kernelContext_4)
{

#line 4
    float _S14;

    if(valid_0)
    {

#line 6
        _S14 = v_0;

#line 6
    }
    else
    {

#line 6
        _S14 = 0.0f;

#line 6
    }

#line 6
    float s_4 = simd_sum(_S14);
    bool _S15 = simd_is_first();

#line 7
    if(_S15)
    {

#line 8
        float _S16 = atomic_fetch_add_explicit(((atomic_float device*)(kernelContext_4->nrcG_0+index_0)), s_4, memory_order_relaxed);

#line 7
    }

    return;
}


void nrcTrainSample_0(float3 p_2, float3 n_1, float3 target_0, bool valid_1, KernelContext_0 thread* kernelContext_5)
{

#line 13
    float sig_0;

#line 13
    float _S17;

#line 13
    uint j_1;

#line 13
    NrcAct_0 _S18 = nrcForward_0(p_2, n_1, kernelContext_5);

#line 13
    uint _S19 = nrcCount_0(kernelContext_5);


    float _S20 = 1.0f / max(float(_S19), 1.0f);
    thread array<float, int(3)> dy_0;

#line 17
    uint o_1 = 0U;
    for(;;)
    {

#line 18
        if(o_1 < 3U)
        {
        }
        else
        {

#line 18
            break;
        }


        float g_0 = 2.0f * (_S18.y_0[o_1] - target_0[o_1]) / (_S18.y_0[o_1] * _S18.y_0[o_1] + 0.0099999997764825821f) * _S20;

#line 18
        uint _S21 = o_1;

#line 23
        if((_S18.pre3_0[o_1]) > 20.0f)
        {

#line 23
            sig_0 = 1.0f;

#line 23
        }
        else
        {

#line 23
            sig_0 = 1.0f / (1.0f + exp(- _S18.pre3_0[_S21]));

#line 23
        }

#line 23
        uint _S22 = o_1;
        if(valid_1)
        {

#line 24
            _S17 = g_0 * sig_0;

#line 24
        }
        else
        {

#line 24
            _S17 = 0.0f;

#line 24
        }

#line 24
        dy_0[_S22] = _S17;

#line 18
        o_1 = o_1 + 1U;

#line 18
    }

#line 26
    thread array<float, int(32)> d2_0;

#line 26
    uint i_0 = 0U;
    for(;;)
    {

#line 27
        if(i_0 < 32U)
        {
        }
        else
        {

#line 27
            break;
        }

#line 27
        o_1 = 0U;

#line 27
        sig_0 = 0.0f;


        for(;;)
        {

#line 30
            if(o_1 < 3U)
            {
            }
            else
            {

#line 30
                break;
            }

#line 31
            float s_5 = sig_0 + dy_0[o_1] * *(kernelContext_5->nrcP_0+(525984U + o_1 * 32U + i_0));

#line 30
            o_1 = o_1 + 1U;

#line 30
            sig_0 = s_5;

#line 30
        }

#line 30
        uint _S23 = i_0;

        if((_S18.a2_0[i_0]) > 0.0f)
        {

#line 32
            _S17 = sig_0;

#line 32
        }
        else
        {

#line 32
            _S17 = 0.0f;

#line 32
        }

#line 32
        d2_0[_S23] = _S17;

#line 27
        i_0 = i_0 + 1U;

#line 27
    }

#line 27
    o_1 = 0U;

#line 34
    for(;;)
    {

#line 34
        if(o_1 < 3U)
        {
        }
        else
        {

#line 34
            break;
        }

#line 34
        uint _S24 = o_1;

#line 34
        nrcAddWave_0(526080U + o_1, dy_0[_S24], valid_1, kernelContext_5);

#line 34
        i_0 = 0U;


        for(;;)
        {

#line 37
            if(i_0 < 32U)
            {
            }
            else
            {

#line 37
                break;
            }

#line 37
            nrcAddWave_0(525984U + o_1 * 32U + i_0, dy_0[_S24] * _S18.a2_0[i_0], valid_1, kernelContext_5);

#line 37
            i_0 = i_0 + 1U;

#line 37
        }

#line 34
        o_1 = o_1 + 1U;

#line 34
    }

#line 40
    thread array<float, int(32)> d1_0;

#line 40
    i_0 = 0U;
    for(;;)
    {

#line 41
        if(i_0 < 32U)
        {
        }
        else
        {

#line 41
            break;
        }

#line 41
        j_1 = 0U;

#line 41
        sig_0 = 0.0f;


        for(;;)
        {

#line 44
            if(j_1 < 32U)
            {
            }
            else
            {

#line 44
                break;
            }

#line 45
            float s_6 = sig_0 + d2_0[j_1] * *(kernelContext_5->nrcP_0+(524928U + j_1 * 32U + i_0));

#line 44
            j_1 = j_1 + 1U;

#line 44
            sig_0 = s_6;

#line 44
        }

#line 44
        uint _S25 = i_0;

        if((_S18.a1_0[i_0]) > 0.0f)
        {

#line 46
            _S17 = sig_0;

#line 46
        }
        else
        {

#line 46
            _S17 = 0.0f;

#line 46
        }

#line 46
        d1_0[_S25] = _S17;

#line 41
        i_0 = i_0 + 1U;

#line 41
    }

#line 41
    j_1 = 0U;

#line 48
    for(;;)
    {

#line 48
        if(j_1 < 32U)
        {
        }
        else
        {

#line 48
            break;
        }

#line 48
        uint _S26 = j_1;

#line 48
        nrcAddWave_0(525952U + j_1, d2_0[_S26], valid_1, kernelContext_5);

#line 48
        i_0 = 0U;


        for(;;)
        {

#line 51
            if(i_0 < 32U)
            {
            }
            else
            {

#line 51
                break;
            }

#line 51
            nrcAddWave_0(524928U + j_1 * 32U + i_0, d2_0[_S26] * _S18.a1_0[i_0], valid_1, kernelContext_5);

#line 51
            i_0 = i_0 + 1U;

#line 51
        }

#line 48
        j_1 = j_1 + 1U;

#line 48
    }

#line 54
    thread array<float, int(16)> dx_0;

#line 54
    i_0 = 0U;
    for(;;)
    {

#line 55
        if(i_0 < 16U)
        {
        }
        else
        {

#line 55
            break;
        }

#line 56
        dx_0[i_0] = 0.0f;

#line 55
        i_0 = i_0 + 1U;

#line 55
    }

#line 55
    j_1 = 0U;

    for(;;)
    {

#line 57
        if(j_1 < 32U)
        {
        }
        else
        {

#line 57
            break;
        }

#line 57
        uint _S27 = j_1;

#line 57
        nrcAddWave_0(524896U + j_1, d1_0[_S27], valid_1, kernelContext_5);

#line 57
        i_0 = 0U;


        for(;;)
        {

#line 60
            if(i_0 < 19U)
            {
            }
            else
            {

#line 60
                break;
            }
            uint _S28 = 524288U + j_1 * 19U + i_0;

#line 62
            nrcAddWave_0(_S28, d1_0[_S27] * _S18.x_1[i_0], valid_1, kernelContext_5);
            if(i_0 < 16U)
            {

#line 64
                dx_0[i_0] = dx_0[i_0] + d1_0[_S27] * *(kernelContext_5->nrcP_0+_S28);

#line 63
            }

#line 60
            i_0 = i_0 + 1U;

#line 60
        }

#line 57
        j_1 = j_1 + 1U;

#line 57
    }

#line 67
    if(!valid_1)
    {

#line 68
        return;
    }

#line 68
    float3 _S29 = nrcUnit_0(p_2, kernelContext_5);

#line 68
    uint l_2 = 0U;

    for(;;)
    {

#line 70
        if(l_2 < 8U)
        {
        }
        else
        {

#line 70
            break;
        }

#line 70
        uint k_2 = 0U;

        for(;;)
        {

#line 72
            if(k_2 < 8U)
            {
            }
            else
            {

#line 72
                break;
            }
            thread uint slot_2;
            thread float w_2;
            nrcCorner_0(_S29, l_2, k_2, &slot_2, &w_2);
            uint _S30 = 2U * l_2;

#line 77
            float _S31 = atomic_fetch_add_explicit(((atomic_float device*)(kernelContext_5->nrcG_0+slot_2)), w_2 * dx_0[_S30], memory_order_relaxed);
            float _S32 = atomic_fetch_add_explicit(((atomic_float device*)(kernelContext_5->nrcG_0+(slot_2 + 1U))), w_2 * dx_0[_S30 + 1U], memory_order_relaxed);

#line 72
            k_2 = k_2 + 1U;

#line 72
        }

#line 70
        l_2 = l_2 + 1U;

#line 70
    }

#line 81
    return;
}


#line 16 "shaders/nrc_train.slang"
[[kernel]] void nrc_train(uint3 tid_0 [[thread_position_in_grid]], uint device* nrcCfg_1 [[buffer(4)]], float device* trainSamples_1 [[buffer(5)]], float device* nrcP_1 [[buffer(0)]], float device* nrcG_1 [[buffer(1)]])
{

#line 16
    thread KernelContext_0 kernelContext_6;

#line 16
    (&kernelContext_6)->nrcCfg_0 = nrcCfg_1;

#line 16
    (&kernelContext_6)->trainSamples_0 = trainSamples_1;

#line 16
    (&kernelContext_6)->nrcP_0 = nrcP_1;

#line 16
    (&kernelContext_6)->nrcG_0 = nrcG_1;

    uint _S33 = tid_0.x;

#line 18
    bool valid_2;

#line 18
    if(_S33 < nrcCfg_1[int(0)])
    {

#line 18
        valid_2 = (&kernelContext_6)->trainSamples_0[_S33 * 12U + 9U] > 0.5f;

#line 18
    }
    else
    {

#line 18
        valid_2 = false;

#line 18
    }
    uint b_0 = _S33 * 12U;

#line 19
    float3 p_3;
    if(valid_2)
    {

#line 20
        p_3 = float3((&kernelContext_6)->trainSamples_0[b_0], (&kernelContext_6)->trainSamples_0[b_0 + 1U], (&kernelContext_6)->trainSamples_0[b_0 + 2U]);

#line 20
    }
    else
    {

#line 20
        p_3 = float3(0.0f, 0.0f, 0.0f);

#line 20
    }

#line 20
    float3 n_2;
    if(valid_2)
    {

#line 21
        n_2 = float3((&kernelContext_6)->trainSamples_0[b_0 + 3U], (&kernelContext_6)->trainSamples_0[b_0 + 4U], (&kernelContext_6)->trainSamples_0[b_0 + 5U]);

#line 21
    }
    else
    {

#line 21
        n_2 = float3(0.0f, 1.0f, 0.0f);

#line 21
    }

#line 21
    float3 t_1;
    if(valid_2)
    {

#line 22
        t_1 = float3((&kernelContext_6)->trainSamples_0[b_0 + 6U], (&kernelContext_6)->trainSamples_0[b_0 + 7U], (&kernelContext_6)->trainSamples_0[b_0 + 8U]);

#line 22
    }
    else
    {

#line 22
        t_1 = float3(0.0f, 0.0f, 0.0f);

#line 22
    }

#line 22
    nrcTrainSample_0(p_3, n_2, t_1, valid_2, &kernelContext_6);

    return;
}

