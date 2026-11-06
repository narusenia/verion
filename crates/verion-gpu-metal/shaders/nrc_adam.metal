#include <metal_stdlib>
#include <metal_math>
#include <metal_texture>
using namespace metal;

#line 22 "shaders/include/nrc_net.slang"
struct KernelContext_0
{
    float device* nrcG_0;
    uint device* nrcCfg_0;
    float device* nrcM_0;
    float device* nrcV_0;
    float device* nrcP_0;
};


#line 28
float nrcF_0(uint i_0, KernelContext_0 thread* kernelContext_0)
{

#line 28
    return (as_type<float>((kernelContext_0->nrcCfg_0[i_0])));
}


#line 6 "shaders/nrc_adam.slang"
[[kernel]] void nrc_adam(uint3 tid_0 [[thread_position_in_grid]], float device* nrcG_1 [[buffer(1)]], uint device* nrcCfg_1 [[buffer(4)]], float device* nrcM_1 [[buffer(2)]], float device* nrcV_1 [[buffer(3)]], float device* nrcP_1 [[buffer(0)]])
{

#line 6
    thread KernelContext_0 kernelContext_1;

#line 6
    (&kernelContext_1)->nrcG_0 = nrcG_1;

#line 6
    (&kernelContext_1)->nrcCfg_0 = nrcCfg_1;

#line 6
    (&kernelContext_1)->nrcM_0 = nrcM_1;

#line 6
    (&kernelContext_1)->nrcV_0 = nrcV_1;

#line 6
    (&kernelContext_1)->nrcP_0 = nrcP_1;

    uint i_1 = tid_0.x;
    if(i_1 >= 526083U)
    {

#line 10
        return;
    }

#line 11
    float g_0 = *((&kernelContext_1)->nrcG_0+i_1);
    *((&kernelContext_1)->nrcG_0+i_1) = 0.0f;
    float step_0 = float((&kernelContext_1)->nrcCfg_0[int(1)]);

#line 13
    float lr_0;
    if(i_1 < 524288U)
    {

#line 14
        float _S1 = nrcF_0(6U, &kernelContext_1);

#line 14
        lr_0 = _S1;

#line 14
    }
    else
    {

#line 14
        float _S2 = nrcF_0(7U, &kernelContext_1);

#line 14
        lr_0 = _S2;

#line 14
    }
    float m_0 = 0.89999997615814209f * *((&kernelContext_1)->nrcM_0+i_1) + 0.10000000149011612f * g_0;
    float v_0 = 0.99900001287460327f * *((&kernelContext_1)->nrcV_0+i_1) + 0.0010000000474974513f * g_0 * g_0;
    *((&kernelContext_1)->nrcM_0+i_1) = m_0;
    *((&kernelContext_1)->nrcV_0+i_1) = v_0;


    float device* _S3 = (&kernelContext_1)->nrcP_0+i_1;

#line 21
    *_S3 = *_S3 - lr_0 * (m_0 / (1.0f - pow(0.89999997615814209f, step_0))) / (sqrt(v_0 / (1.0f - pow(0.99900001287460327f, step_0))) + 9.99999993922529029e-09f);
    return;
}

