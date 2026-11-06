#include <metal_stdlib>
#include <metal_math>
#include <metal_texture>
using namespace metal;

#line 5 "shaders/nrc_infer.slang"
struct KernelContext_0
{
    uint device* nrcCfg_0;
    float device* inferQueries_0;
    float device* nrcP_0;
    float device* inferOut_0;
};


#line 28 "shaders/include/nrc_net.slang"
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

float3 nrcQuery_0(float3 p_2, float3 n_1, KernelContext_0 thread* kernelContext_3)
{

#line 108
    NrcAct_0 _S18 = nrcForward_0(p_2, n_1, kernelContext_3);

#line 108
    return _S18.y_0;
}


#line 9 "shaders/nrc_infer.slang"
[[kernel]] void nrc_infer(uint3 tid_0 [[thread_position_in_grid]], uint device* nrcCfg_1 [[buffer(4)]], float device* inferQueries_1 [[buffer(5)]], float device* nrcP_1 [[buffer(0)]], float device* inferOut_1 [[buffer(6)]])
{

#line 9
    thread KernelContext_0 kernelContext_4;

#line 9
    (&kernelContext_4)->nrcCfg_0 = nrcCfg_1;

#line 9
    (&kernelContext_4)->inferQueries_0 = inferQueries_1;

#line 9
    (&kernelContext_4)->nrcP_0 = nrcP_1;

#line 9
    (&kernelContext_4)->inferOut_0 = inferOut_1;

    uint _S19 = tid_0.x;

#line 11
    if(_S19 >= nrcCfg_1[int(0)])
    {

#line 12
        return;
    }

#line 13
    uint b_0 = _S19 * 12U;

#line 13
    float3 _S20 = nrcQuery_0(float3((&kernelContext_4)->inferQueries_0[b_0], (&kernelContext_4)->inferQueries_0[b_0 + 1U], (&kernelContext_4)->inferQueries_0[b_0 + 2U]), float3((&kernelContext_4)->inferQueries_0[b_0 + 3U], (&kernelContext_4)->inferQueries_0[b_0 + 4U], (&kernelContext_4)->inferQueries_0[b_0 + 5U]), &kernelContext_4);

#line 13
    uint o_1 = 0U;

    for(;;)
    {

#line 15
        if(o_1 < 3U)
        {
        }
        else
        {

#line 15
            break;
        }

#line 16
        *((&kernelContext_4)->inferOut_0+(3U * _S19 + o_1)) = _S20[o_1];

#line 15
        o_1 = o_1 + 1U;

#line 15
    }

    return;
}

