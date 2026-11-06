#include <metal_stdlib>
#include <metal_math>
#include <metal_texture>
using namespace metal;

#line 2 "shaders/nrc_adam.slang"
struct KernelContext_0
{
    float device* nrcG_0;
    uint device* nrcCfg_0;
    float device* nrcM_0;
    float device* nrcV_0;
    float device* nrcP_0;
};


[[kernel]] void nrc_adam(uint3 tid_0 [[thread_position_in_grid]], float device* nrcG_1 [[buffer(1)]], uint device* nrcCfg_1 [[buffer(4)]], float device* nrcM_1 [[buffer(2)]], float device* nrcV_1 [[buffer(3)]], float device* nrcP_1 [[buffer(0)]])
{

#line 12
    thread KernelContext_0 kernelContext_0;

#line 12
    (&kernelContext_0)->nrcG_0 = nrcG_1;

#line 12
    (&kernelContext_0)->nrcCfg_0 = nrcCfg_1;

#line 12
    (&kernelContext_0)->nrcM_0 = nrcM_1;

#line 12
    (&kernelContext_0)->nrcV_0 = nrcV_1;

#line 12
    (&kernelContext_0)->nrcP_0 = nrcP_1;

    uint i_0 = tid_0.x;
    if(i_0 >= 526083U)
    {

#line 16
        return;
    }

#line 17
    float g_0 = *((&kernelContext_0)->nrcG_0+i_0);
    *((&kernelContext_0)->nrcG_0+i_0) = 0.0f;
    float step_0 = float((&kernelContext_0)->nrcCfg_0[int(1)]);

#line 19
    int _S1;
    if(i_0 < 524288U)
    {

#line 20
        _S1 = int(6);

#line 20
    }
    else
    {

#line 20
        _S1 = int(7);

#line 20
    }

#line 20
    float lr_0 = (as_type<float>(((&kernelContext_0)->nrcCfg_0[_S1])));
    float m_0 = 0.89999997615814209f * *((&kernelContext_0)->nrcM_0+i_0) + 0.10000000149011612f * g_0;
    float v_0 = 0.99900001287460327f * *((&kernelContext_0)->nrcV_0+i_0) + 0.0010000000474974513f * g_0 * g_0;
    *((&kernelContext_0)->nrcM_0+i_0) = m_0;
    *((&kernelContext_0)->nrcV_0+i_0) = v_0;


    float device* _S2 = (&kernelContext_0)->nrcP_0+i_0;

#line 27
    *_S2 = *_S2 - lr_0 * (m_0 / (1.0f - pow(0.89999997615814209f, step_0))) / (sqrt(v_0 / (1.0f - pow(0.99900001287460327f, step_0))) + 9.99999993922529029e-09f);
    return;
}

