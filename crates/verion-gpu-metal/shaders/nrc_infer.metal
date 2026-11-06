#include <metal_stdlib>
#include <metal_math>
#include <metal_texture>
using namespace metal;

#line 8 "shaders/nrc_infer.slang"
struct KernelContext_0
{
    uint device* nrcCfg_0;
    float device* inferQueries_0;
    float device* nrcP_0;
    float device* inferOut_0;
};


#line 4
float4 nrcBounds_0(KernelContext_0 thread* kernelContext_0)
{

#line 4
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

float3 nrcQuery_0(float3 p_2, float3 n_1, KernelContext_0 thread* kernelContext_3)
{

#line 102
    NrcAct_0 _S14 = nrcForward_0(p_2, n_1, kernelContext_3);

#line 102
    return _S14.y_0;
}


#line 12 "shaders/nrc_infer.slang"
[[kernel]] void nrc_infer(uint3 tid_0 [[thread_position_in_grid]], uint device* nrcCfg_1 [[buffer(1)]], float device* inferQueries_1 [[buffer(2)]], float device* nrcP_1 [[buffer(0)]], float device* inferOut_1 [[buffer(3)]])
{

#line 12
    thread KernelContext_0 kernelContext_4;

#line 12
    (&kernelContext_4)->nrcCfg_0 = nrcCfg_1;

#line 12
    (&kernelContext_4)->inferQueries_0 = inferQueries_1;

#line 12
    (&kernelContext_4)->nrcP_0 = nrcP_1;

#line 12
    (&kernelContext_4)->inferOut_0 = inferOut_1;

    uint _S15 = tid_0.x;

#line 14
    if(_S15 >= nrcCfg_1[int(0)])
    {

#line 15
        return;
    }

#line 16
    uint b_0 = _S15 * 12U;

#line 16
    float3 _S16 = nrcQuery_0(float3((&kernelContext_4)->inferQueries_0[b_0], (&kernelContext_4)->inferQueries_0[b_0 + 1U], (&kernelContext_4)->inferQueries_0[b_0 + 2U]), float3((&kernelContext_4)->inferQueries_0[b_0 + 3U], (&kernelContext_4)->inferQueries_0[b_0 + 4U], (&kernelContext_4)->inferQueries_0[b_0 + 5U]), &kernelContext_4);

#line 16
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

#line 19
        *((&kernelContext_4)->inferOut_0+(3U * _S15 + o_1)) = _S16[o_1];

#line 18
        o_1 = o_1 + 1U;

#line 18
    }

    return;
}

