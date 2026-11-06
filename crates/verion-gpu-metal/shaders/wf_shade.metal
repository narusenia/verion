#include <metal_stdlib>
#include <metal_math>
#include <metal_texture>
using namespace metal;

            raytracing::intersection_params _slang_ray_flags_to_intersection_params(uint flags){
                raytracing::intersection_params params;
                if (flags & 0x01) /* RAY_FLAG_FORCE_OPAQUE */
                    params.force_opacity(raytracing::forced_opacity::opaque);
                if (flags & 0x02) /* RAY_FLAG_FORCE_NON_OPAQUE */
                    params.force_opacity(raytracing::forced_opacity::non_opaque);
                if (flags & 0x10) /* RAY_FLAG_CULL_BACK_FACING_TRIANGLES */
                    params.set_triangle_cull_mode(raytracing::triangle_cull_mode::back);
                if (flags & 0x20) /* RAY_FLAG_CULL_FRONT_FACING_TRIANGLES */
                    params.set_triangle_cull_mode(raytracing::triangle_cull_mode::front);
                if (flags & 0x40) /* RAY_FLAG_CULL_OPAQUE */
                    params.set_opacity_cull_mode(raytracing::opacity_cull_mode::opaque);
                if (flags & 0x80) /* RAY_FLAG_CULL_NON_OPAQUE */
                    params.set_opacity_cull_mode(raytracing::opacity_cull_mode::non_opaque);
                if (flags & 0x100) /* RAY_FLAG_SKIP_TRIANGLES */
                    params.set_geometry_cull_mode(raytracing::geometry_cull_mode::triangle);
                if (flags & 0x200) /* RAY_FLAG_SKIP_PROCEDURAL_PRIMITIVES */
                    params.set_geometry_cull_mode(raytracing::geometry_cull_mode::bounding_box);
                return params;
            }
        

                uint _slang_committed_intersection_type_to_uint(raytracing::intersection_type type){
                    switch(type){
                        case raytracing::intersection_type::none:
                            return 0; /* COMMITTED_NOTHING */
                        case raytracing::intersection_type::triangle:
                            return 1; /* COMMITTED_TRIANGLE_HIT */
                        case raytracing::intersection_type::bounding_box:
                            return 2; /* COMMITTED_PROCEDURAL_PRIMITIVE_HIT */
                        default:
                            return 0xFFFFFFFF; // Invalid value to indicate error case, should never be returned by the API
                    }
                }
            

#line 1368 "core.meta.slang"
float float_getPi_0()
{

#line 1368
    return 3.1415927410125732f;
}


#line 10545 "hlsl.meta.slang"
float degrees_0(float x_0)
{

#line 10556
    return x_0 * (180.0f / float_getPi_0());
}


#line 49 "shaders/include/pt_core.slang"
struct KernelContext_0
{
    uint device* params_0;
    uint device* counts_0;
    uint device* queueIn_0;
    uint device* state_0;
    uint device* hits_0;
    float device* restir_0;
    float device* envPixels_0;
    uint device* instances_0;
    uint device* indices_0;
    float device* positions_0;
    float device* materials_0;
    float device* uvs_0;
    uint device* texInfo_0;
    float device* texels_0;
    float device* vnormals_0;
    uint device* lights_0;
    float device* emitters_0;
    metal::raytracing::acceleration_structure<metal::raytracing::instancing> scene_0;
    float device* lighting_0;
    float device* emitCdf_0;
    float device* envMarginal_0;
    float device* envCond_0;
    uint device* queueOut_0;
    float device* accum_0;
    float device* pixelStats_0;
};


#line 96 "shaders/include/wf_state.slang"
uint queuedPath_0(uint i_0, uint depth_0, KernelContext_0 thread* kernelContext_0)
{

#line 96
    bool _S1;

#line 96
    if(depth_0 == 0U)
    {

#line 96
        _S1 = kernelContext_0->params_0[int(32)] == 0U;

#line 96
    }
    else
    {

#line 96
        _S1 = false;

#line 96
    }

#line 96
    uint _S2;

#line 96
    if(_S1)
    {

#line 96
        _S2 = i_0;

#line 96
    }
    else
    {

#line 96
        _S2 = kernelContext_0->queueIn_0[i_0];

#line 96
    }

#line 96
    return _S2;
}


#line 72 "shaders/include/pt_core.slang"
uint pcg_0(uint v_0)
{
    uint s_0 = v_0 * 747796405U + 2891336453U;
    uint w_0 = ((s_0 >> ((s_0 >> 28U) + 4U)) ^ s_0) * 277803737U;
    return (w_0 >> 22U) ^ w_0;
}


#line 89
float pf_0(uint i_1, KernelContext_0 thread* kernelContext_1)
{

#line 89
    return (as_type<float>((kernelContext_1->params_0[i_1])));
}


#line 79
struct Rng_0
{
    uint state_1;
};


#line 82
float Rng_next_0(Rng_0 thread* this_0)
{
    uint _S3 = pcg_0(this_0->state_1);

#line 84
    this_0->state_1 = _S3;
    return float(_S3 >> 8U) * 5.9604644775390625e-08f;
}


#line 505
struct Parts_0
{
    float3 total_0;
    float3 directDiffuse_0;
    float3 indirectDiffuse_0;
    float3 specular_0;
    float3 transmission_0;
    float3 emission_0;
};


#line 625
struct PathState_0
{
    float3 org_0;
    float3 dir_0;
    float3 thr_0;
    uint rng_0;
    uint cls_0;
    int chan_0;
    float pathLen_0;
    bool misPrev_0;
    bool gi_0;
    bool restir_1;
    float qPrev_0;
    uint prevInst_0;
    float visLit_0;
    float visTotal_0;
    Parts_0 parts_0;
};


#line 654
PathState_0 generatePathFor_0(uint px_0, uint py_0, uint sample_0, KernelContext_0 thread* kernelContext_2)
{
    uint w_1 = kernelContext_2->params_0[int(0)];
    uint h_0 = kernelContext_2->params_0[int(1)];

    thread Rng_0 rng_1;
    (&rng_1)->state_1 = pcg_0((py_0 * w_1 + px_0) ^ (pcg_0(sample_0 * 2654435769U + 2135587861U + kernelContext_2->params_0[int(43)] * 1759714724U)));

#line 660
    float _S4 = pf_0(2U, kernelContext_2);

    float _S5 = float(w_1);

#line 662
    float _S6 = float(h_0);

#line 662
    float aspect_0 = _S5 / _S6;
    float _S7 = float(px_0);

#line 663
    float _S8 = Rng_next_0(&rng_1);

#line 663
    float _S9 = 2.0f * (_S7 + _S8) / _S5 - 1.0f;

#line 663
    float _S10 = pf_0(39U, kernelContext_2);

#line 663
    float u_0 = (_S9 + _S10) * aspect_0 * _S4;
    float _S11 = float(py_0);

#line 664
    float _S12 = Rng_next_0(&rng_1);

#line 664
    float _S13 = 1.0f - 2.0f * (_S11 + _S12) / _S6;

#line 664
    float _S14 = pf_0(40U, kernelContext_2);
    float3 _S15 = float3(u_0, (_S13 + _S14) * _S4, -1.0f);

#line 665
    float _S16 = pf_0(4U, kernelContext_2);

#line 665
    float3 focal_0 = _S15 * float3(_S16) ;

#line 665
    float _S17 = pf_0(3U, kernelContext_2);
    float _S18 = Rng_next_0(&rng_1);

#line 666
    float lensR_0 = _S17 * sqrt(_S18);
    float _S19 = Rng_next_0(&rng_1);

#line 667
    float lensA_0 = 6.2831854820251465f * _S19;
    float _S20 = lensR_0 * cos(lensA_0);

#line 668
    float _S21 = lensR_0 * sin(lensA_0);
    float3 _S22 = normalize(focal_0 - float3(_S20, _S21, 0.0f));
    thread PathState_0 s_1;

#line 670
    uint r_0 = 0U;
    for(;;)
    {

#line 671
        if(r_0 < 3U)
        {
        }
        else
        {

#line 671
            break;
        }
        uint _S23 = 4U * r_0;

#line 673
        uint _S24 = 8U + _S23;

#line 673
        uint _S25 = 9U + _S23;

#line 673
        uint _S26 = 10U + _S23;

#line 673
        (&s_1)->org_0[r_0] = (as_type<float>((kernelContext_2->params_0[_S24]))) * _S20 + (as_type<float>((kernelContext_2->params_0[_S25]))) * _S21 + (as_type<float>((kernelContext_2->params_0[_S26]))) * 0.0f + (as_type<float>((kernelContext_2->params_0[11U + _S23])));
        (&s_1)->dir_0[r_0] = (as_type<float>((kernelContext_2->params_0[_S24]))) * _S22.x + (as_type<float>((kernelContext_2->params_0[_S25]))) * _S22.y + (as_type<float>((kernelContext_2->params_0[_S26]))) * _S22.z;

#line 671
        r_0 = r_0 + 1U;

#line 671
    }

#line 676
    (&s_1)->dir_0 = normalize((&s_1)->dir_0);
    (&s_1)->thr_0 = float3(1.0f) ;
    (&s_1)->rng_0 = (&rng_1)->state_1;
    (&s_1)->cls_0 = 0U;
    (&s_1)->chan_0 = int(-1);
    (&s_1)->pathLen_0 = 0.0f;
    (&s_1)->misPrev_0 = false;
    (&s_1)->restir_1 = false;
    (&s_1)->gi_0 = false;
    (&s_1)->qPrev_0 = 0.0f;
    (&s_1)->prevInst_0 = 0U;
    (&s_1)->visLit_0 = 0.0f;
    (&s_1)->visTotal_0 = 0.0f;
    float3 _S27 = float3(0.0f) ;

#line 689
    (&(&s_1)->parts_0)->total_0 = _S27;

#line 689
    (&(&s_1)->parts_0)->directDiffuse_0 = _S27;

#line 689
    (&(&s_1)->parts_0)->indirectDiffuse_0 = _S27;

#line 689
    (&(&s_1)->parts_0)->specular_0 = _S27;

#line 689
    (&(&s_1)->parts_0)->transmission_0 = _S27;

#line 689
    (&(&s_1)->parts_0)->emission_0 = _S27;
    return s_1;
}


#line 1567
PathState_0 generatePath_0(uint px_1, uint py_1, KernelContext_0 thread* kernelContext_3)
{

#line 1567
    PathState_0 _S28 = generatePathFor_0(px_1, py_1, kernelContext_3->params_0[int(6)], kernelContext_3);

#line 1567
    return _S28;
}


#line 25 "shaders/include/wf_state.slang"
uint pathCount_0(KernelContext_0 thread* kernelContext_4)
{

#line 25
    return kernelContext_4->params_0[int(31)];
}

float getF_0(uint f_0, uint p_0, KernelContext_0 thread* kernelContext_5)
{

#line 28
    uint _S29 = pathCount_0(kernelContext_5);

#line 28
    return (as_type<float>((*(kernelContext_5->state_0+(f_0 * _S29 + p_0)))));
}


#line 30
float3 get3_0(uint f_1, uint p_1, KernelContext_0 thread* kernelContext_6)
{

#line 30
    float _S30 = getF_0(f_1, p_1, kernelContext_6);

#line 30
    float _S31 = getF_0(f_1 + 1U, p_1, kernelContext_6);

#line 30
    float _S32 = getF_0(f_1 + 2U, p_1, kernelContext_6);

#line 30
    return float3(_S30, _S31, _S32);
}


#line 58
PathState_0 loadPath_0(uint p_2, uint depth_1, KernelContext_0 thread* kernelContext_7)
{
    if(depth_1 == 0U)
    {

#line 61
        uint _S33 = p_2 % kernelContext_7->params_0[int(0)];

#line 61
        uint _S34 = p_2 / kernelContext_7->params_0[int(0)];

#line 61
        PathState_0 _S35 = generatePath_0(_S33, _S34, kernelContext_7);

#line 61
        return _S35;
    }

#line 61
    uint _S36 = pathCount_0(kernelContext_7);

    thread PathState_0 s_2;

#line 63
    float3 _S37 = get3_0(0U, p_2, kernelContext_7);
    (&s_2)->org_0 = _S37;

#line 64
    float3 _S38 = get3_0(3U, p_2, kernelContext_7);
    (&s_2)->dir_0 = _S38;

#line 65
    float3 _S39 = get3_0(6U, p_2, kernelContext_7);
    (&s_2)->thr_0 = _S39;
    (&s_2)->rng_0 = *(kernelContext_7->state_0+(9U * _S36 + p_2));
    uint device* _S40 = kernelContext_7->state_0+(10U * _S36 + p_2);
    (&s_2)->cls_0 = (*_S40) & 3U;
    (&s_2)->chan_0 = int(((*_S40) >> 2U) & 3U) - int(1);
    (&s_2)->misPrev_0 = ((*_S40) & 16U) != 0U;
    (&s_2)->restir_1 = ((*_S40) & 32U) != 0U;
    (&s_2)->gi_0 = ((*_S40) & 64U) != 0U;
    (&s_2)->prevInst_0 = (*_S40) >> 8U;

#line 74
    float _S41 = getF_0(11U, p_2, kernelContext_7);
    (&s_2)->pathLen_0 = _S41;

#line 75
    float _S42 = getF_0(12U, p_2, kernelContext_7);
    (&s_2)->qPrev_0 = _S42;
    float3 _S43 = float3(0.0f) ;

#line 77
    (&(&s_2)->parts_0)->total_0 = _S43;

#line 77
    (&(&s_2)->parts_0)->directDiffuse_0 = _S43;

#line 77
    (&(&s_2)->parts_0)->indirectDiffuse_0 = _S43;

#line 77
    (&(&s_2)->parts_0)->specular_0 = _S43;

#line 77
    (&(&s_2)->parts_0)->transmission_0 = _S43;

#line 77
    (&(&s_2)->parts_0)->emission_0 = _S43;

#line 77
    float3 _S44 = get3_0(13U, p_2, kernelContext_7);
    (&(&s_2)->parts_0)->total_0 = _S44;
    (&s_2)->visLit_0 = 0.0f;
    (&s_2)->visTotal_0 = 0.0f;
    if(kernelContext_7->params_0[int(28)] != 0U)
    {

#line 81
        float3 _S45 = get3_0(16U, p_2, kernelContext_7);

        (&(&s_2)->parts_0)->directDiffuse_0 = _S45;

#line 83
        float3 _S46 = get3_0(19U, p_2, kernelContext_7);
        (&(&s_2)->parts_0)->indirectDiffuse_0 = _S46;

#line 84
        float3 _S47 = get3_0(22U, p_2, kernelContext_7);
        (&(&s_2)->parts_0)->specular_0 = _S47;

#line 85
        float3 _S48 = get3_0(25U, p_2, kernelContext_7);
        (&(&s_2)->parts_0)->transmission_0 = _S48;

#line 86
        float3 _S49 = get3_0(28U, p_2, kernelContext_7);
        (&(&s_2)->parts_0)->emission_0 = _S49;

#line 87
        float _S50 = getF_0(31U, p_2, kernelContext_7);
        (&s_2)->visLit_0 = _S50;

#line 88
        float _S51 = getF_0(32U, p_2, kernelContext_7);
        (&s_2)->visTotal_0 = _S51;

#line 81
    }

#line 91
    return s_2;
}


#line 54 "shaders/include/pt_core.slang"
constant bool fc_restirCompiled_0 [[function_constant(0)]];
constant bool restirCompiled_0 = is_function_constant_defined(fc_restirCompiled_0) ? fc_restirCompiled_0 : true;

#line 721
uint restirBase_0(uint pixel_0, uint which_0)
{

#line 721
    return pixel_0 * 80U + which_0 * 28U;
}


#line 992
void restirClear_0(uint pixel_1, KernelContext_0 thread* kernelContext_8)
{
    uint co_0 = restirBase_0(pixel_1, kernelContext_8->params_0[int(6)] & 1U);
    float _S52 = (as_type<float>((0U)));

#line 995
    *(kernelContext_8->restir_0+(co_0 + 14U)) = _S52;
    *(kernelContext_8->restir_0+(co_0 + 27U)) = _S52;
    return;
}


#line 534
void Parts_file_0(Parts_0 thread* this_1, uint depth_2, uint cls_1, float3 c_0)
{
    if(depth_2 == 0U)
    {

#line 537
        this_1->emission_0 = this_1->emission_0 + c_0;

#line 536
    }
    else
    {

#line 538
        if(cls_1 == 0U)
        {

#line 539
            this_1->indirectDiffuse_0 = this_1->indirectDiffuse_0 + c_0;

#line 538
        }
        else
        {

#line 540
            if(cls_1 == 1U)
            {

#line 541
                this_1->specular_0 = this_1->specular_0 + c_0;

#line 540
            }
            else
            {
                this_1->transmission_0 = this_1->transmission_0 + c_0;

#line 540
            }

#line 538
        }

#line 536
    }

#line 544
    return;
}


#line 515
void Parts_add_0(Parts_0 thread* this_2, uint depth_3, uint cls_2, float3 c_1)
{
    this_2->total_0 = this_2->total_0 + c_1;
    Parts_file_0(this_2, depth_3, cls_2, c_1);
    return;
}


#line 257
void envCoords_0(float3 d_0, uint thread* i_2, uint thread* j_0, KernelContext_0 thread* kernelContext_9)
{
    uint w_2 = kernelContext_9->params_0[int(24)];
    uint h_1 = kernelContext_9->params_0[int(25)];

    float v_1 = acos(clamp(d_0.y, -1.0f, 1.0f)) / 3.1415927410125732f;
    *i_2 = min(uint((atan2(d_0.x, - d_0.z) * 0.15915493667125702f + 0.5f) * float(w_2)), w_2 - 1U);
    *j_0 = min(uint(v_1 * float(h_1)), h_1 - 1U);
    return;
}


#line 250
float3 envTexel_0(uint i_3, uint j_1, KernelContext_0 thread* kernelContext_10)
{
    uint o_0 = 3U * (j_1 * kernelContext_10->params_0[int(24)] + i_3);
    return float3(kernelContext_10->envPixels_0[o_0], kernelContext_10->envPixels_0[o_0 + 1U], kernelContext_10->envPixels_0[o_0 + 2U]);
}


#line 190
float lum_0(float3 c_2)
{

#line 190
    return dot(c_2, float3(0.2125999927520752f, 0.71520000696182251f, 0.072200000286102295f));
}


#line 276
float envPdf_0(float3 d_1, KernelContext_0 thread* kernelContext_11)
{
    thread uint i_4;

#line 278
    thread uint j_2;

#line 278
    envCoords_0(d_1, &i_4, &j_2, kernelContext_11);

#line 278
    float3 _S53 = envTexel_0(i_4, j_2, kernelContext_11);

    float _S54 = lum_0(_S53);

#line 280
    float _S55 = pf_0(26U, kernelContext_11);

#line 280
    return _S54 * _S55;
}


#line 267
float3 envRadiance_0(float3 d_2, KernelContext_0 thread* kernelContext_12)
{
    thread uint i_5;

#line 269
    thread uint j_3;

#line 269
    envCoords_0(d_2, &i_5, &j_3, kernelContext_12);

#line 269
    float3 _S56 = envTexel_0(i_5, j_3, kernelContext_12);

    return _S56;
}


#line 97
float3 vertexPos_0(uint v_2, KernelContext_0 thread* kernelContext_13)
{

#line 97
    uint _S57 = 3U * v_2;

#line 97
    return float3(kernelContext_13->positions_0[_S57], kernelContext_13->positions_0[_S57 + 1U], kernelContext_13->positions_0[_S57 + 2U]);
}


#line 99
float3 transformPoint_0(uint base_0, float3 p_3, KernelContext_0 thread* kernelContext_14)
{
    thread float3 r_1;

#line 101
    uint row_0 = 0U;
    for(;;)
    {

#line 102
        if(row_0 < 3U)
        {
        }
        else
        {

#line 102
            break;
        }
        uint o_1 = base_0 + 4U * row_0;
        r_1[row_0] = (as_type<float>((kernelContext_14->instances_0[o_1]))) * p_3.x + (as_type<float>((kernelContext_14->instances_0[o_1 + 1U]))) * p_3.y + (as_type<float>((kernelContext_14->instances_0[o_1 + 2U]))) * p_3.z + (as_type<float>((kernelContext_14->instances_0[o_1 + 3U])));

#line 102
        row_0 = row_0 + 1U;

#line 102
    }

#line 107
    return r_1;
}


#line 318
float3 texelAt_0(uint base_1, uint w_3, uint h_2, int x_1, int y_0, KernelContext_0 thread* kernelContext_15)
{
    int _S58 = int(w_3);

#line 320
    int _S59 = x_1 % _S58;

#line 320
    int _S60 = (_S59 + _S58) % _S58;

#line 320
    uint xi_0 = uint(_S60);
    int _S61 = int(h_2);

#line 321
    int _S62 = y_0 % _S61;

#line 321
    int _S63 = (_S62 + _S61) % _S61;
    uint o_2 = 3U * (base_1 + uint(_S63) * w_3 + xi_0);
    return float3(kernelContext_15->texels_0[o_2], kernelContext_15->texels_0[o_2 + 1U], kernelContext_15->texels_0[o_2 + 2U]);
}

float3 bilinear_0(uint base_2, uint w_4, uint h_3, float2 uv_0, KernelContext_0 thread* kernelContext_16)
{
    float fx_0 = uv_0.x * float(w_4) - 0.5f;
    float fy_0 = uv_0.y * float(h_3) - 0.5f;
    int x0_0 = int(floor(fx_0));
    int y0_0 = int(floor(fy_0));
    float tx_0 = fx_0 - float(x0_0);
    float ty_0 = fy_0 - float(y0_0);

#line 333
    float3 _S64 = texelAt_0(base_2, w_4, h_3, x0_0, y0_0, kernelContext_16);
    int _S65 = x0_0 + int(1);

#line 334
    float3 _S66 = texelAt_0(base_2, w_4, h_3, _S65, y0_0, kernelContext_16);

#line 334
    float3 _S67 = float3(tx_0) ;

#line 334
    float3 a_0 = mix(_S64, _S66, _S67);
    int _S68 = y0_0 + int(1);

#line 335
    float3 _S69 = texelAt_0(base_2, w_4, h_3, x0_0, _S68, kernelContext_16);

#line 335
    float3 _S70 = texelAt_0(base_2, w_4, h_3, _S65, _S68, kernelContext_16);
    return mix(a_0, mix(_S69, _S70, _S67), float3(ty_0) );
}


float3 sampleTexture_0(uint tex_0, float2 uv_1, float footprint_0, KernelContext_0 thread* kernelContext_17)
{
    uint ti_0 = tex_0 * 4U;
    uint base_3 = kernelContext_17->texInfo_0[ti_0];
    uint w_5 = kernelContext_17->texInfo_0[ti_0 + 1U];
    uint h_4 = kernelContext_17->texInfo_0[ti_0 + 2U];
    uint levels_0 = kernelContext_17->texInfo_0[ti_0 + 3U];
    float lod_0 = clamp(log2(max(footprint_0 * float(max(w_5, h_4)), 9.99999993922529029e-09f)), 0.0f, float(levels_0 - 1U));
    uint l0_0 = uint(floor(lod_0));
    float t_0 = lod_0 - float(l0_0);

#line 349
    uint lw_0 = w_5;

#line 349
    uint lh_0 = h_4;

#line 349
    uint k_0 = 0U;

#line 349
    uint off_0 = base_3;



    for(;;)
    {

#line 353
        if(k_0 < l0_0)
        {
        }
        else
        {

#line 353
            break;
        }
        uint off_1 = off_0 + lw_0 * lh_0;
        uint _S71 = max(lw_0 / 2U, 1U);
        uint _S72 = max(lh_0 / 2U, 1U);

#line 353
        uint _S73 = k_0 + 1U;

#line 353
        lw_0 = _S71;

#line 353
        lh_0 = _S72;

#line 353
        k_0 = _S73;

#line 353
        off_0 = off_1;

#line 353
    }

#line 353
    float3 _S74 = bilinear_0(off_0, lw_0, lh_0, uv_1, kernelContext_17);

#line 353
    bool _S75;

#line 360
    if((l0_0 + 1U) >= levels_0)
    {

#line 360
        _S75 = true;

#line 360
    }
    else
    {

#line 360
        _S75 = t_0 <= 0.0f;

#line 360
    }

#line 360
    if(_S75)
    {

#line 361
        return _S74;
    }

#line 361
    float3 _S76 = bilinear_0(off_0 + lw_0 * lh_0, max(lw_0 / 2U, 1U), max(lh_0 / 2U, 1U), uv_1, kernelContext_17);


    return mix(_S74, _S76, float3(t_0) );
}


#line 570
float opacityAt_0(uint instIdx_0, uint prim_0, float2 bary_0, KernelContext_0 thread* kernelContext_18)
{
    uint _S77 = instIdx_0 * 16U;

#line 572
    uint mi_0 = kernelContext_18->instances_0[_S77 + 2U] * 24U;
    float op_0 = kernelContext_18->materials_0[mi_0 + 22U];
    uint tex_1 = uint(kernelContext_18->materials_0[mi_0 + 23U]);

#line 574
    bool _S78;
    if(tex_1 > 0U)
    {

#line 575
        _S78 = op_0 > 0.0f;

#line 575
    }
    else
    {

#line 575
        _S78 = false;

#line 575
    }

#line 575
    float op_1;

#line 575
    if(_S78)
    {
        uint tri_0 = kernelContext_18->instances_0[_S77 + 1U] + 3U * prim_0;
        uint vo_0 = kernelContext_18->instances_0[_S77];
        float2 uv0_0 = float2(kernelContext_18->uvs_0[2U * (kernelContext_18->indices_0[tri_0] + vo_0)], kernelContext_18->uvs_0[2U * (kernelContext_18->indices_0[tri_0] + vo_0) + 1U]);
        uint _S79 = tri_0 + 1U;
        uint _S80 = tri_0 + 2U;

#line 581
        float3 _S81 = sampleTexture_0(tex_1 - 1U, uv0_0 + float2(bary_0.x)  * (float2(kernelContext_18->uvs_0[2U * (kernelContext_18->indices_0[_S79] + vo_0)], kernelContext_18->uvs_0[2U * (kernelContext_18->indices_0[_S79] + vo_0) + 1U]) - uv0_0) + float2(bary_0.y)  * (float2(kernelContext_18->uvs_0[2U * (kernelContext_18->indices_0[_S80] + vo_0)], kernelContext_18->uvs_0[2U * (kernelContext_18->indices_0[_S80] + vo_0) + 1U]) - uv0_0), 0.0f, kernelContext_18);

#line 581
        op_1 = op_0 * _S81.x;

#line 575
    }
    else
    {

#line 575
        op_1 = op_0;

#line 575
    }

#line 584
    return op_1;
}


#line 722
uint restirScratch_0(uint pixel_2)
{

#line 722
    return pixel_2 * 80U + 56U;
}


#line 122
float3 vertexNormal_0(uint v_3, KernelContext_0 thread* kernelContext_19)
{

#line 122
    uint _S82 = 3U * v_3;

#line 122
    return float3(kernelContext_19->vnormals_0[_S82], kernelContext_19->vnormals_0[_S82 + 1U], kernelContext_19->vnormals_0[_S82 + 2U]);
}


#line 112
float3 transformNormal_0(uint base_4, float3 n_0, KernelContext_0 thread* kernelContext_20)
{
    float3 r0_0 = float3((as_type<float>((kernelContext_20->instances_0[base_4]))), (as_type<float>((kernelContext_20->instances_0[base_4 + 1U]))), (as_type<float>((kernelContext_20->instances_0[base_4 + 2U]))));
    float3 r1_0 = float3((as_type<float>((kernelContext_20->instances_0[base_4 + 4U]))), (as_type<float>((kernelContext_20->instances_0[base_4 + 5U]))), (as_type<float>((kernelContext_20->instances_0[base_4 + 6U]))));
    float3 r2_0 = float3((as_type<float>((kernelContext_20->instances_0[base_4 + 8U]))), (as_type<float>((kernelContext_20->instances_0[base_4 + 9U]))), (as_type<float>((kernelContext_20->instances_0[base_4 + 10U]))));
    float3 c0_0 = cross(r1_0, r2_0);

#line 117
    float s_3;
    if((dot(r0_0, c0_0)) < 0.0f)
    {

#line 118
        s_3 = -1.0f;

#line 118
    }
    else
    {

#line 118
        s_3 = 1.0f;

#line 118
    }
    return float3(s_3)  * float3(dot(c0_0, n_0), dot(cross(r2_0, r0_0), n_0), dot(cross(r0_0, r1_0), n_0));
}


#line 204
uint emitMask_0(uint inst_0, KernelContext_0 thread* kernelContext_21)
{

#line 204
    return kernelContext_21->lights_0[kernelContext_21->params_0[int(5)] * 16U + 5888U + 2U * inst_0 + 1U];
}


#line 203
uint recvMask_0(uint inst_1, KernelContext_0 thread* kernelContext_22)
{

#line 203
    return kernelContext_22->lights_0[kernelContext_22->params_0[int(5)] * 16U + 5888U + 2U * inst_1];
}


#line 164
void basis_0(float3 n_1, float3 thread* t_1, float3 thread* b_0)
{

#line 164
    float3 a_1;

    if((abs(n_1.x)) > 0.89999997615814209f)
    {

#line 166
        a_1 = float3(0.0f, 1.0f, 0.0f);

#line 166
    }
    else
    {

#line 166
        a_1 = float3(1.0f, 0.0f, 0.0f);

#line 166
    }
    float3 _S83 = normalize(cross(n_1, a_1));

#line 167
    *b_0 = _S83;
    *t_1 = cross(_S83, n_1);
    return;
}


#line 153
float fresnelDielectric_0(float cosi_0, float eta_0)
{
    float s2_0 = (1.0f - cosi_0 * cosi_0) / (eta_0 * eta_0);
    if(s2_0 >= 1.0f)
    {

#line 157
        return 1.0f;
    }

#line 158
    float cost_0 = sqrt(1.0f - s2_0);
    float _S84 = eta_0 * cost_0;

#line 159
    float rs_0 = (cosi_0 - _S84) / (cosi_0 + _S84);
    float _S85 = eta_0 * cosi_0;

#line 160
    float rp_0 = (_S85 - cost_0) / (_S85 + cost_0);
    return 0.5f * (rs_0 * rs_0 + rp_0 * rp_0);
}


#line 201
float albedoAt_0(uint i_6, KernelContext_0 thread* kernelContext_23)
{

#line 201
    return (as_type<float>((kernelContext_23->lights_0[kernelContext_23->params_0[int(5)] * 16U + i_6])));
}


#line 419
float dielectricAlbedo_0(float cosO_0, float rough_0, float ior_0, bool outside_0, KernelContext_0 thread* kernelContext_24)
{
    float x_2 = saturate(cosO_0) * 15.0f;
    float y_1 = saturate(rough_0) * 15.0f;
    float z_0 = clamp((ior_0 - 1.0f) * 4.0f, 0.0f, 7.999000072479248f);
    uint _S86 = min(uint(x_2), 14U);
    uint _S87 = min(uint(y_1), 14U);
    uint z0_0 = uint(z_0);
    float _S88 = x_2 - float(_S86);
    float _S89 = y_1 - float(_S87);
    float fz_0 = z_0 - float(z0_0);

#line 429
    uint k_1;
    if(outside_0)
    {

#line 430
        k_1 = 0U;

#line 430
    }
    else
    {

#line 430
        k_1 = 9U;

#line 430
    }

#line 430
    uint _S90 = k_1 * 16U * 16U;
    thread array<float, int(2)> c_3;

#line 431
    k_1 = 0U;
    for(;;)
    {

#line 432
        if(k_1 < 2U)
        {
        }
        else
        {

#line 432
            break;
        }

        uint _S91 = 1280U + (_S90 + ((z0_0 + k_1) * 16U + _S87) * 16U + _S86);

#line 435
        float _S92 = albedoAt_0(_S91, kernelContext_24);

#line 435
        float _S93 = albedoAt_0(_S91 + 1U, kernelContext_24);

#line 435
        float a_2 = mix(_S92, _S93, _S88);
        uint _S94 = _S91 + 16U;

#line 436
        float _S95 = albedoAt_0(_S94, kernelContext_24);

#line 436
        float _S96 = albedoAt_0(_S94 + 1U, kernelContext_24);
        c_3[k_1] = mix(a_2, mix(_S95, _S96, _S88), _S89);

#line 432
        k_1 = k_1 + 1U;

#line 432
    }

#line 439
    return mix(c_3[int(0)], c_3[int(1)], fz_0);
}


float sheenAlbedo_0(float cosO_1, float r_2, KernelContext_0 thread* kernelContext_25)
{
    float x_3 = saturate(cosO_1) * 15.0f;
    float y_2 = saturate(r_2) * 15.0f;
    uint _S97 = min(uint(x_3), 14U);
    uint _S98 = min(uint(y_2), 14U);
    float fx_1 = x_3 - float(_S97);
    float fy_1 = y_2 - float(_S98);
    uint _S99 = 1024U + _S98 * 16U + _S97;

#line 451
    float _S100 = albedoAt_0(_S99, kernelContext_25);

#line 451
    float _S101 = albedoAt_0(_S99 + 1U, kernelContext_25);

#line 451
    float a_3 = mix(_S100, _S101, fx_1);
    uint _S102 = 1024U + (_S98 + 1U) * 16U + _S97;

#line 452
    float _S103 = albedoAt_0(_S102, kernelContext_25);

#line 452
    float _S104 = albedoAt_0(_S102 + 1U, kernelContext_25);
    return mix(a_3, mix(_S103, _S104, fx_1), fy_1);
}


#line 56
constant bool fc_nrcCompiled_0 [[function_constant(1)]];
constant bool nrcCompiled_0 = is_function_constant_defined(fc_nrcCompiled_0) ? fc_nrcCompiled_0 : true;

#line 208
float iesFactor_0(uint po_0, float3 d_3, KernelContext_0 thread* kernelContext_26)
{



    float th_0 = degrees_0(acos(clamp(- dot(d_3, float3((as_type<float>((kernelContext_26->lights_0[po_0 + 6U]))), (as_type<float>((kernelContext_26->lights_0[po_0 + 7U]))), (as_type<float>((kernelContext_26->lights_0[po_0 + 8U]))))), -1.0f, 1.0f)));
    float ph_0 = degrees_0(atan2(dot(d_3, float3((as_type<float>((kernelContext_26->lights_0[po_0 + 3U]))), (as_type<float>((kernelContext_26->lights_0[po_0 + 4U]))), (as_type<float>((kernelContext_26->lights_0[po_0 + 5U]))))), dot(d_3, float3((as_type<float>((kernelContext_26->lights_0[po_0]))), (as_type<float>((kernelContext_26->lights_0[po_0 + 1U]))), (as_type<float>((kernelContext_26->lights_0[po_0 + 2U])))))));

#line 214
    float ph_1;
    if(ph_0 < 0.0f)
    {

#line 215
        ph_1 = ph_0 + 360.0f;

#line 215
    }
    else
    {

#line 215
        ph_1 = ph_0;

#line 215
    }

    uint _S105 = min(uint(th_0), 179U);
    uint _S106 = min(uint(ph_1), 359U);
    float ft_0 = th_0 - float(_S105);

    uint t_2 = po_0 + 9U;
    uint _S107 = t_2 + _S106 * 181U + _S105;
    uint _S108 = t_2 + (_S106 + 1U) * 181U + _S105;
    return mix(mix((as_type<float>((kernelContext_26->lights_0[_S107]))), (as_type<float>((kernelContext_26->lights_0[_S107 + 1U]))), ft_0), mix((as_type<float>((kernelContext_26->lights_0[_S108]))), (as_type<float>((kernelContext_26->lights_0[_S108 + 1U]))), ft_0), ph_1 - float(_S106));
}


#line 20995 "hlsl.meta.slang"
struct RayDesc_0
{
    float3 Origin_0;
    float TMin_0;
    float3 Direction_0;
    float TMax_0;
};


#line 589 "shaders/include/pt_core.slang"
bool occluded_0(float3 o_3, float3 d_4, float tmax_0, KernelContext_0 thread* kernelContext_27)
{

#line 589
    uint layer_0 = 0U;

#line 589
    float3 _S109 = o_3;

#line 589
    float _S110 = tmax_0;

    for(;;)
    {

#line 591
        if(layer_0 < 8U)
        {
        }
        else
        {

#line 591
            break;
        }
        thread RayDesc_0 ray_0;
        (&ray_0)->Origin_0 = _S109;
        (&ray_0)->Direction_0 = d_4;
        (&ray_0)->TMin_0 = 0.0f;
        (&ray_0)->TMax_0 = _S110;
        thread raytracing::intersection_query<raytracing::triangle_data, raytracing::instancing> q_0;
        (&q_0)->reset({ (ray_0.Origin_0), (ray_0.Direction_0), (ray_0.TMin_0), (ray_0.TMax_0) }, (kernelContext_27->scene_0), (255U), _slang_ray_flags_to_intersection_params((5U)));
        for(;;)
        {

#line 600
            bool _S111 = ((&q_0)->next());

#line 600
            if(_S111)
            {
            }
            else
            {

#line 600
                break;
            }

#line 600
        }
        uint _S112 = (_slang_committed_intersection_type_to_uint((&q_0)->get_committed_intersection_type()));

#line 601
        if(_S112 != 1U)
        {

#line 602
            return false;
        }

#line 603
        uint _S113 = ((&q_0)->get_committed_instance_id());

#line 603
        uint _S114 = ((&q_0)->get_committed_primitive_id());

#line 603
        float2 _S115 = ((&q_0)->get_committed_triangle_barycentric_coord());

#line 603
        float _S116 = opacityAt_0(_S113, _S114, _S115, kernelContext_27);
        if(_S116 >= 1.0f)
        {

#line 605
            return true;
        }
        uint h_5 = (((((((as_type<uint>((_S109.x))) * 73856093U) ^ ((as_type<uint>((_S109.y))) * 19349663U)) ^ ((as_type<uint>((_S109.z))) * 83492791U)) ^ ((as_type<uint>((d_4.x))) * 2654435761U)) ^ ((as_type<uint>((d_4.y))) * 40503U)) ^ ((as_type<uint>((d_4.z))) * 2246822519U)) ^ (layer_0 * 3266489917U);

        uint h_6 = (h_5 ^ (h_5 >> 16U)) * 2146121005U;

        uint h_7 = (h_6 ^ (h_6 >> 15U)) * 2221713035U;

        if((float((h_7 ^ (h_7 >> 16U)) >> 8U) * 5.9604644775390625e-08f) < _S116)
        {

#line 614
            return true;
        }

#line 615
        float _S117 = ((&q_0)->get_committed_distance());

#line 615
        float adv_0 = _S117 + 9.9999997473787516e-05f;
        float3 _S118 = _S109 + d_4 * float3(adv_0) ;
        float _S119 = _S110 - adv_0;
        if(_S119 <= 0.0f)
        {

#line 619
            return false;
        }

#line 591
        layer_0 = layer_0 + 1U;

#line 591
        _S109 = _S118;

#line 591
        _S110 = _S119;

#line 591
    }

#line 621
    return true;
}


#line 138
float D_0(float hz_0, float alpha_0)
{
    float a2_0 = alpha_0 * alpha_0;
    float d_5 = hz_0 * hz_0 * (a2_0 - 1.0f) + 1.0f;
    return a2_0 / (3.1415927410125732f * d_5 * d_5);
}


#line 131
float G1_0(float cosT_0, float alpha_1)
{
    float c2_0 = cosT_0 * cosT_0;

    return 2.0f / (1.0f + sqrt(1.0f + alpha_1 * alpha_1 * ((1.0f - c2_0) / max(c2_0, 9.99999993922529029e-09f))));
}


#line 145
float3 schlick_0(float3 f0_0, float c_4)
{
    float m_0 = 1.0f - saturate(c_4);
    float m2_0 = m_0 * m_0;
    return f0_0 + (float3(1.0f)  - f0_0) * float3((m2_0 * m2_0 * m_0)) ;
}


#line 393
float ggxAlbedo_0(float cosO_2, float alpha_2, KernelContext_0 thread* kernelContext_28)
{
    float x_4 = saturate(cosO_2) * 31.0f;
    float y_3 = saturate(sqrt(alpha_2)) * 31.0f;
    uint _S120 = min(uint(x_4), 30U);
    uint _S121 = min(uint(y_3), 30U);
    float fx_2 = x_4 - float(_S120);
    float fy_2 = y_3 - float(_S121);
    uint _S122 = _S121 * 32U + _S120;

#line 401
    float _S123 = albedoAt_0(_S122, kernelContext_28);

#line 401
    float _S124 = albedoAt_0(_S122 + 1U, kernelContext_28);

#line 401
    float a_4 = mix(_S123, _S124, fx_2);
    uint _S125 = (_S121 + 1U) * 32U + _S120;

#line 402
    float _S126 = albedoAt_0(_S125, kernelContext_28);

#line 402
    float _S127 = albedoAt_0(_S125 + 1U, kernelContext_28);
    return mix(a_4, mix(_S126, _S127, fx_2), fy_2);
}


#line 367
struct Surface_0
{
    float3 albedo_0;
    float metallic_0;
    float alpha_3;
    float transmission_1;
    float ior_1;
    float eta_1;
    float fSel_0;
    float tComp_0;
    float coat_0;
    float coatAlpha_0;
    float3 sheenColor_0;
    float sheenAlpha_0;
    float sheenP_0;
    float coatP_0;
};


#line 410
float3 multiscatterFactor_0(const Surface_0 thread* s_4, float cosO_3, KernelContext_0 thread* kernelContext_29)
{
    if(kernelContext_29->params_0[int(29)] == 0U)
    {

#line 413
        return float3(1.0f) ;
    }

#line 413
    float3 _S128 = s_4->albedo_0;

#line 413
    float _S129 = ggxAlbedo_0(cosO_3, s_4->alpha_3, kernelContext_29);
    return float3(1.0f)  + _S128 * float3((1.0f / max(_S129, 0.05000000074505806f) - 1.0f)) ;
}


#line 458
float sheenCore_0(float woz_0, float wiz_0, float hz_1, float alpha_4)
{



    return (2.0f + 1.0f / alpha_4) * pow(sqrt(max(1.0f - hz_1 * hz_1, 0.0f)), 1.0f / alpha_4) / 6.2831854820251465f * (1.0f / (4.0f * (wiz_0 + woz_0 - wiz_0 * woz_0))) * wiz_0;
}


#line 385
struct Lobes_0
{
    float3 diffuse_0;
    float3 specular_1;
};


#line 468
Lobes_0 evalLobes_0(const Surface_0 thread* s_5, float3 woL_0, float3 wiL_0, KernelContext_0 thread* kernelContext_30)
{
    float3 hh_0 = normalize(woL_0 + wiL_0);
    float _S130 = max(dot(woL_0, hh_0), 0.0f);

    float _S131 = hh_0.z;

#line 473
    float _S132 = woL_0.z;

#line 473
    float _S133 = wiL_0.z;

#line 473
    float _S134 = 4.0f * _S132;

#line 473
    float core_0 = D_0(_S131, s_5->alpha_3) * G1_0(_S132, s_5->alpha_3) * G1_0(_S133, s_5->alpha_3) / _S134;

#line 473
    float _S135 = s_5->transmission_1;

    thread Lobes_0 l_0;

#line 475
    float _S136 = s_5->metallic_0;

#line 475
    float3 _S137 = s_5->albedo_0;
    float3 _S138 = float3(s_5->metallic_0)  * schlick_0(s_5->albedo_0, _S130);

#line 476
    float3 _S139 = multiscatterFactor_0(s_5, _S132, kernelContext_30);
    float _S140 = 1.0f - _S136;

#line 477
    float _S141 = 1.0f - _S135;

#line 476
    (&l_0)->specular_1 = _S138 * _S139 * float3(core_0)  + float3((_S140 * (_S135 * fresnelDielectric_0(_S130, s_5->eta_1) * s_5->tComp_0 + _S141 * fresnelDielectric_0(_S130, s_5->ior_1)) * core_0)) ;

    (&l_0)->diffuse_0 = float3((_S140 * _S141 * (1.0f - s_5->fSel_0)))  * _S137 * float3((_S133 / 3.1415927410125732f)) ;

#line 478
    float _S142 = s_5->sheenP_0;

    if((s_5->sheenP_0) > 0.0f)
    {

#line 480
        float3 _S143 = float3((1.0f - _S142)) ;

        (&l_0)->specular_1 = _S143 * (&l_0)->specular_1 + s_5->sheenColor_0 * float3(sheenCore_0(_S132, _S133, _S131, s_5->sheenAlpha_0)) ;
        (&l_0)->diffuse_0 = (&l_0)->diffuse_0 * _S143;

#line 480
    }

#line 480
    float _S144 = s_5->coat_0;

#line 485
    if((s_5->coat_0) > 0.0f)
    {

#line 485
        float3 _S145 = float3((1.0f - s_5->coatP_0)) ;

#line 491
        (&l_0)->specular_1 = _S145 * (&l_0)->specular_1 + float3((_S144 * fresnelDielectric_0(_S130, 1.5f) * (D_0(_S131, s_5->coatAlpha_0) * G1_0(_S132, s_5->coatAlpha_0) * G1_0(_S133, s_5->coatAlpha_0) / _S134))) ;
        (&l_0)->diffuse_0 = (&l_0)->diffuse_0 * _S145;

#line 485
    }

#line 494
    return l_0;
}


#line 522
void Parts_addLight_0(Parts_0 thread* this_3, uint depth_4, uint cls_3, float3 c_5, float3 cd_0, float3 cs_0)
{
    this_3->total_0 = this_3->total_0 + c_5;
    if(depth_4 == 0U)
    {
        this_3->directDiffuse_0 = this_3->directDiffuse_0 + cd_0;
        this_3->specular_0 = this_3->specular_0 + cs_0;

#line 525
    }
    else
    {



        Parts_file_0(this_3, depth_4, cls_3, cd_0 + cs_0);

#line 525
    }

#line 532
    return;
}


#line 229
void addSlot_0(uint pixel_3, uint slot_0, float3 u_1, float3 s_6, float3 wi_0, float lit_0, float r_3, KernelContext_0 thread* kernelContext_31)
{

#line 229
    bool _S146;

    if(any(isnan(u_1)))
    {

#line 231
        _S146 = true;

#line 231
    }
    else
    {

#line 231
        _S146 = any(isinf(u_1));

#line 231
    }

#line 231
    if(_S146)
    {

#line 231
        _S146 = true;

#line 231
    }
    else
    {

#line 231
        _S146 = any(isnan(s_6));

#line 231
    }

#line 231
    if(_S146)
    {

#line 231
        _S146 = true;

#line 231
    }
    else
    {

#line 231
        _S146 = any(isinf(s_6));

#line 231
    }

#line 231
    if(_S146)
    {

#line 232
        return;
    }

#line 233
    uint o_4 = 65U * pixel_3 + 17U + 12U * slot_0;
    float w_6 = lum_0(u_1);
    float wd_0 = w_6 + lum_0(s_6);
    float device* _S147 = kernelContext_31->lighting_0+o_4;

#line 236
    *_S147 = *_S147 + u_1.x;
    float device* _S148 = kernelContext_31->lighting_0+(o_4 + 1U);

#line 237
    *_S148 = *_S148 + u_1.y;
    float device* _S149 = kernelContext_31->lighting_0+(o_4 + 2U);

#line 238
    *_S149 = *_S149 + u_1.z;
    float device* _S150 = kernelContext_31->lighting_0+(o_4 + 3U);

#line 239
    *_S150 = *_S150 + w_6;
    float device* _S151 = kernelContext_31->lighting_0+(o_4 + 4U);

#line 240
    *_S151 = *_S151 + w_6 * r_3;
    float device* _S152 = kernelContext_31->lighting_0+(o_4 + 5U);

#line 241
    *_S152 = *_S152 + s_6.x;
    float device* _S153 = kernelContext_31->lighting_0+(o_4 + 6U);

#line 242
    *_S153 = *_S153 + s_6.y;
    float device* _S154 = kernelContext_31->lighting_0+(o_4 + 7U);

#line 243
    *_S154 = *_S154 + s_6.z;
    float device* _S155 = kernelContext_31->lighting_0+(o_4 + 8U);

#line 244
    *_S155 = *_S155 + wd_0 * wi_0.x;
    float device* _S156 = kernelContext_31->lighting_0+(o_4 + 9U);

#line 245
    *_S156 = *_S156 + wd_0 * wi_0.y;
    float device* _S157 = kernelContext_31->lighting_0+(o_4 + 10U);

#line 246
    *_S157 = *_S157 + wd_0 * wi_0.z;
    float device* _S158 = kernelContext_31->lighting_0+(o_4 + 11U);

#line 247
    *_S158 = *_S158 + wd_0 * lit_0;
    return;
}


#line 894
void restirGbuffer_0(uint pixel_4, float3 p_4, float3 n_2, KernelContext_0 thread* kernelContext_32)
{
    uint co_1 = restirBase_0(pixel_4, kernelContext_32->params_0[int(6)] & 1U);
    *(kernelContext_32->restir_0+(co_1 + 8U)) = p_4.x;
    *(kernelContext_32->restir_0+(co_1 + 9U)) = p_4.y;
    *(kernelContext_32->restir_0+(co_1 + 10U)) = p_4.z;
    *(kernelContext_32->restir_0+(co_1 + 11U)) = n_2.x;
    *(kernelContext_32->restir_0+(co_1 + 12U)) = n_2.y;
    *(kernelContext_32->restir_0+(co_1 + 13U)) = n_2.z;
    *(kernelContext_32->restir_0+(co_1 + 14U)) = (as_type<float>((1U)));
    return;
}


#line 497
float3 evalReflective_0(const Surface_0 thread* s_7, float3 woL_1, float3 wiL_1, KernelContext_0 thread* kernelContext_33)
{

#line 497
    Lobes_0 _S159 = evalLobes_0(s_7, woL_1, wiL_1, kernelContext_33);


    return _S159.specular_1 + _S159.diffuse_0;
}


#line 910
void restirGIPrepare_0(uint pixel_5, float3 p_5, float3 n_3, float pHitT_0, const Surface_0 thread* surf_0, float3 T_0, float3 B_0, float3 woL_2, Rng_0 thread* rng_2, KernelContext_0 thread* kernelContext_34)
{
    uint w_7 = kernelContext_34->params_0[int(0)];
    uint _S160 = kernelContext_34->params_0[int(6)] & 1U;
    float _S161 = float(max(kernelContext_34->params_0[int(38)], 1U));



    float3 _S162 = float3(0.0f) ;

#line 918
    float pSel_0;

#line 918
    float mTotal_0;

#line 918
    float wsum_0;

#line 918
    float3 cSel_0;

#line 918
    float3 xSel_0;

#line 918
    float3 nSel_0;

#line 918
    float3 lSel_0;

#line 918
    uint k_2;



    if(kernelContext_34->params_0[int(6)] > 0U)
    {
        uint _S163 = pixel_5 % w_7;

#line 924
        int nx_0 = int(_S163);
        uint _S164 = pixel_5 / w_7;

#line 925
        int ny_0 = int(_S164);

#line 925
        pSel_0 = 0.0f;

#line 925
        cSel_0 = _S162;

#line 925
        xSel_0 = _S162;

#line 925
        nSel_0 = _S162;

#line 925
        lSel_0 = _S162;

#line 925
        k_2 = 0U;

#line 925
        mTotal_0 = 0.0f;

#line 925
        wsum_0 = 0.0f;
        for(;;)
        {

#line 926
            if(k_2 < 3U)
            {
            }
            else
            {

#line 926
                break;
            }

#line 926
            bool _S165;

#line 926
            bool _S166;

#line 926
            bool _S167;

#line 926
            int ny_1;

#line 926
            int nx_1;



            if(k_2 > 0U)
            {
                float _S168 = Rng_next_0(rng_2);

#line 932
                int nx_2 = nx_0 + (int(_S168 * 13.0f) - int(6));
                float _S169 = Rng_next_0(rng_2);

#line 933
                int ny_2 = ny_0 + (int(_S169 * 13.0f) - int(6));
                if(nx_2 < int(0))
                {

#line 934
                    _S165 = true;

#line 934
                }
                else
                {

#line 934
                    _S165 = ny_2 < int(0);

#line 934
                }

#line 934
                if(_S165)
                {

#line 934
                    _S166 = true;

#line 934
                }
                else
                {

#line 934
                    _S166 = nx_2 >= int(w_7);

#line 934
                }

#line 934
                if(_S166)
                {

#line 934
                    _S167 = true;

#line 934
                }
                else
                {

#line 934
                    _S167 = ny_2 >= int(kernelContext_34->params_0[int(1)]);

#line 934
                }

#line 934
                if(_S167)
                {

#line 935
                    k_2 = k_2 + 1U;

#line 926
                    continue;
                }

#line 926
                ny_1 = ny_2;

#line 926
                nx_1 = nx_2;



            }
            else
            {

#line 930
                ny_1 = ny_0;

#line 930
                nx_1 = nx_0;

#line 930
            }

#line 937
            uint ro_0 = restirBase_0(uint(ny_1) * w_7 + uint(nx_1), _S160 ^ 1U);
            if((as_type<uint>((*(kernelContext_34->restir_0+(ro_0 + 14U))))) == 0U)
            {

#line 938
                _S165 = true;

#line 938
            }
            else
            {

#line 938
                _S165 = (as_type<uint>((*(kernelContext_34->restir_0+(ro_0 + 27U))))) == 0U;

#line 938
            }

#line 938
            if(_S165)
            {

#line 939
                k_2 = k_2 + 1U;

#line 926
                continue;
            }

#line 940
            float3 pq_0 = float3(*(kernelContext_34->restir_0+(ro_0 + 8U)), *(kernelContext_34->restir_0+(ro_0 + 9U)), *(kernelContext_34->restir_0+(ro_0 + 10U)));

            if((dot(float3(*(kernelContext_34->restir_0+(ro_0 + 11U)), *(kernelContext_34->restir_0+(ro_0 + 12U)), *(kernelContext_34->restir_0+(ro_0 + 13U))), n_3)) < 0.89999997615814209f)
            {

#line 942
                _S166 = true;

#line 942
            }
            else
            {

#line 942
                _S166 = (length(pq_0 - p_5)) > (0.05000000074505806f * max(pHitT_0, 0.0099999997764825821f));

#line 942
            }

#line 942
            if(_S166)
            {

#line 943
                k_2 = k_2 + 1U;

#line 926
                continue;
            }

#line 944
            float3 x2_0 = float3(*(kernelContext_34->restir_0+(ro_0 + 16U)), *(kernelContext_34->restir_0+(ro_0 + 17U)), *(kernelContext_34->restir_0+(ro_0 + 18U)));
            float3 n2_0 = float3(*(kernelContext_34->restir_0+(ro_0 + 19U)), *(kernelContext_34->restir_0+(ro_0 + 20U)), *(kernelContext_34->restir_0+(ro_0 + 21U)));
            float3 l2_0 = float3(*(kernelContext_34->restir_0+(ro_0 + 22U)), *(kernelContext_34->restir_0+(ro_0 + 23U)), *(kernelContext_34->restir_0+(ro_0 + 24U)));
            float _S170 = min(*(kernelContext_34->restir_0+(ro_0 + 26U)), _S161);
            float mTotal_1 = mTotal_0 + _S170;
            float3 toX_0 = x2_0 - p_5;
            float dR_0 = length(toX_0);
            float3 wi_1 = toX_0 / float3(max(dR_0, 9.99999997475242708e-07f)) ;
            float dQ_0 = length(x2_0 - pq_0);
            float cosT_1 = dot(n_3, wi_1);
            float cosR_0 = abs(dot(n2_0, wi_1));
            float cosQ_0 = abs(dot(n2_0, normalize(pq_0 - x2_0)));
            if(cosT_1 <= 0.0f)
            {

#line 956
                _S167 = true;

#line 956
            }
            else
            {

#line 956
                _S167 = dR_0 < 0.0010000000474974513f;

#line 956
            }

#line 956
            bool _S171;

#line 956
            if(_S167)
            {

#line 956
                _S171 = true;

#line 956
            }
            else
            {

#line 956
                _S171 = cosR_0 < 0.0010000000474974513f;

#line 956
            }

#line 956
            bool _S172;

#line 956
            if(_S171)
            {

#line 956
                _S172 = true;

#line 956
            }
            else
            {

#line 956
                _S172 = cosQ_0 < 0.0010000000474974513f;

#line 956
            }

#line 956
            if(_S172)
            {

#line 956
                mTotal_0 = mTotal_1;
                k_2 = k_2 + 1U;

#line 926
                continue;
            }

#line 958
            float jac_0 = cosR_0 / cosQ_0 * (dQ_0 * dQ_0) / (dR_0 * dR_0);

#line 958
            bool _S173;
            if(jac_0 > 10.0f)
            {

#line 959
                _S173 = true;

#line 959
            }
            else
            {

#line 959
                _S173 = jac_0 < 0.10000000149011612f;

#line 959
            }

#line 959
            if(_S173)
            {

#line 959
                mTotal_0 = mTotal_1;
                k_2 = k_2 + 1U;

#line 926
                continue;
            }

#line 926
            float3 _S174 = evalReflective_0(surf_0, woL_2, float3(dot(wi_1, T_0), dot(wi_1, B_0), cosT_1), kernelContext_34);

#line 961
            float3 c_6 = _S174 * l2_0;
            float phat_0 = lum_0(c_6);

#line 962
            bool _S175;
            if(phat_0 <= 0.0f)
            {

#line 963
                _S175 = true;

#line 963
            }
            else
            {

#line 963
                bool _S176 = occluded_0(p_5, wi_1, dR_0 * 0.99900001287460327f, kernelContext_34);

#line 963
                _S175 = _S176;

#line 963
            }

#line 963
            if(_S175)
            {

#line 963
                mTotal_0 = mTotal_1;
                k_2 = k_2 + 1U;

#line 926
                continue;
            }

#line 965
            float wgt_0 = phat_0 * *(kernelContext_34->restir_0+(ro_0 + 25U)) * _S170 * jac_0;
            float wsum_1 = wsum_0 + wgt_0;
            float _S177 = Rng_next_0(rng_2);

#line 967
            float pSel_1;

#line 967
            float3 cSel_1;

#line 967
            float3 xSel_1;

#line 967
            float3 nSel_1;

#line 967
            float3 lSel_1;

#line 967
            if((_S177 * wsum_1) < wgt_0)
            {

#line 967
                pSel_1 = phat_0;

#line 967
                cSel_1 = c_6;

#line 967
                xSel_1 = x2_0;

#line 967
                nSel_1 = n2_0;

#line 967
                lSel_1 = l2_0;

#line 967
            }
            else
            {

#line 967
                pSel_1 = pSel_0;

#line 967
                cSel_1 = cSel_0;

#line 967
                xSel_1 = xSel_0;

#line 967
                nSel_1 = nSel_0;

#line 967
                lSel_1 = lSel_0;

#line 967
            }

#line 967
            pSel_0 = pSel_1;

#line 967
            cSel_0 = cSel_1;

#line 967
            xSel_0 = xSel_1;

#line 967
            nSel_0 = nSel_1;

#line 967
            lSel_0 = lSel_1;

#line 967
            mTotal_0 = mTotal_1;

#line 967
            wsum_0 = wsum_1;

#line 926
            k_2 = k_2 + 1U;

#line 926
        }

#line 922
    }
    else
    {

#line 922
        pSel_0 = 0.0f;

#line 922
        cSel_0 = _S162;

#line 922
        xSel_0 = _S162;

#line 922
        nSel_0 = _S162;

#line 922
        lSel_0 = _S162;

#line 922
        wsum_0 = 0.0f;

#line 922
        mTotal_0 = 0.0f;

#line 922
    }

#line 977
    uint so_0 = restirScratch_0(pixel_5);
    *(kernelContext_34->restir_0+so_0) = wsum_0;
    *(kernelContext_34->restir_0+(so_0 + 1U)) = mTotal_0;
    *(kernelContext_34->restir_0+(so_0 + 2U)) = pSel_0;

#line 980
    k_2 = 0U;
    for(;;)
    {

#line 981
        if(k_2 < 3U)
        {
        }
        else
        {

#line 981
            break;
        }
        *(kernelContext_34->restir_0+(so_0 + 3U + k_2)) = cSel_0[k_2];
        *(kernelContext_34->restir_0+(so_0 + 6U + k_2)) = xSel_0[k_2];
        *(kernelContext_34->restir_0+(so_0 + 9U + k_2)) = nSel_0[k_2];
        *(kernelContext_34->restir_0+(so_0 + 12U + k_2)) = lSel_0[k_2];

#line 981
        k_2 = k_2 + 1U;

#line 981
    }

#line 988
    *(kernelContext_34->restir_0+(so_0 + 22U)) = (as_type<float>((0U)));
    return;
}


#line 727
bool restirLight_0(uint e_0, uint recv_0, float3 x_5, float3 p_6, float3 n_4, float3 thread* wi_2, float thread* dist_0, float thread* cosi_1, float3 thread* g_0, float thread* plsa_0, KernelContext_0 thread* kernelContext_35)
{
    uint o_5 = e_0 * 16U;
    float3 a_5 = float3(kernelContext_35->emitters_0[o_5], kernelContext_35->emitters_0[o_5 + 1U], kernelContext_35->emitters_0[o_5 + 2U]);
    float3 b_1 = float3(kernelContext_35->emitters_0[o_5 + 3U], kernelContext_35->emitters_0[o_5 + 4U], kernelContext_35->emitters_0[o_5 + 5U]);
    float3 c_7 = float3(kernelContext_35->emitters_0[o_5 + 6U], kernelContext_35->emitters_0[o_5 + 7U], kernelContext_35->emitters_0[o_5 + 8U]);
    float3 toL_0 = x_5 - p_6;
    float d2_0 = dot(toL_0, toL_0);
    float _S178 = sqrt(d2_0);

#line 735
    *dist_0 = _S178;
    float3 _S179 = toL_0 / float3(max(_S178, 9.99999997475242708e-07f)) ;

#line 736
    *wi_2 = _S179;
    float cosl_0 = abs(dot(normalize(cross(b_1 - a_5, c_7 - a_5)), _S179));
    *cosi_1 = dot(n_4, _S179);
    *g_0 = float3(kernelContext_35->emitters_0[o_5 + 9U], kernelContext_35->emitters_0[o_5 + 10U], kernelContext_35->emitters_0[o_5 + 11U]) * float3((cosl_0 / max(d2_0, 9.999999960041972e-13f))) ;


    *plsa_0 = kernelContext_35->emitters_0[o_5 + 13U] * d2_0 / (max(kernelContext_35->emitters_0[o_5 + 12U], 1.00000000317107685e-30f) * max(cosl_0, 9.9999997473787516e-06f));

#line 742
    bool _S180;

    if((*cosi_1) > 0.0f)
    {

#line 744
        _S180 = cosl_0 > 9.9999997473787516e-06f;

#line 744
    }
    else
    {

#line 744
        _S180 = false;

#line 744
    }

#line 744
    if(_S180)
    {

#line 744
        _S180 = d2_0 > 9.999999960041972e-13f;

#line 744
    }
    else
    {

#line 744
        _S180 = false;

#line 744
    }

#line 744
    if(_S180)
    {

#line 744
        _S180 = ((as_type<uint>((kernelContext_35->emitters_0[o_5 + 14U]))) & recv_0) != 0U;

#line 744
    }
    else
    {

#line 744
        _S180 = false;

#line 744
    }

#line 744
    return _S180;
}


#line 549
float reflectivePdf_0(const Surface_0 thread* s_8, float3 woL_3, float3 wiL_2)
{
    float3 hh_1 = normalize(woL_3 + wiL_2);

    float _S181 = woL_3.z;

#line 553
    float _S182 = hh_1.z;

#line 553
    float _S183 = 4.0f * _S181;

    float _S184 = 1.0f - s_8->metallic_0;

#line 555
    float _S185 = 1.0f - s_8->transmission_1;
    float _S186 = wiL_2.z;
    float q_1 = (s_8->metallic_0 + _S184 * (s_8->transmission_1 * fresnelDielectric_0(max(dot(woL_3, hh_1), 0.0f), s_8->eta_1) + _S185 * s_8->fSel_0)) * (G1_0(_S181, s_8->alpha_3) * D_0(_S182, s_8->alpha_3) / _S183) + _S184 * _S185 * (1.0f - s_8->fSel_0) * _S186 / 3.1415927410125732f;

#line 557
    float _S187 = s_8->sheenP_0;

#line 557
    float q_2;
    if((s_8->sheenP_0) > 0.0f)
    {

#line 558
        q_2 = (1.0f - _S187) * q_1 + _S187 * _S186 / 3.1415927410125732f;

#line 558
    }
    else
    {

#line 558
        q_2 = q_1;

#line 558
    }

    if((s_8->coat_0) > 0.0f)
    {

#line 560
        q_2 = (1.0f - s_8->coatP_0) * q_2 + s_8->coatP_0 * (G1_0(_S181, s_8->coatAlpha_0) * D_0(_S182, s_8->coatAlpha_0) / _S183);

#line 560
    }

#line 565
    return q_2;
}


#line 748
float restirMis_0(const Surface_0 thread* surf_1, float3 woL_4, float3 wiL_3, float plsa_1)
{

#line 748
    float _S188 = reflectivePdf_0(surf_1, woL_4, wiL_3);


    float _S189 = plsa_1 * plsa_1;

#line 751
    return _S189 / max(_S189 + _S188 * _S188, 1.00000000317107685e-30f);
}

struct RestirPick_0
{
    bool valid_0;
    uint e_1;
    float3 x_6;
    float W_0;
    bool occ_0;
};


#line 768
RestirPick_0 restirDI_0(uint pixel_6, uint recv_1, float3 p_7, float3 n_5, float pHitT_1, const Surface_0 thread* surf_2, float3 T_1, float3 B_1, float3 woL_5, Rng_0 thread* rng_3, KernelContext_0 thread* kernelContext_36)
{

#line 768
    uint lo_0;

#line 768
    float q_3;

#line 768
    float phat_1;

#line 768
    float selPhat_0;

#line 768
    float3 selX_0;

#line 768
    bool _S190;

    uint w_8 = kernelContext_36->params_0[int(0)];
    uint cur_0 = kernelContext_36->params_0[int(6)] & 1U;
    uint _S191 = kernelContext_36->params_0[int(23)];
    float _S192 = float(max(kernelContext_36->params_0[int(38)], 1U));



    float3 _S193 = float3(0.0f) ;

#line 777
    uint selE_0 = 0U;

#line 777
    float selPhat_1 = 0.0f;

#line 777
    float3 selX_1 = _S193;

#line 777
    uint k_3 = 0U;

#line 777
    float mTotal_2 = 0.0f;

#line 777
    float wsum_2 = 0.0f;

    for(;;)
    {

#line 779
        if(k_3 < (max(kernelContext_36->params_0[int(37)], 1U)))
        {
        }
        else
        {

#line 779
            break;
        }
        float _S194 = Rng_next_0(rng_3);
        float ua_0 = Rng_next_0(rng_3);
        float ub_0 = Rng_next_0(rng_3);

        uint _S195 = _S191 - 1U;

#line 785
        lo_0 = 0U;

#line 785
        uint hi_0 = _S195;
        for(;;)
        {

#line 786
            if(lo_0 < hi_0)
            {
            }
            else
            {

#line 786
                break;
            }
            uint mid_0 = (lo_0 + hi_0) / 2U;
            if(kernelContext_36->emitCdf_0[mid_0] >= _S194)
            {

#line 789
                hi_0 = mid_0;

#line 789
            }
            else
            {

#line 789
                lo_0 = mid_0 + 1U;

#line 789
            }

#line 786
        }

#line 794
        uint o_6 = lo_0 * 16U;



        float su_0 = sqrt(ua_0);
        float3 x_7 = float3(kernelContext_36->emitters_0[o_6], kernelContext_36->emitters_0[o_6 + 1U], kernelContext_36->emitters_0[o_6 + 2U]) * float3((1.0f - su_0))  + float3(kernelContext_36->emitters_0[o_6 + 3U], kernelContext_36->emitters_0[o_6 + 4U], kernelContext_36->emitters_0[o_6 + 5U]) * float3((su_0 * (1.0f - ub_0)))  + float3(kernelContext_36->emitters_0[o_6 + 6U], kernelContext_36->emitters_0[o_6 + 7U], kernelContext_36->emitters_0[o_6 + 8U]) * float3((su_0 * ub_0)) ;
        float area_0 = kernelContext_36->emitters_0[o_6 + 12U];
        if(area_0 > 0.0f)
        {

#line 801
            q_3 = kernelContext_36->emitters_0[o_6 + 13U] / area_0;

#line 801
        }
        else
        {

#line 801
            q_3 = 0.0f;

#line 801
        }
        thread float3 wi_3;

#line 802
        thread float3 g_1;
        thread float dist_1;

#line 803
        thread float cosi_2;

#line 803
        thread float plsa_2;

        if(q_3 > 0.0f)
        {

#line 805
            bool _S196 = restirLight_0(lo_0, recv_1, x_7, p_7, n_5, &wi_3, &dist_1, &cosi_2, &g_1, &plsa_2, kernelContext_36);

#line 805
            _S190 = _S196;

#line 805
        }
        else
        {

#line 805
            _S190 = false;

#line 805
        }

#line 805
        if(_S190)
        {
            float3 wiL_4 = float3(dot(wi_3, T_1), dot(wi_3, B_1), cosi_2);

#line 807
            float3 _S197 = evalReflective_0(surf_2, woL_5, wiL_4, kernelContext_36);
            float _S198 = lum_0(_S197 * g_1);

#line 808
            float _S199 = restirMis_0(surf_2, woL_5, wiL_4, plsa_2);

#line 808
            phat_1 = _S198 * _S199;

#line 805
        }
        else
        {

#line 805
            phat_1 = 0.0f;

#line 805
        }

#line 810
        float wgt_1 = phat_1 / max(q_3, 1.00000000317107685e-30f);
        float mTotal_3 = mTotal_2 + 1.0f;
        if(phat_1 > 0.0f)
        {
            float wsum_3 = wsum_2 + wgt_1;
            float _S200 = Rng_next_0(rng_3);

#line 815
            uint selE_1;

#line 815
            if((_S200 * wsum_3) < wgt_1)
            {

#line 815
                selE_1 = lo_0 + 1U;

#line 815
                selPhat_0 = phat_1;

#line 815
                selX_0 = x_7;

#line 815
            }
            else
            {

#line 815
                selE_1 = selE_0;

#line 815
                selPhat_0 = selPhat_1;

#line 815
                selX_0 = selX_1;

#line 815
            }

#line 815
            selE_0 = selE_1;

#line 815
            selPhat_1 = selPhat_0;

#line 815
            selX_1 = selX_0;

#line 815
            wsum_2 = wsum_3;

#line 812
        }

#line 779
        k_3 = k_3 + 1U;

#line 779
        mTotal_2 = mTotal_3;

#line 779
    }

#line 823
    if(kernelContext_36->params_0[int(6)] > 0U)
    {
        uint _S201 = pixel_6 % w_8;

#line 825
        int nx_3 = int(_S201);
        uint _S202 = pixel_6 / w_8;

#line 826
        int ny_3 = int(_S202);

#line 826
        k_3 = 0U;
        for(;;)
        {

#line 827
            if(k_3 < 3U)
            {
            }
            else
            {

#line 827
                break;
            }

#line 827
            bool _S203;

#line 827
            int ny_4;

#line 827
            int nx_4;



            if(k_3 > 0U)
            {
                float _S204 = Rng_next_0(rng_3);

#line 833
                int nx_5 = nx_3 + (int(_S204 * 13.0f) - int(6));
                float _S205 = Rng_next_0(rng_3);

#line 834
                int ny_5 = ny_3 + (int(_S205 * 13.0f) - int(6));
                if(nx_5 < int(0))
                {

#line 835
                    _S190 = true;

#line 835
                }
                else
                {

#line 835
                    _S190 = ny_5 < int(0);

#line 835
                }

#line 835
                if(_S190)
                {

#line 835
                    _S203 = true;

#line 835
                }
                else
                {

#line 835
                    _S203 = nx_5 >= int(w_8);

#line 835
                }

#line 835
                bool _S206;

#line 835
                if(_S203)
                {

#line 835
                    _S206 = true;

#line 835
                }
                else
                {

#line 835
                    _S206 = ny_5 >= int(kernelContext_36->params_0[int(1)]);

#line 835
                }

#line 835
                if(_S206)
                {

#line 836
                    k_3 = k_3 + 1U;

#line 827
                    continue;
                }

#line 827
                ny_4 = ny_5;

#line 827
                nx_4 = nx_5;



            }
            else
            {

#line 831
                ny_4 = ny_3;

#line 831
                nx_4 = nx_3;

#line 831
            }

#line 838
            uint ro_1 = restirBase_0(uint(ny_4) * w_8 + uint(nx_4), cur_0 ^ 1U);
            uint ei_0 = (as_type<uint>((*(kernelContext_36->restir_0+ro_1))));
            if((as_type<uint>((*(kernelContext_36->restir_0+(ro_1 + 14U))))) == 0U)
            {

#line 840
                _S190 = true;

#line 840
            }
            else
            {

#line 840
                _S190 = ei_0 == 0U;

#line 840
            }

#line 840
            if(_S190)
            {

#line 841
                k_3 = k_3 + 1U;

#line 827
                continue;
            }

#line 843
            float3 pp_0 = float3(*(kernelContext_36->restir_0+(ro_1 + 8U)), *(kernelContext_36->restir_0+(ro_1 + 9U)), *(kernelContext_36->restir_0+(ro_1 + 10U)));
            if((dot(float3(*(kernelContext_36->restir_0+(ro_1 + 11U)), *(kernelContext_36->restir_0+(ro_1 + 12U)), *(kernelContext_36->restir_0+(ro_1 + 13U))), n_5)) < 0.89999997615814209f)
            {

#line 844
                _S203 = true;

#line 844
            }
            else
            {

#line 844
                _S203 = (length(pp_0 - p_7)) > (0.05000000074505806f * max(pHitT_1, 0.0099999997764825821f));

#line 844
            }

#line 844
            if(_S203)
            {

#line 845
                k_3 = k_3 + 1U;

#line 827
                continue;
            }

#line 846
            float3 xc_0 = float3(*(kernelContext_36->restir_0+(ro_1 + 1U)), *(kernelContext_36->restir_0+(ro_1 + 2U)), *(kernelContext_36->restir_0+(ro_1 + 3U)));
            float _S207 = min(*(kernelContext_36->restir_0+(ro_1 + 5U)), _S192);
            thread float3 wi_4;

#line 848
            thread float3 g_2;
            thread float dist_2;

#line 849
            thread float cosi_3;

#line 849
            thread float plsa_3;

#line 849
            bool _S208 = restirLight_0(ei_0 - 1U, recv_1, xc_0, p_7, n_5, &wi_4, &dist_2, &cosi_3, &g_2, &plsa_3, kernelContext_36);

            if(_S208)
            {
                float3 wiL_5 = float3(dot(wi_4, T_1), dot(wi_4, B_1), cosi_3);

#line 853
                float3 _S209 = evalReflective_0(surf_2, woL_5, wiL_5, kernelContext_36);
                float _S210 = lum_0(_S209 * g_2);

#line 854
                float _S211 = restirMis_0(surf_2, woL_5, wiL_5, plsa_3);

#line 854
                q_3 = _S210 * _S211;

#line 851
            }
            else
            {

#line 851
                q_3 = 0.0f;

#line 851
            }

#line 856
            float wgt_2 = q_3 * *(kernelContext_36->restir_0+(ro_1 + 4U)) * _S207;
            float mTotal_4 = mTotal_2 + _S207;
            if(wgt_2 > 0.0f)
            {
                float wsum_4 = wsum_2 + wgt_2;
                float _S212 = Rng_next_0(rng_3);

#line 861
                if((_S212 * wsum_4) < wgt_2)
                {

#line 861
                    lo_0 = ei_0;

#line 861
                    phat_1 = q_3;

#line 861
                    selX_0 = xc_0;

#line 861
                }
                else
                {

#line 861
                    lo_0 = selE_0;

#line 861
                    phat_1 = selPhat_1;

#line 861
                    selX_0 = selX_1;

#line 861
                }

#line 861
                selPhat_0 = wsum_4;

#line 858
            }
            else
            {

#line 858
                lo_0 = selE_0;

#line 858
                phat_1 = selPhat_1;

#line 858
                selX_0 = selX_1;

#line 858
                selPhat_0 = wsum_2;

#line 858
            }

#line 858
            selE_0 = lo_0;

#line 858
            selPhat_1 = phat_1;

#line 858
            selX_1 = selX_0;

#line 858
            mTotal_2 = mTotal_4;

#line 858
            wsum_2 = selPhat_0;

#line 827
            k_3 = k_3 + 1U;

#line 827
        }

#line 823
    }

#line 870
    thread RestirPick_0 r_4;
    if(selE_0 != 0U)
    {

#line 871
        _S190 = selPhat_1 > 0.0f;

#line 871
    }
    else
    {

#line 871
        _S190 = false;

#line 871
    }

#line 871
    (&r_4)->valid_0 = _S190;
    (&r_4)->e_1 = selE_0;
    (&r_4)->x_6 = selX_1;
    if(_S190)
    {

#line 874
        selPhat_1 = wsum_2 / (mTotal_2 * selPhat_1);

#line 874
    }
    else
    {

#line 874
        selPhat_1 = 0.0f;

#line 874
    }

#line 874
    (&r_4)->W_0 = selPhat_1;
    (&r_4)->occ_0 = false;
    if((&r_4)->valid_0)
    {
        thread float3 wi_5;

#line 878
        thread float3 g_3;
        thread float dist_3;

#line 879
        thread float cosi_4;

#line 879
        thread float plsa_4;

#line 879
        bool _S213 = restirLight_0(selE_0 - 1U, recv_1, selX_1, p_7, n_5, &wi_5, &dist_3, &cosi_4, &g_3, &plsa_4, kernelContext_36);

#line 879
        bool _S214 = occluded_0(p_7, wi_5, dist_3 * 0.99900001287460327f, kernelContext_36);

        (&r_4)->occ_0 = _S214;

#line 876
    }

#line 883
    uint co_2 = restirBase_0(pixel_6, cur_0);
    *(kernelContext_36->restir_0+co_2) = (as_type<float>((selE_0)));
    *(kernelContext_36->restir_0+(co_2 + 1U)) = selX_1.x;
    *(kernelContext_36->restir_0+(co_2 + 2U)) = selX_1.y;
    *(kernelContext_36->restir_0+(co_2 + 3U)) = selX_1.z;
    float device* _S215 = kernelContext_36->restir_0+(co_2 + 4U);

#line 888
    if((&r_4)->occ_0)
    {

#line 888
        selPhat_1 = 0.0f;

#line 888
    }
    else
    {

#line 888
        selPhat_1 = (&r_4)->W_0;

#line 888
    }

#line 888
    *_S215 = selPhat_1;
    *(kernelContext_36->restir_0+(co_2 + 5U)) = mTotal_2;
    return r_4;
}


#line 283
float3 envSample_0(float u1_0, float u2_0, float u3_0, float u4_0, float thread* pdf_0, float3 thread* le_0, KernelContext_0 thread* kernelContext_37)
{

#line 283
    uint lo_1;

    uint w_9 = kernelContext_37->params_0[int(24)];
    uint h_8 = kernelContext_37->params_0[int(25)];

    uint _S216 = h_8 - 1U;

#line 288
    uint lo_2 = 0U;

#line 288
    uint hi_1 = _S216;
    for(;;)
    {

#line 289
        if(lo_2 < hi_1)
        {
        }
        else
        {

#line 289
            break;
        }
        uint mid_1 = (lo_2 + hi_1) / 2U;
        if(kernelContext_37->envMarginal_0[mid_1] >= u1_0)
        {

#line 292
            lo_1 = lo_2;

#line 292
            hi_1 = mid_1;

#line 292
        }
        else
        {

#line 292
            lo_1 = mid_1 + 1U;

#line 292
        }

#line 292
        lo_2 = lo_1;

#line 289
    }

#line 299
    uint _S217 = w_9 - 1U;

#line 299
    lo_1 = 0U;

#line 299
    hi_1 = _S217;
    for(;;)
    {

#line 300
        if(lo_1 < hi_1)
        {
        }
        else
        {

#line 300
            break;
        }
        uint mid_2 = (lo_1 + hi_1) / 2U;
        if(kernelContext_37->envCond_0[lo_2 * w_9 + mid_2] >= u2_0)
        {

#line 303
            hi_1 = mid_2;

#line 303
        }
        else
        {

#line 303
            lo_1 = mid_2 + 1U;

#line 303
        }

#line 300
    }

#line 309
    float phi_0 = ((float(lo_1) + u3_0) / float(w_9) - 0.5f) * 2.0f * 3.1415927410125732f;
    float theta_0 = (float(lo_2) + u4_0) / float(h_8) * 3.1415927410125732f;
    float st_0 = sin(theta_0);

#line 311
    float3 _S218 = envTexel_0(lo_1, lo_2, kernelContext_37);
    *le_0 = _S218;
    float _S219 = lum_0(_S218);

#line 313
    float _S220 = pf_0(26U, kernelContext_37);

#line 313
    *pdf_0 = _S219 * _S220;
    return float3(st_0 * sin(phi_0), cos(theta_0), - st_0 * cos(phi_0));
}


#line 94
float4 nrcBounds_0(KernelContext_0 thread* kernelContext_38)
{

#line 94
    float _S221 = pf_0(45U, kernelContext_38);

#line 94
    float _S222 = pf_0(46U, kernelContext_38);

#line 94
    float _S223 = pf_0(47U, kernelContext_38);

#line 94
    float _S224 = pf_0(48U, kernelContext_38);

#line 94
    return float4(_S221, _S222, _S223, _S224);
}


#line 53 "shaders/include/nrc_net.slang"
float3 nrcUnit_0(float3 p_8, KernelContext_0 thread* kernelContext_39)
{

#line 53
    float4 _S225 = nrcBounds_0(kernelContext_39);

#line 53
    return saturate((p_8 - _S225.xyz) * float3(_S225.w) );
}


#line 29
float nrcLevelRes_0(uint l_1)
{

#line 29
    return floor(16.0f * pow(1.5f, float(l_1)));
}


#line 24
uint nrcHash_0(uint3 c_8, uint level_0)
{
    return ((((c_8.x) ^ (c_8.y * 2654435761U)) ^ (c_8.z * 805459861U)) ^ (level_0 * 2654435761U)) & 32767U;
}


#line 41
void nrcCorner_0(float3 u_2, uint level_1, uint k_4, uint thread* slot_1, float thread* w_10)
{

    float3 s_9 = u_2 * float3(nrcLevelRes_0(level_1)) ;
    float3 f_2 = floor(s_9);
    float3 t_3 = s_9 - f_2;
    uint _S226 = k_4 & 1U;

#line 47
    uint _S227 = (k_4 >> 1U) & 1U;

#line 47
    uint _S228 = (k_4 >> 2U) & 1U;
    uint3 c_9 = uint3(f_2) + uint3(_S226, _S227, _S228);

#line 48
    float _S229;
    if(_S226 != 0U)
    {

#line 49
        _S229 = t_3.x;

#line 49
    }
    else
    {

#line 49
        _S229 = 1.0f - t_3.x;

#line 49
    }

#line 49
    float _S230;

#line 49
    if(_S227 != 0U)
    {

#line 49
        _S230 = t_3.y;

#line 49
    }
    else
    {

#line 49
        _S230 = 1.0f - t_3.y;

#line 49
    }

#line 49
    float _S231 = _S229 * _S230;

#line 49
    if(_S228 != 0U)
    {

#line 49
        _S229 = t_3.z;

#line 49
    }
    else
    {

#line 49
        _S229 = 1.0f - t_3.z;

#line 49
    }

#line 49
    *w_10 = _S231 * _S229;
    *slot_1 = (level_1 * 32768U + nrcHash_0(c_9, level_1)) * 2U;
    return;
}


float nrcSoftplus_0(float x_8)
{

#line 55
    float _S232;

#line 55
    if(x_8 > 20.0f)
    {

#line 55
        _S232 = x_8;

#line 55
    }
    else
    {

#line 55
        _S232 = log(1.0f + exp(x_8));

#line 55
    }

#line 55
    return _S232;
}


#line 31
struct NrcAct_0
{
    array<float, int(19)> x_9;
    array<float, int(32)> a1_0;
    array<float, int(32)> a2_1;
    array<float, int(3)> pre3_0;
    float3 y_4;
};


#line 57
NrcAct_0 nrcForward_0(float3 p_9, float3 n_6, KernelContext_0 thread* kernelContext_40)
{

#line 57
    uint k_5;

#line 57
    float f0_1;

    thread NrcAct_0 a_6;

#line 59
    float3 _S233 = nrcUnit_0(p_9, kernelContext_40);

#line 59
    uint l_2 = 0U;

    for(;;)
    {

#line 61
        if(l_2 < 8U)
        {
        }
        else
        {

#line 61
            break;
        }

#line 61
        k_5 = 0U;

#line 61
        f0_1 = 0.0f;

#line 61
        float f1_0 = 0.0f;


        for(;;)
        {

#line 64
            if(k_5 < 8U)
            {
            }
            else
            {

#line 64
                break;
            }
            thread uint slot_2;
            thread float w_11;
            nrcCorner_0(_S233, l_2, k_5, &slot_2, &w_11);
            float f0_2 = f0_1 + w_11 * *(kernelContext_40->restir_0+slot_2);
            float f1_1 = f1_0 + w_11 * *(kernelContext_40->restir_0+(slot_2 + 1U));

#line 64
            k_5 = k_5 + 1U;

#line 64
            f0_1 = f0_2;

#line 64
            f1_0 = f1_1;

#line 64
        }

#line 72
        uint _S234 = 2U * l_2;

#line 72
        (&a_6)->x_9[_S234] = f0_1;
        (&a_6)->x_9[_S234 + 1U] = f1_0;

#line 61
        l_2 = l_2 + 1U;

#line 61
    }

#line 61
    k_5 = 0U;

#line 75
    for(;;)
    {

#line 75
        if(k_5 < 3U)
        {
        }
        else
        {

#line 75
            break;
        }

#line 76
        (&a_6)->x_9[16U + k_5] = n_6[k_5];

#line 75
        k_5 = k_5 + 1U;

#line 75
    }

#line 75
    uint j_4 = 0U;

    for(;;)
    {

#line 77
        if(j_4 < 32U)
        {
        }
        else
        {

#line 77
            break;
        }
        float device* _S235 = kernelContext_40->restir_0+(524896U + j_4);

#line 79
        k_5 = 0U;

#line 79
        f0_1 = *_S235;
        for(;;)
        {

#line 80
            if(k_5 < 19U)
            {
            }
            else
            {

#line 80
                break;
            }

#line 81
            float s_10 = f0_1 + *(kernelContext_40->restir_0+(524288U + j_4 * 19U + k_5)) * (&a_6)->x_9[k_5];

#line 80
            k_5 = k_5 + 1U;

#line 80
            f0_1 = s_10;

#line 80
        }

        (&a_6)->a1_0[j_4] = max(f0_1, 0.0f);

#line 77
        j_4 = j_4 + 1U;

#line 77
    }

#line 77
    j_4 = 0U;

#line 84
    for(;;)
    {

#line 84
        if(j_4 < 32U)
        {
        }
        else
        {

#line 84
            break;
        }
        float device* _S236 = kernelContext_40->restir_0+(525952U + j_4);

#line 86
        k_5 = 0U;

#line 86
        f0_1 = *_S236;
        for(;;)
        {

#line 87
            if(k_5 < 32U)
            {
            }
            else
            {

#line 87
                break;
            }

#line 88
            float s_11 = f0_1 + *(kernelContext_40->restir_0+(524928U + j_4 * 32U + k_5)) * (&a_6)->a1_0[k_5];

#line 87
            k_5 = k_5 + 1U;

#line 87
            f0_1 = s_11;

#line 87
        }

        (&a_6)->a2_1[j_4] = max(f0_1, 0.0f);

#line 84
        j_4 = j_4 + 1U;

#line 84
    }

#line 84
    uint o_7 = 0U;

#line 91
    for(;;)
    {

#line 91
        if(o_7 < 3U)
        {
        }
        else
        {

#line 91
            break;
        }
        float device* _S237 = kernelContext_40->restir_0+(526080U + o_7);

#line 93
        k_5 = 0U;

#line 93
        f0_1 = *_S237;
        for(;;)
        {

#line 94
            if(k_5 < 32U)
            {
            }
            else
            {

#line 94
                break;
            }

#line 95
            float s_12 = f0_1 + *(kernelContext_40->restir_0+(525984U + o_7 * 32U + k_5)) * (&a_6)->a2_1[k_5];

#line 94
            k_5 = k_5 + 1U;

#line 94
            f0_1 = s_12;

#line 94
        }

        (&a_6)->pre3_0[o_7] = f0_1;
        (&a_6)->y_4[o_7] = nrcSoftplus_0(f0_1);

#line 91
        o_7 = o_7 + 1U;

#line 91
    }

#line 99
    return a_6;
}

float3 nrcQuery_0(float3 p_10, float3 n_7, KernelContext_0 thread* kernelContext_41)
{

#line 102
    NrcAct_0 _S238 = nrcForward_0(p_10, n_7, kernelContext_41);

#line 102
    return _S238.y_4;
}


#line 172 "shaders/include/pt_core.slang"
float3 sampleVndf_0(float3 wo_0, float alpha_5, float u1_1, float u2_1)
{
    float3 vh_0 = normalize(float3(alpha_5 * wo_0.x, alpha_5 * wo_0.y, wo_0.z));
    float _S239 = vh_0.x;

#line 175
    float _S240 = vh_0.y;

#line 175
    float lensq_0 = _S239 * _S239 + _S240 * _S240;

#line 175
    float3 t1_0;
    if(lensq_0 > 0.0f)
    {

#line 176
        t1_0 = float3(- _S240, _S239, 0.0f) * float3(rsqrt(lensq_0)) ;

#line 176
    }
    else
    {

#line 176
        t1_0 = float3(1.0f, 0.0f, 0.0f);

#line 176
    }

    float r_5 = sqrt(u1_1);
    float phi_1 = 6.2831854820251465f * u2_1;
    float a_7 = r_5 * cos(phi_1);

    float s_13 = 0.5f * (1.0f + vh_0.z);
    float _S241 = 1.0f - a_7 * a_7;

#line 183
    float b_2 = (1.0f - s_13) * sqrt(_S241) + s_13 * (r_5 * sin(phi_1));
    float3 nh_0 = float3(a_7)  * t1_0 + float3(b_2)  * cross(vh_0, t1_0) + float3(sqrt(max(0.0f, _S241 - b_2 * b_2)))  * vh_0;
    return normalize(float3(alpha_5 * nh_0.x, alpha_5 * nh_0.y, max(0.0f, nh_0.z)));
}


#line 124
float3 cosineLocal_0(float u1_2, float u2_2)
{
    float r_6 = sqrt(u1_2);
    float phi_2 = 6.2831854820251465f * u2_2;
    return float3(r_6 * cos(phi_2), r_6 * sin(phi_2), sqrt(max(0.0f, 1.0f - u1_2)));
}


#line 645
struct Hit_0
{
    bool hit_0;
    uint inst_2;
    uint prim_1;
    float t_4;
};


#line 1001
bool shadePath_0(PathState_0 thread* st_1, const Hit_0 thread* hq_0, uint depth_5, uint pixel_7, KernelContext_0 thread* kernelContext_42)
{

#line 1001
    uint k_6;

#line 1001
    int chan_1;

#line 1001
    bool alive_0;

#line 1001
    bool _S242;

#line 1001
    float dist_4;

#line 1001
    float vv_0;

#line 1001
    float us_0;

#line 1001
    float _S243;

#line 1001
    float _S244;

#line 1001
    float3 wi_6;

#line 1001
    float3 li_0;

#line 1001
    bool _S245;

#line 1001
    bool _S246;

#line 1001
    bool chooseEnv_0;

#line 1001
    bool _S247;

#line 1001
    bool track_0;

#line 1001
    float _S248 = pf_0(20U, kernelContext_42);

#line 1001
    float _S249 = pf_0(21U, kernelContext_42);

#line 1001
    float _S250 = pf_0(22U, kernelContext_42);

    float3 _S251 = float3(_S248, _S249, _S250);
    bool _S252 = kernelContext_42->params_0[int(28)] != 0U;
    uint _S253 = kernelContext_42->params_0[int(5)];
    uint emitterCount_0 = kernelContext_42->params_0[int(23)];
    bool hasEnv_0 = kernelContext_42->params_0[int(24)] > 0U;

#line 1007
    float _S254;

    if(hasEnv_0)
    {

#line 1009
        if(emitterCount_0 > 0U)
        {

#line 1009
            _S254 = 0.5f;

#line 1009
        }
        else
        {

#line 1009
            _S254 = 1.0f;

#line 1009
        }

#line 1009
    }
    else
    {

#line 1009
        _S254 = 0.0f;

#line 1009
    }
    thread Rng_0 rng_4;
    (&rng_4)->state_1 = st_1->rng_0;

#line 1011
    uint cls_4 = st_1->cls_0;

#line 1011
    float3 dir_1 = st_1->dir_0;

#line 1011
    float3 org_1 = st_1->org_0;

#line 1011
    int chan_2 = st_1->chan_0;

#line 1011
    uint once_0 = 0U;

#line 1011
    float3 thr_1 = st_1->thr_0;

#line 1018
    for(;;)
    {

#line 1018
        if(once_0 < 1U)
        {
        }
        else
        {

#line 1018
            chan_1 = chan_2;

#line 1018
            alive_0 = true;

#line 1018
            break;
        }

#line 1018
        float wB_0;

        if(!hq_0->hit_0)
        {
            if(restirCompiled_0)
            {

#line 1022
                alive_0 = depth_5 == 0U;

#line 1022
            }
            else
            {

#line 1022
                alive_0 = false;

#line 1022
            }

#line 1022
            if(alive_0)
            {

#line 1022
                alive_0 = kernelContext_42->params_0[int(36)] != 0U;

#line 1022
            }
            else
            {

#line 1022
                alive_0 = false;

#line 1022
            }

#line 1022
            if(alive_0)
            {

#line 1022
                restirClear_0(pixel_7, kernelContext_42);

#line 1022
            }


            if(depth_5 == 0U)
            {

#line 1025
                alive_0 = kernelContext_42->params_0[int(42)] != 0U;

#line 1025
            }
            else
            {

#line 1025
                alive_0 = false;

#line 1025
            }

#line 1025
            if(alive_0)
            {

#line 1025
                chan_1 = chan_2;

#line 1025
                alive_0 = false;


                break;
            }

            Parts_add_0(&st_1->parts_0, depth_5, cls_4, thr_1 * _S251);
            if(hasEnv_0)
            {

                if(st_1->misPrev_0)
                {
                    if(st_1->restir_1)
                    {

#line 1037
                        alive_0 = depth_5 == 1U;

#line 1037
                    }
                    else
                    {

#line 1037
                        alive_0 = false;

#line 1037
                    }

#line 1037
                    if(alive_0)
                    {

#line 1037
                        _S254 = 1.0f;

#line 1037
                    }

#line 1037
                    float _S255 = envPdf_0(dir_1, kernelContext_42);

#line 1037
                    float pl_0 = _S254 * _S255;
                    float den_0 = st_1->qPrev_0 * st_1->qPrev_0 + pl_0 * pl_0;
                    if(den_0 > 0.0f)
                    {

#line 1039
                        _S254 = st_1->qPrev_0 * st_1->qPrev_0 / den_0;

#line 1039
                    }
                    else
                    {

#line 1039
                        _S254 = 1.0f;

#line 1039
                    }

#line 1039
                    wB_0 = _S254;

#line 1035
                }
                else
                {

#line 1035
                    wB_0 = 1.0f;

#line 1035
                }

#line 1035
                float3 _S256 = envRadiance_0(dir_1, kernelContext_42);

#line 1041
                Parts_add_0(&st_1->parts_0, depth_5, cls_4, thr_1 * _S256 * float3(wB_0) );

#line 1032
            }

#line 1032
            chan_1 = chan_2;

#line 1032
            alive_0 = false;

#line 1043
            break;
        }

#line 1043
        uint _S257 = hq_0->inst_2;


        uint inst_3 = hq_0->inst_2 * 16U;

#line 1046
        uint _S258 = hq_0->prim_1;
        uint tri_1 = kernelContext_42->instances_0[inst_3 + 1U] + 3U * hq_0->prim_1;
        uint vo_1 = kernelContext_42->instances_0[inst_3];
        uint _S259 = inst_3 + 4U;

#line 1049
        float3 _S260 = vertexPos_0(kernelContext_42->indices_0[tri_1] + vo_1, kernelContext_42);

#line 1049
        float3 _S261 = transformPoint_0(_S259, _S260, kernelContext_42);
        uint _S262 = tri_1 + 1U;

#line 1050
        float3 _S263 = vertexPos_0(kernelContext_42->indices_0[_S262] + vo_1, kernelContext_42);

#line 1050
        float3 _S264 = transformPoint_0(_S259, _S263, kernelContext_42);
        uint _S265 = tri_1 + 2U;

#line 1051
        float3 _S266 = vertexPos_0(kernelContext_42->indices_0[_S265] + vo_1, kernelContext_42);

#line 1051
        float3 _S267 = transformPoint_0(_S259, _S266, kernelContext_42);

        float3 _S268 = _S264 - _S261;

#line 1053
        float3 _S269 = _S267 - _S261;

#line 1053
        float3 _S270 = cross(_S268, _S269);

#line 1053
        float3 nOut_0 = normalize(_S270);
        float3 wo_1 = - dir_1;
        bool outside_1 = (dot(nOut_0, wo_1)) > 0.0f;

#line 1055
        float3 ng_0;
        if(outside_1)
        {

#line 1056
            ng_0 = nOut_0;

#line 1056
        }
        else
        {

#line 1056
            ng_0 = - nOut_0;

#line 1056
        }

#line 1056
        float _S271 = hq_0->t_4;

        st_1->pathLen_0 = st_1->pathLen_0 + hq_0->t_4;
        float3 hit_1 = org_1 + dir_1 * float3(_S271) ;

#line 1065
        float3 e3_0 = hit_1 - _S261;
        float d11_0 = dot(_S268, _S268);
        float d12_0 = dot(_S268, _S269);
        float d22_0 = dot(_S269, _S269);
        float _S272 = max(d11_0 * d22_0 - d12_0 * d12_0, 9.99999968265522539e-21f);
        float _S273 = dot(e3_0, _S268);

#line 1070
        float _S274 = dot(e3_0, _S269);

#line 1070
        float b1_0 = (d22_0 * _S273 - d12_0 * _S274) / _S272;
        float b2_0 = (d11_0 * _S274 - d12_0 * _S273) / _S272;

#line 1071
        float _S275 = opacityAt_0(_S257, _S258, float2(b1_0, b2_0), kernelContext_42);


        if(_S275 < 1.0f)
        {

#line 1074
            float _S276 = Rng_next_0(&rng_4);

#line 1074
            alive_0 = _S276 >= _S275;

#line 1074
        }
        else
        {

#line 1074
            alive_0 = false;

#line 1074
        }

#line 1074
        if(alive_0)
        {

#line 1074
            org_1 = hit_1 + dir_1 * float3(9.9999997473787516e-05f) ;

#line 1074
            chan_1 = chan_2;

#line 1074
            alive_0 = true;


            break;
        }

        float3 p_11 = hit_1 + ng_0 * float3(9.9999997473787516e-05f) ;
        bool _S277 = depth_5 == 1U;

#line 1081
        if(_S277)
        {

#line 1081
            _S242 = st_1->gi_0;

#line 1081
        }
        else
        {

#line 1081
            _S242 = false;

#line 1081
        }

#line 1081
        if(_S242)
        {

            uint _S278 = restirBase_0(pixel_7, kernelContext_42->params_0[int(6)] & 1U);

#line 1084
            k_6 = 0U;
            for(;;)
            {

#line 1085
                if(k_6 < 3U)
                {
                }
                else
                {

#line 1085
                    break;
                }
                *(kernelContext_42->restir_0+(_S278 + 16U + k_6)) = hit_1[k_6];
                *(kernelContext_42->restir_0+(_S278 + 19U + k_6)) = ng_0[k_6];

#line 1085
                k_6 = k_6 + 1U;

#line 1085
            }

#line 1090
            *(kernelContext_42->restir_0+(restirScratch_0(pixel_7) + 22U)) = (as_type<float>((1U)));

#line 1081
        }

#line 1095
        float _S279 = 1.0f - b1_0 - b2_0;

#line 1095
        float3 _S280 = vertexNormal_0(kernelContext_42->indices_0[tri_1] + vo_1, kernelContext_42);

#line 1095
        float3 _S281 = float3(_S279)  * _S280;

#line 1095
        float3 _S282 = vertexNormal_0(kernelContext_42->indices_0[_S262] + vo_1, kernelContext_42);

#line 1095
        float3 _S283 = _S281 + float3(b1_0)  * _S282;

#line 1095
        float3 _S284 = vertexNormal_0(kernelContext_42->indices_0[_S265] + vo_1, kernelContext_42);

#line 1095
        float3 nsObj_0 = _S283 + float3(b2_0)  * _S284;

#line 1095
        float3 ns_0;

        if((dot(nsObj_0, nsObj_0)) > 9.999999960041972e-13f)
        {

#line 1097
            float3 _S285 = transformNormal_0(_S259, nsObj_0, kernelContext_42);

            float3 ns_1 = normalize(_S285);
            if((dot(ns_1, nOut_0)) < 0.0f)
            {

#line 1100
                ns_0 = - ns_1;

#line 1100
            }
            else
            {

#line 1100
                ns_0 = ns_1;

#line 1100
            }

#line 1097
        }
        else
        {

#line 1097
            ns_0 = nOut_0;

#line 1097
        }

#line 1097
        float3 _S286;

#line 1103
        if(outside_1)
        {

#line 1103
            _S286 = ns_0;

#line 1103
        }
        else
        {

#line 1103
            _S286 = - ns_0;

#line 1103
        }

        uint mi_1 = kernelContext_42->instances_0[inst_3 + 2U] * 24U;
        float3 albedo_1 = float3(kernelContext_42->materials_0[mi_1], kernelContext_42->materials_0[mi_1 + 1U], kernelContext_42->materials_0[mi_1 + 2U]);

        uint texBase_0 = uint(kernelContext_42->materials_0[mi_1 + 10U]);
        uint texMR_0 = uint(kernelContext_42->materials_0[mi_1 + 11U]);
        uint texEm_0 = uint(kernelContext_42->materials_0[mi_1 + 12U]);
        uint texNm_0 = uint(kernelContext_42->materials_0[mi_1 + 13U]);
        float2 _S287 = float2(1.0f) ;
        float3 _S288 = float3(1.0f) ;

#line 1113
        float3 albedo_2;

#line 1113
        float3 texEmission_0;

#line 1113
        float3 n_8;

#line 1113
        float3 n_9;

#line 1113
        bool _S289;

#line 1113
        float2 texRM_0;
        if((texBase_0 + texMR_0 + texEm_0 + texNm_0) > 0U)
        {
            float2 uv0_1 = float2(kernelContext_42->uvs_0[2U * (kernelContext_42->indices_0[tri_1] + vo_1)], kernelContext_42->uvs_0[2U * (kernelContext_42->indices_0[tri_1] + vo_1) + 1U]);


            float2 _S290 = float2(kernelContext_42->uvs_0[2U * (kernelContext_42->indices_0[_S262] + vo_1)], kernelContext_42->uvs_0[2U * (kernelContext_42->indices_0[_S262] + vo_1) + 1U]) - uv0_1;

#line 1119
            float2 _S291 = float2(kernelContext_42->uvs_0[2U * (kernelContext_42->indices_0[_S265] + vo_1)], kernelContext_42->uvs_0[2U * (kernelContext_42->indices_0[_S265] + vo_1) + 1U]) - uv0_1;

#line 1119
            float2 uv_2 = uv0_1 + float2(b1_0)  * _S290 + float2(b2_0)  * _S291;


            float _S292 = _S290.x;

#line 1122
            float _S293 = _S291.y;

#line 1122
            float _S294 = _S292 * _S293;

#line 1122
            float _S295 = _S290.y;

#line 1122
            float _S296 = _S291.x;

#line 1122
            float uvPerWorld_0 = sqrt(abs(_S294 - _S295 * _S296) / max(length(_S270), 9.99999968265522539e-21f));
            float _S297 = st_1->pathLen_0;

#line 1123
            float _S298 = pf_0(27U, kernelContext_42);

#line 1123
            float footprint_1 = _S297 * _S298 / max(abs(dot(nOut_0, dir_1)), 0.10000000149011612f) * uvPerWorld_0;
            if(texBase_0 > 0U)
            {

#line 1124
                float3 _S299 = sampleTexture_0(texBase_0 - 1U, uv_2, footprint_1, kernelContext_42);

#line 1124
                albedo_2 = albedo_1 * _S299;

#line 1124
            }
            else
            {

#line 1124
                albedo_2 = albedo_1;

#line 1124
            }

            if(texMR_0 > 0U)
            {

#line 1126
                float3 _S300 = sampleTexture_0(texMR_0 - 1U, uv_2, footprint_1, kernelContext_42);

#line 1126
                texRM_0 = _S300.yz;

#line 1126
            }
            else
            {

#line 1126
                texRM_0 = _S287;

#line 1126
            }

            if(texEm_0 > 0U)
            {

#line 1128
                float3 _S301 = sampleTexture_0(texEm_0 - 1U, uv_2, footprint_1, kernelContext_42);

#line 1128
                texEmission_0 = _S301;

#line 1128
            }
            else
            {

#line 1128
                texEmission_0 = _S288;

#line 1128
            }

            if(texNm_0 > 0U)
            {

                float det_0 = _S294 - _S296 * _S295;

#line 1133
                float3 _S302 = float3(det_0) ;
                float3 dPdu_0 = (_S268 * float3(_S293)  - _S269 * float3(_S295) ) / _S302;
                float3 dPdv_0 = (_S269 * float3(_S292)  - _S268 * float3(_S296) ) / _S302;
                float3 tg_0 = dPdu_0 - ns_0 * float3(dot(ns_0, dPdu_0)) ;
                if((abs(det_0)) > 9.99999968265522539e-21f)
                {

#line 1137
                    _S289 = (dot(tg_0, tg_0)) > 9.99999968265522539e-21f;

#line 1137
                }
                else
                {

#line 1137
                    _S289 = false;

#line 1137
                }

#line 1137
                if(_S289)
                {
                    float3 tg_1 = normalize(tg_0);
                    float3 bt_0 = cross(ns_0, tg_1);
                    if((dot(bt_0, dPdv_0)) > 0.0f)
                    {

#line 1141
                        n_8 = - bt_0;

#line 1141
                    }
                    else
                    {

#line 1141
                        n_8 = bt_0;

#line 1141
                    }

#line 1141
                    float3 _S303 = sampleTexture_0(texNm_0 - 1U, uv_2, footprint_1, kernelContext_42);

                    float3 nt_0 = _S303 * float3(2.0f)  - float3(1.0f) ;
                    uint _S304 = mi_1 + 14U;

#line 1144
                    float3 ns_2 = normalize(float3((nt_0.x * kernelContext_42->materials_0[_S304]))  * tg_1 + float3((nt_0.y * kernelContext_42->materials_0[_S304]))  * n_8 + float3(nt_0.z)  * ns_0);
                    if(outside_1)
                    {

#line 1145
                        n_9 = ns_2;

#line 1145
                    }
                    else
                    {

#line 1145
                        n_9 = - ns_2;

#line 1145
                    }

#line 1145
                    n_8 = n_9;

#line 1137
                }
                else
                {

#line 1137
                    n_8 = _S286;

#line 1137
                }

#line 1130
            }
            else
            {

#line 1130
                n_8 = _S286;

#line 1130
            }

#line 1114
        }
        else
        {

#line 1114
            n_8 = _S286;

#line 1114
            texEmission_0 = _S288;

#line 1114
            texRM_0 = _S287;

#line 1114
            albedo_2 = albedo_1;

#line 1114
        }

#line 1151
        float woN_0 = dot(n_8, wo_1);
        if(woN_0 < 0.05000000074505806f)
        {

#line 1152
            n_9 = normalize(n_8 + wo_1 * float3((0.05000000074505806f - woN_0)) );

#line 1152
        }
        else
        {

#line 1152
            n_9 = n_8;

#line 1152
        }


        float3 _S305 = float3(kernelContext_42->materials_0[mi_1 + 3U], kernelContext_42->materials_0[mi_1 + 4U], kernelContext_42->materials_0[mi_1 + 5U]) * texEmission_0;

        if((st_1->prevInst_0) != 0U)
        {

#line 1157
            uint _S306 = emitMask_0(_S257, kernelContext_42);

#line 1157
            uint _S307 = recvMask_0(st_1->prevInst_0 - 1U, kernelContext_42);

#line 1157
            _S289 = (_S306 & _S307) == 0U;

#line 1157
        }
        else
        {

#line 1157
            _S289 = false;

#line 1157
        }

#line 1157
        float3 le_1;

#line 1157
        if(_S289)
        {

#line 1157
            le_1 = float3(0.0f) ;

#line 1157
        }
        else
        {

#line 1157
            le_1 = _S305;

#line 1157
        }

#line 1157
        bool _S308;

#line 1157
        bool _S309;

        if(any(le_1 > (float3(0.0f) )))
        {

            uint eb_0 = kernelContext_42->instances_0[inst_3 + 3U];
            if(st_1->misPrev_0)
            {

#line 1163
                _S308 = eb_0 != 0U;

#line 1163
            }
            else
            {

#line 1163
                _S308 = false;

#line 1163
            }

#line 1163
            if(_S308)
            {
                uint e_2 = (eb_0 - 1U + _S258) * 16U;
                float _S310 = max(abs(dot(nOut_0, dir_1)), 9.9999997473787516e-05f);
                if(st_1->restir_1)
                {

#line 1167
                    _S309 = _S277;

#line 1167
                }
                else
                {

#line 1167
                    _S309 = false;

#line 1167
                }

#line 1167
                if(_S309)
                {

#line 1167
                    wB_0 = 1.0f;

#line 1167
                }
                else
                {

#line 1167
                    wB_0 = 1.0f - _S254;

#line 1167
                }

#line 1167
                float pl_1 = wB_0 * kernelContext_42->emitters_0[e_2 + 13U] * _S271 * _S271 / (kernelContext_42->emitters_0[e_2 + 12U] * _S310);

#line 1167
                wB_0 = st_1->qPrev_0 * st_1->qPrev_0 / (st_1->qPrev_0 * st_1->qPrev_0 + pl_1 * pl_1);

#line 1163
            }
            else
            {

#line 1163
                wB_0 = 1.0f;

#line 1163
            }

#line 1170
            float3 _S311 = thr_1 * le_1 * float3(wB_0) ;

#line 1170
            Parts_add_0(&st_1->parts_0, depth_5, cls_4, _S311);
            if(_S277)
            {

#line 1171
                _S309 = st_1->gi_0;

#line 1171
            }
            else
            {

#line 1171
                _S309 = false;

#line 1171
            }

#line 1171
            if(_S309)
            {


                uint _S312 = restirScratch_0(pixel_7) + 18U;

#line 1175
                k_6 = 0U;
                for(;;)
                {

#line 1176
                    if(k_6 < 3U)
                    {
                    }
                    else
                    {

#line 1176
                        break;
                    }

#line 1177
                    float device* _S313 = kernelContext_42->restir_0+(_S312 + k_6);

#line 1177
                    *_S313 = *_S313 + _S311[k_6];

#line 1176
                    k_6 = k_6 + 1U;

#line 1176
                }

#line 1171
            }

#line 1159
        }

#line 1180
        float metallic_1 = kernelContext_42->materials_0[mi_1 + 6U] * texRM_0.y;
        float rough_1 = kernelContext_42->materials_0[mi_1 + 7U] * texRM_0.x;
        float transmission_2 = kernelContext_42->materials_0[mi_1 + 8U];
        float ior_2 = kernelContext_42->materials_0[mi_1 + 9U];
        float dispersion_0 = kernelContext_42->materials_0[mi_1 + 21U];
        if(dispersion_0 > 0.0f)
        {

#line 1185
            _S308 = transmission_2 > 0.0f;

#line 1185
        }
        else
        {

#line 1185
            _S308 = false;

#line 1185
        }

#line 1185
        float eta_2;

#line 1185
        float _S314;

#line 1185
        float3 thr_2;

#line 1185
        if(_S308)
        {


            if(chan_2 < int(0))
            {
                float _S315 = Rng_next_0(&rng_4);

#line 1191
                int _S316 = min(int(_S315 * 3.0f), int(2));
                if(_S316 == int(0))
                {

#line 1192
                    wB_0 = 1.0f;

#line 1192
                }
                else
                {

#line 1192
                    wB_0 = 0.0f;

#line 1192
                }

#line 1192
                if(_S316 == int(1))
                {

#line 1192
                    eta_2 = 1.0f;

#line 1192
                }
                else
                {

#line 1192
                    eta_2 = 0.0f;

#line 1192
                }

#line 1192
                if(_S316 == int(2))
                {

#line 1192
                    _S314 = 1.0f;

#line 1192
                }
                else
                {

#line 1192
                    _S314 = 0.0f;

#line 1192
                }

#line 1192
                float3 thr_3 = thr_1 * (float3(3.0f)  * float3(wB_0, eta_2, _S314));

#line 1192
                chan_1 = _S316;

#line 1192
                thr_2 = thr_3;

#line 1189
            }
            else
            {

#line 1189
                chan_1 = chan_2;

#line 1189
                thr_2 = thr_1;

#line 1189
            }

#line 1189
            wB_0 = max(ior_2 + float(chan_1 - int(1)) * (ior_2 - 1.0f) * 0.02500000037252903f * dispersion_0, 1.0f);

#line 1185
        }
        else
        {

#line 1185
            wB_0 = ior_2;

#line 1185
            chan_1 = chan_2;

#line 1185
            thr_2 = thr_1;

#line 1185
        }

#line 1198
        if(_S277)
        {

#line 1198
            _S309 = st_1->gi_0;

#line 1198
        }
        else
        {

#line 1198
            _S309 = false;

#line 1198
        }

#line 1198
        bool _S317;

#line 1198
        if(_S309)
        {

#line 1198
            _S317 = transmission_2 > 0.0f;

#line 1198
        }
        else
        {

#line 1198
            _S317 = false;

#line 1198
        }

#line 1198
        if(_S317)
        {

#line 1199
            *(kernelContext_42->restir_0+(restirScratch_0(pixel_7) + 22U)) = (as_type<float>((0U)));

#line 1198
        }

        float _S318 = max(rough_1 * rough_1, 0.0010000000474974513f);
        if(outside_1)
        {

#line 1201
            eta_2 = wB_0;

#line 1201
        }
        else
        {

#line 1201
            eta_2 = 1.0f / wB_0;

#line 1201
        }

        thread float3 T_2;

#line 1203
        thread float3 B_2;
        basis_0(n_9, &T_2, &B_2);
        float _S319 = max(dot(wo_1, n_9), 9.9999997473787516e-05f);

#line 1205
        float3 woL_6 = float3(dot(wo_1, T_2), dot(wo_1, B_2), _S319);
        float fSel_1 = fresnelDielectric_0(_S319, wB_0);
        thread Surface_0 surf_3;
        (&surf_3)->albedo_0 = albedo_2;
        (&surf_3)->metallic_0 = metallic_1;
        (&surf_3)->alpha_3 = _S318;
        (&surf_3)->transmission_1 = transmission_2;
        (&surf_3)->ior_1 = wB_0;
        (&surf_3)->eta_1 = eta_2;
        (&surf_3)->fSel_0 = fSel_1;


        (&surf_3)->tComp_0 = 1.0f;

#line 1217
        bool _S320;
        if(kernelContext_42->params_0[int(29)] != 0U)
        {

#line 1218
            _S320 = transmission_2 > 0.0f;

#line 1218
        }
        else
        {

#line 1218
            _S320 = false;

#line 1218
        }

#line 1218
        bool _S321;

#line 1218
        if(_S320)
        {

#line 1218
            _S321 = rough_1 > 0.0f;

#line 1218
        }
        else
        {

#line 1218
            _S321 = false;

#line 1218
        }

#line 1218
        if(_S321)
        {

#line 1218
            float _S322 = dielectricAlbedo_0(_S319, rough_1, wB_0, outside_1, kernelContext_42);
            (&surf_3)->tComp_0 = 1.0f / max(_S322, 0.10000000149011612f);

#line 1218
        }


        if(outside_1)
        {

#line 1221
            _S314 = kernelContext_42->materials_0[mi_1 + 15U];

#line 1221
        }
        else
        {

#line 1221
            _S314 = 0.0f;

#line 1221
        }

#line 1221
        (&surf_3)->coat_0 = _S314;
        uint _S323 = mi_1 + 16U;

#line 1222
        (&surf_3)->coatAlpha_0 = max(kernelContext_42->materials_0[_S323] * kernelContext_42->materials_0[_S323], 0.0010000000474974513f);
        float coatF_0 = fresnelDielectric_0(_S319, 1.5f);
        (&surf_3)->coatP_0 = _S314 * coatF_0;

#line 1224
        float3 _S324;
        if(outside_1)
        {

#line 1225
            _S324 = float3(kernelContext_42->materials_0[mi_1 + 18U], kernelContext_42->materials_0[mi_1 + 19U], kernelContext_42->materials_0[mi_1 + 20U]);

#line 1225
        }
        else
        {

#line 1225
            _S324 = float3(0.0f) ;

#line 1225
        }

#line 1225
        (&surf_3)->sheenColor_0 = _S324;
        float _S325 = max(_S324.x, max(_S324.y, _S324.z));
        float _S326 = max(kernelContext_42->materials_0[mi_1 + 17U], 0.070000000298023224f);
        (&surf_3)->sheenAlpha_0 = _S326 * _S326;

#line 1228
        float _S327;
        if(_S325 > 0.0f)
        {

#line 1229
            float _S328 = sheenAlbedo_0(_S319, _S326, kernelContext_42);

#line 1229
            _S327 = _S325 * _S328;

#line 1229
        }
        else
        {

#line 1229
            _S327 = 0.0f;

#line 1229
        }

#line 1229
        (&surf_3)->sheenP_0 = _S327;

#line 1229
        bool _S329;



        if(nrcCompiled_0)
        {

#line 1233
            _S329 = kernelContext_42->params_0[int(44)] != 0U;

#line 1233
        }
        else
        {

#line 1233
            _S329 = false;

#line 1233
        }

#line 1233
        bool _S330;

#line 1233
        if(_S329)
        {

#line 1233
            _S330 = _S277;

#line 1233
        }
        else
        {

#line 1233
            _S330 = false;

#line 1233
        }

#line 1233
        bool _S331;

#line 1233
        if(_S330)
        {

#line 1233
            _S331 = cls_4 == 0U;

#line 1233
        }
        else
        {

#line 1233
            _S331 = false;

#line 1233
        }

#line 1233
        bool _S332;

#line 1233
        if(_S331)
        {

#line 1233
            _S332 = !st_1->gi_0;

#line 1233
        }
        else
        {

#line 1233
            _S332 = false;

#line 1233
        }

#line 1233
        bool _S333;
        if(_S332)
        {

#line 1234
            _S333 = metallic_1 == 0.0f;

#line 1234
        }
        else
        {

#line 1234
            _S333 = false;

#line 1234
        }

#line 1234
        bool _S334;

#line 1234
        if(_S333)
        {

#line 1234
            _S334 = transmission_2 == 0.0f;

#line 1234
        }
        else
        {

#line 1234
            _S334 = false;

#line 1234
        }

#line 1234
        bool _S335;

#line 1234
        if(_S334)
        {

#line 1234
            _S335 = ((&surf_3)->coat_0) == 0.0f;

#line 1234
        }
        else
        {

#line 1234
            _S335 = false;

#line 1234
        }

#line 1234
        bool nrcCut_0;

#line 1234
        if(_S335)
        {

#line 1234
            nrcCut_0 = ((&surf_3)->sheenP_0) == 0.0f;

#line 1234
        }
        else
        {

#line 1234
            nrcCut_0 = false;

#line 1234
        }

#line 1234
        k_6 = 0U;



        for(;;)
        {

#line 1238
            if(k_6 < _S253)
            {
            }
            else
            {

#line 1238
                break;
            }
            uint o_8 = k_6 * 16U;
            float3 col_0 = float3((as_type<float>((kernelContext_42->lights_0[o_8 + 1U]))), (as_type<float>((kernelContext_42->lights_0[o_8 + 2U]))), (as_type<float>((kernelContext_42->lights_0[o_8 + 3U])))) * float3((as_type<float>((kernelContext_42->lights_0[o_8 + 4U])))) ;
            float3 vec_0 = float3((as_type<float>((kernelContext_42->lights_0[o_8 + 5U]))), (as_type<float>((kernelContext_42->lights_0[o_8 + 6U]))), (as_type<float>((kernelContext_42->lights_0[o_8 + 7U]))));

            bool virt_0 = kernelContext_42->lights_0[o_8] == 3U;
            if(virt_0)
            {

#line 1245
                if(_S252)
                {

#line 1245
                    _S245 = depth_5 == 0U;

#line 1245
                }
                else
                {

#line 1245
                    _S245 = false;

#line 1245
                }

#line 1245
                _S245 = !_S245;

#line 1245
            }
            else
            {

#line 1245
                _S245 = false;

#line 1245
            }

#line 1245
            if(_S245)
            {

#line 1246
                k_6 = k_6 + 1U;

#line 1238
                continue;
            }

#line 1248
            uint _S336 = kernelContext_42->lights_0[o_8 + 14U];

#line 1248
            uint _S337 = recvMask_0(_S257, kernelContext_42);

#line 1248
            if((_S336 & _S337) == 0U)
            {

#line 1249
                k_6 = k_6 + 1U;

#line 1238
                continue;
            }

#line 1253
            if(kernelContext_42->lights_0[o_8] == 1U)
            {

#line 1253
                _S246 = true;

#line 1253
            }
            else
            {

#line 1253
                _S246 = virt_0;

#line 1253
            }

#line 1253
            if(_S246)
            {

#line 1253
                wi_6 = - normalize(vec_0);

#line 1253
                dist_4 = 1.00000001504746622e+30f;

#line 1253
                li_0 = col_0;

#line 1253
            }
            else
            {

#line 1261
                float3 toL_1 = vec_0 - p_11;
                float d2_1 = dot(toL_1, toL_1);
                float dist_5 = sqrt(d2_1);
                float3 wi_7 = toL_1 / float3(dist_5) ;
                float3 li_1 = col_0 / float3(d2_1) ;
                uint _S338 = o_8 + 15U;

#line 1266
                if(kernelContext_42->lights_0[_S338] != 0U)
                {

#line 1266
                    float _S339 = iesFactor_0(kernelContext_42->lights_0[_S338] - 1U, - wi_7, kernelContext_42);

#line 1266
                    wi_6 = li_1 * float3(_S339) ;

#line 1266
                }
                else
                {

#line 1266
                    wi_6 = li_1;

#line 1266
                }

                if(kernelContext_42->lights_0[o_8] == 2U)
                {

                    float att_0 = saturate(dot(float3((as_type<float>((kernelContext_42->lights_0[o_8 + 8U]))), (as_type<float>((kernelContext_42->lights_0[o_8 + 9U]))), (as_type<float>((kernelContext_42->lights_0[o_8 + 10U])))), - wi_7) * (as_type<float>((kernelContext_42->lights_0[o_8 + 11U]))) + (as_type<float>((kernelContext_42->lights_0[o_8 + 12U]))));

#line 1271
                    li_0 = wi_6 * float3((att_0 * att_0)) ;

#line 1268
                }
                else
                {

#line 1268
                    li_0 = wi_6;

#line 1268
                }

#line 1268
                wi_6 = wi_7;

#line 1268
                dist_4 = dist_5;

#line 1253
            }

#line 1275
            float c_10 = dot(n_9, wi_6);
            if(c_10 > 0.0f)
            {

#line 1276
                bool _S340 = occluded_0(p_11, wi_6, dist_4 - 0.0010000000474974513f, kernelContext_42);


                if(_S252)
                {

#line 1279
                    track_0 = depth_5 == 0U;

#line 1279
                }
                else
                {

#line 1279
                    track_0 = false;

#line 1279
                }
                bool _S341 = !_S340;

#line 1280
                if(_S341)
                {

#line 1280
                    chooseEnv_0 = true;

#line 1280
                }
                else
                {

#line 1280
                    chooseEnv_0 = track_0;

#line 1280
                }

#line 1280
                if(chooseEnv_0)
                {
                    float3 _S342 = float3(dot(wi_6, T_2), dot(wi_6, B_2), c_10);

#line 1282
                    thread Surface_0 _S343 = surf_3;

#line 1282
                    Lobes_0 _S344 = evalLobes_0(&_S343, woL_6, _S342, kernelContext_42);
                    float3 cd_1 = thr_2 * _S344.diffuse_0 * li_0;
                    float3 cs_1 = thr_2 * _S344.specular_1 * li_0;
                    if(_S341)
                    {

#line 1285
                        _S247 = !virt_0;

#line 1285
                    }
                    else
                    {

#line 1285
                        _S247 = false;

#line 1285
                    }

#line 1285
                    if(_S247)
                    {

#line 1286
                        Parts_addLight_0(&st_1->parts_0, depth_5, cls_4, thr_2 * (_S344.diffuse_0 + _S344.specular_1) * li_0, cd_1, cs_1);

#line 1285
                    }

                    if(track_0)
                    {
                        if(virt_0)
                        {

#line 1289
                            vv_0 = 0.0f;

#line 1289
                        }
                        else
                        {

#line 1289
                            vv_0 = lum_0(cd_1 + cs_1);

#line 1289
                        }
                        st_1->visTotal_0 = st_1->visTotal_0 + vv_0;
                        if(_S340)
                        {

#line 1291
                            us_0 = 0.0f;

#line 1291
                        }
                        else
                        {

#line 1291
                            us_0 = vv_0;

#line 1291
                        }

#line 1291
                        st_1->visLit_0 = st_1->visLit_0 + us_0;
                        uint _S345 = kernelContext_42->lights_0[o_8 + 13U];

#line 1292
                        float3 _S346 = float3(c_10) ;

#line 1292
                        float3 _S347 = cd_1 / _S346;

#line 1292
                        float3 _S348 = cs_1 / _S346;

#line 1292
                        if(_S340)
                        {

#line 1292
                            _S243 = 0.0f;

#line 1292
                        }
                        else
                        {

#line 1292
                            _S243 = 1.0f;

#line 1292
                        }

#line 1292
                        if(_S340)
                        {

#line 1292
                            _S244 = 0.0f;

#line 1292
                        }
                        else
                        {

#line 1292
                            _S244 = c_10;

#line 1292
                        }

#line 1292
                        addSlot_0(pixel_7, _S345, _S347, _S348, wi_6, _S243, _S244, kernelContext_42);

#line 1287
                    }

#line 1280
                }

#line 1276
            }

#line 1238
            k_6 = k_6 + 1U;

#line 1238
        }

#line 1301
        if(restirCompiled_0)
        {

#line 1301
            _S245 = depth_5 == 0U;

#line 1301
        }
        else
        {

#line 1301
            _S245 = false;

#line 1301
        }

#line 1301
        if(_S245)
        {

#line 1301
            _S246 = kernelContext_42->params_0[int(36)] != 0U;

#line 1301
        }
        else
        {

#line 1301
            _S246 = false;

#line 1301
        }

#line 1301
        bool suits_0;

#line 1301
        bool ok_0;

#line 1301
        bool reDI_0;

#line 1301
        bool refracted_0;

#line 1301
        if(_S246)
        {

#line 1301
            float _S349 = pf_0(3U, kernelContext_42);

            if(_S349 == 0.0f)
            {

#line 1303
                chooseEnv_0 = transmission_2 == 0.0f;

#line 1303
            }
            else
            {

#line 1303
                chooseEnv_0 = false;

#line 1303
            }

#line 1303
            if(chooseEnv_0)
            {

#line 1303
                _S247 = ((&surf_3)->alpha_3) >= 0.15000000596046448f;

#line 1303
            }
            else
            {

#line 1303
                _S247 = false;

#line 1303
            }
            if(_S247)
            {

#line 1304
                if(((&surf_3)->coat_0) == 0.0f)
                {

#line 1304
                    suits_0 = true;

#line 1304
                }
                else
                {

#line 1304
                    suits_0 = ((&surf_3)->coatAlpha_0) >= 0.15000000596046448f;

#line 1304
                }

#line 1304
            }
            else
            {

#line 1304
                suits_0 = false;

#line 1304
            }
            if(suits_0)
            {

#line 1305
                ok_0 = (kernelContext_42->params_0[int(36)] & 1U) != 0U;

#line 1305
            }
            else
            {

#line 1305
                ok_0 = false;

#line 1305
            }

#line 1305
            if(ok_0)
            {

#line 1305
                reDI_0 = emitterCount_0 > 0U;

#line 1305
            }
            else
            {

#line 1305
                reDI_0 = false;

#line 1305
            }

            if(suits_0)
            {

#line 1307
                refracted_0 = (kernelContext_42->params_0[int(36)] & 2U) != 0U;

#line 1307
            }
            else
            {

#line 1307
                refracted_0 = false;

#line 1307
            }

#line 1307
            if(refracted_0)
            {

#line 1307
                track_0 = !_S252;

#line 1307
            }
            else
            {

#line 1307
                track_0 = false;

#line 1307
            }
            st_1->restir_1 = reDI_0;
            st_1->gi_0 = track_0;
            if(suits_0)
            {

#line 1310
                restirGbuffer_0(pixel_7, p_11, n_9, kernelContext_42);


                if(track_0)
                {

#line 1313
                    thread Surface_0 _S350 = surf_3;

#line 1313
                    restirGIPrepare_0(pixel_7, p_11, n_9, _S271, &_S350, T_2, B_2, woL_6, &rng_4, kernelContext_42);

#line 1313
                }

#line 1310
            }
            else
            {

#line 1310
                restirClear_0(pixel_7, kernelContext_42);

#line 1310
            }

#line 1301
        }
        else
        {

#line 1301
            reDI_0 = false;

#line 1301
        }

#line 1319
        if(reDI_0)
        {

#line 1319
            uint _S351 = recvMask_0(_S257, kernelContext_42);

#line 1319
            thread Surface_0 _S352 = surf_3;

#line 1319
            RestirPick_0 _S353 = restirDI_0(pixel_7, _S351, p_11, n_9, _S271, &_S352, T_2, B_2, woL_6, &rng_4, kernelContext_42);


            if(_S353.valid_0)
            {


                uint _S354 = _S353.e_1 - 1U;

#line 1326
                uint _S355 = recvMask_0(_S257, kernelContext_42);

#line 1324
                thread float3 wi_8;

#line 1324
                thread float3 g_4;
                thread float dist_6;

#line 1325
                thread float cosi_5;

#line 1325
                thread float plsa_5;

#line 1325
                bool _S356 = restirLight_0(_S354, _S355, _S353.x_6, p_11, n_9, &wi_8, &dist_6, &cosi_5, &g_4, &plsa_5, kernelContext_42);


                bool _S357 = !_S353.occ_0;

#line 1328
                if(_S357)
                {

#line 1328
                    chooseEnv_0 = true;

#line 1328
                }
                else
                {

#line 1328
                    chooseEnv_0 = _S252;

#line 1328
                }

#line 1328
                if(chooseEnv_0)
                {
                    float3 wiL_6 = float3(dot(wi_8, T_2), dot(wi_8, B_2), cosi_5);

#line 1330
                    thread Surface_0 _S358 = surf_3;

#line 1330
                    float _S359 = restirMis_0(&_S358, woL_6, wiL_6, plsa_5);

#line 1330
                    thread Surface_0 _S360 = surf_3;

#line 1330
                    Lobes_0 _S361 = evalLobes_0(&_S360, woL_6, wiL_6, kernelContext_42);

#line 1330
                    float3 _S362 = float3((_S359 * _S353.W_0)) ;


                    float3 cd_2 = thr_2 * _S361.diffuse_0 * g_4 * _S362;
                    float3 cs_2 = thr_2 * _S361.specular_1 * g_4 * _S362;
                    if(_S357)
                    {

#line 1336
                        Parts_addLight_0(&st_1->parts_0, depth_5, cls_4, cd_2 + cs_2, cd_2, cs_2);

#line 1335
                    }

                    if(_S252)
                    {
                        float vv_1 = lum_0(cd_2 + cs_2);
                        st_1->visTotal_0 = st_1->visTotal_0 + vv_1;
                        if(_S353.occ_0)
                        {

#line 1341
                            dist_4 = 0.0f;

#line 1341
                        }
                        else
                        {

#line 1341
                            dist_4 = vv_1;

#line 1341
                        }

#line 1341
                        st_1->visLit_0 = st_1->visLit_0 + dist_4;
                        float3 _S363 = cd_2 / float3(cosi_5) ;

#line 1342
                        float3 _S364 = cs_2 / float3(cosi_5) ;

#line 1342
                        float3 _S365 = wi_8;

#line 1342
                        if(_S353.occ_0)
                        {

#line 1342
                            vv_0 = 0.0f;

#line 1342
                        }
                        else
                        {

#line 1342
                            vv_0 = 1.0f;

#line 1342
                        }

#line 1342
                        if(_S353.occ_0)
                        {

#line 1342
                            us_0 = 0.0f;

#line 1342
                        }
                        else
                        {

#line 1342
                            us_0 = cosi_5;

#line 1342
                        }

#line 1342
                        addSlot_0(pixel_7, 3U, _S363, _S364, _S365, vv_0, us_0, kernelContext_42);

#line 1337
                    }

#line 1328
                }

#line 1322
            }

#line 1319
        }

#line 1349
        float chooseLight_0 = Rng_next_0(&rng_4);
        if(reDI_0)
        {

#line 1350
            if(hasEnv_0)
            {

#line 1350
                dist_4 = 1.0f;

#line 1350
            }
            else
            {

#line 1350
                dist_4 = 0.0f;

#line 1350
            }

#line 1350
        }
        else
        {

#line 1350
            dist_4 = _S254;

#line 1350
        }
        if(hasEnv_0)
        {

#line 1351
            chooseEnv_0 = chooseLight_0 < dist_4;

#line 1351
        }
        else
        {

#line 1351
            chooseEnv_0 = false;

#line 1351
        }
        if(emitterCount_0 > 0U)
        {

#line 1352
            _S247 = !chooseEnv_0;

#line 1352
        }
        else
        {

#line 1352
            _S247 = false;

#line 1352
        }

#line 1352
        if(_S247)
        {

#line 1352
            suits_0 = !reDI_0;

#line 1352
        }
        else
        {

#line 1352
            suits_0 = false;

#line 1352
        }

#line 1352
        uint lobeCls_0;

#line 1352
        uint cls_5;

#line 1352
        if(suits_0)
        {
            float _S366 = Rng_next_0(&rng_4);
            float ua_1 = Rng_next_0(&rng_4);
            float ub_1 = Rng_next_0(&rng_4);

            uint _S367 = emitterCount_0 - 1U;

#line 1358
            lobeCls_0 = 0U;

#line 1358
            cls_5 = _S367;
            for(;;)
            {

#line 1359
                if(lobeCls_0 < cls_5)
                {
                }
                else
                {

#line 1359
                    break;
                }
                uint mid_3 = (lobeCls_0 + cls_5) / 2U;
                if(kernelContext_42->emitCdf_0[mid_3] >= _S366)
                {

#line 1362
                    cls_5 = mid_3;

#line 1362
                }
                else
                {

#line 1362
                    lobeCls_0 = mid_3 + 1U;

#line 1362
                }

#line 1359
            }

#line 1367
            uint e_3 = lobeCls_0 * 16U;
            float3 a_8 = float3(kernelContext_42->emitters_0[e_3], kernelContext_42->emitters_0[e_3 + 1U], kernelContext_42->emitters_0[e_3 + 2U]);
            float3 b_3 = float3(kernelContext_42->emitters_0[e_3 + 3U], kernelContext_42->emitters_0[e_3 + 4U], kernelContext_42->emitters_0[e_3 + 5U]);
            float3 c_11 = float3(kernelContext_42->emitters_0[e_3 + 6U], kernelContext_42->emitters_0[e_3 + 7U], kernelContext_42->emitters_0[e_3 + 8U]);
            float su_1 = sqrt(ua_1);

            float3 toL_2 = a_8 * float3((1.0f - su_1))  + b_3 * float3((su_1 * (1.0f - ub_1)))  + c_11 * float3((su_1 * ub_1))  - p_11;
            float d2_2 = dot(toL_2, toL_2);
            float dist_7 = sqrt(d2_2);
            float3 wi_9 = toL_2 / float3(dist_7) ;
            float cosl_1 = abs(dot(normalize(cross(b_3 - a_8, c_11 - a_8)), wi_9));
            float cosi_6 = dot(n_9, wi_9);
            if(cosi_6 > 0.0f)
            {

#line 1379
                ok_0 = cosl_1 > 9.9999997473787516e-06f;

#line 1379
            }
            else
            {

#line 1379
                ok_0 = false;

#line 1379
            }

#line 1379
            if(ok_0)
            {

#line 1379
                uint _S368 = (as_type<uint>((kernelContext_42->emitters_0[e_3 + 14U])));

#line 1379
                uint _S369 = recvMask_0(_S257, kernelContext_42);

#line 1379
                refracted_0 = (_S368 & _S369) != 0U;

#line 1379
            }
            else
            {

#line 1379
                refracted_0 = false;

#line 1379
            }

#line 1379
            if(refracted_0)
            {

#line 1379
                bool _S370 = occluded_0(p_11, wi_9, dist_7 * 0.99900001287460327f, kernelContext_42);


                if(_S252)
                {

#line 1382
                    track_0 = depth_5 == 0U;

#line 1382
                }
                else
                {

#line 1382
                    track_0 = false;

#line 1382
                }
                bool _S371 = !_S370;

#line 1383
                bool _S372;

#line 1383
                if(_S371)
                {

#line 1383
                    _S372 = true;

#line 1383
                }
                else
                {

#line 1383
                    _S372 = track_0;

#line 1383
                }

#line 1383
                if(_S372)
                {
                    float pl_2 = (1.0f - _S254) * kernelContext_42->emitters_0[e_3 + 13U] * d2_2 / (kernelContext_42->emitters_0[e_3 + 12U] * cosl_1);
                    float3 wiL_7 = float3(dot(wi_9, T_2), dot(wi_9, B_2), cosi_6);

#line 1386
                    thread Surface_0 _S373 = surf_3;

#line 1386
                    float _S374 = reflectivePdf_0(&_S373, woL_6, wiL_7);

                    if(nrcCut_0)
                    {

#line 1388
                        vv_0 = 1.0f;

#line 1388
                    }
                    else
                    {

#line 1388
                        float _S375 = pl_2 * pl_2;

#line 1388
                        vv_0 = _S375 / (_S375 + _S374 * _S374);

#line 1388
                    }
                    float3 le_2 = float3(kernelContext_42->emitters_0[e_3 + 9U], kernelContext_42->emitters_0[e_3 + 10U], kernelContext_42->emitters_0[e_3 + 11U]);

#line 1389
                    thread Surface_0 _S376 = surf_3;

#line 1389
                    Lobes_0 _S377 = evalLobes_0(&_S376, woL_6, wiL_7, kernelContext_42);

#line 1389
                    float3 _S378 = float3(pl_2) ;

                    float3 cd_3 = thr_2 * _S377.diffuse_0 * le_2 / _S378 * float3(vv_0) ;
                    float3 cs_3 = thr_2 * _S377.specular_1 * le_2 / _S378 * float3(vv_0) ;
                    if(_S371)
                    {

#line 1393
                        thread Surface_0 _S379 = surf_3;

#line 1393
                        float3 _S380 = evalReflective_0(&_S379, woL_6, wiL_7, kernelContext_42);
                        Parts_addLight_0(&st_1->parts_0, depth_5, cls_4, thr_2 * _S380 * le_2 / _S378 * float3(vv_0) , cd_3, cs_3);

#line 1393
                    }

                    if(track_0)
                    {
                        float vv_2 = lum_0(cd_3 + cs_3);
                        st_1->visTotal_0 = st_1->visTotal_0 + vv_2;
                        if(_S370)
                        {

#line 1399
                            us_0 = 0.0f;

#line 1399
                        }
                        else
                        {

#line 1399
                            us_0 = vv_2;

#line 1399
                        }

#line 1399
                        st_1->visLit_0 = st_1->visLit_0 + us_0;

#line 1399
                        float3 _S381 = float3(cosi_6) ;
                        float3 _S382 = cd_3 / _S381;

#line 1400
                        float3 _S383 = cs_3 / _S381;

#line 1400
                        if(_S370)
                        {

#line 1400
                            _S243 = 0.0f;

#line 1400
                        }
                        else
                        {

#line 1400
                            _S243 = 1.0f;

#line 1400
                        }

#line 1400
                        if(_S370)
                        {

#line 1400
                            _S244 = 0.0f;

#line 1400
                        }
                        else
                        {

#line 1400
                            _S244 = cosi_6;

#line 1400
                        }

#line 1400
                        addSlot_0(pixel_7, 3U, _S382, _S383, wi_9, _S243, _S244, kernelContext_42);

#line 1395
                    }

#line 1383
                }

#line 1379
            }

#line 1352
        }

#line 1406
        if(chooseEnv_0)
        {
            float e1_0 = Rng_next_0(&rng_4);
            float e2_0 = Rng_next_0(&rng_4);
            float e3_1 = Rng_next_0(&rng_4);
            float e4_0 = Rng_next_0(&rng_4);
            thread float pdfE_0;
            thread float3 leE_0;

#line 1413
            float3 _S384 = envSample_0(e1_0, e2_0, e3_1, e4_0, &pdfE_0, &leE_0, kernelContext_42);

            float cosi_7 = dot(n_9, _S384);
            if(pdfE_0 > 0.0f)
            {

#line 1416
                ok_0 = cosi_7 > 0.0f;

#line 1416
            }
            else
            {

#line 1416
                ok_0 = false;

#line 1416
            }

#line 1416
            if(ok_0)
            {

#line 1416
                bool _S385 = occluded_0(p_11, _S384, 1.00000001504746622e+30f, kernelContext_42);


                if(_S252)
                {

#line 1419
                    track_0 = depth_5 == 0U;

#line 1419
                }
                else
                {

#line 1419
                    track_0 = false;

#line 1419
                }
                bool _S386 = !_S385;

#line 1420
                if(_S386)
                {

#line 1420
                    refracted_0 = true;

#line 1420
                }
                else
                {

#line 1420
                    refracted_0 = track_0;

#line 1420
                }

#line 1420
                if(refracted_0)
                {
                    float pl_3 = dist_4 * pdfE_0;
                    float3 wiL_8 = float3(dot(_S384, T_2), dot(_S384, B_2), cosi_7);

#line 1423
                    thread Surface_0 _S387 = surf_3;

#line 1423
                    float _S388 = reflectivePdf_0(&_S387, woL_6, wiL_8);

                    if(nrcCut_0)
                    {

#line 1425
                        vv_0 = 1.0f;

#line 1425
                    }
                    else
                    {

#line 1425
                        float _S389 = pl_3 * pl_3;

#line 1425
                        vv_0 = _S389 / (_S389 + _S388 * _S388);

#line 1425
                    }

#line 1425
                    thread Surface_0 _S390 = surf_3;

#line 1425
                    Lobes_0 _S391 = evalLobes_0(&_S390, woL_6, wiL_8, kernelContext_42);

#line 1425
                    float3 _S392 = float3(pl_3) ;

                    float3 cd_4 = thr_2 * _S391.diffuse_0 * leE_0 / _S392 * float3(vv_0) ;
                    float3 cs_4 = thr_2 * _S391.specular_1 * leE_0 / _S392 * float3(vv_0) ;
                    if(_S386)
                    {

#line 1429
                        thread Surface_0 _S393 = surf_3;

#line 1429
                        float3 _S394 = evalReflective_0(&_S393, woL_6, wiL_8, kernelContext_42);
                        Parts_addLight_0(&st_1->parts_0, depth_5, cls_4, thr_2 * _S394 * leE_0 / _S392 * float3(vv_0) , cd_4, cs_4);

#line 1429
                    }

                    if(track_0)
                    {
                        float vv_3 = lum_0(cd_4 + cs_4);
                        st_1->visTotal_0 = st_1->visTotal_0 + vv_3;
                        if(_S385)
                        {

#line 1435
                            us_0 = 0.0f;

#line 1435
                        }
                        else
                        {

#line 1435
                            us_0 = vv_3;

#line 1435
                        }

#line 1435
                        st_1->visLit_0 = st_1->visLit_0 + us_0;
                        if(kernelContext_42->params_0[int(41)] == 0U)
                        {

#line 1436
                            float3 _S395 = float3(cosi_7) ;
                            float3 _S396 = cd_4 / _S395;

#line 1437
                            float3 _S397 = cs_4 / _S395;

#line 1437
                            if(_S385)
                            {

#line 1437
                                _S243 = 0.0f;

#line 1437
                            }
                            else
                            {

#line 1437
                                _S243 = 1.0f;

#line 1437
                            }

#line 1437
                            if(_S385)
                            {

#line 1437
                                _S244 = 0.0f;

#line 1437
                            }
                            else
                            {

#line 1437
                                _S244 = cosi_7;

#line 1437
                            }

#line 1437
                            addSlot_0(pixel_7, 3U, _S396, _S397, _S384, _S243, _S244, kernelContext_42);

#line 1436
                        }

#line 1431
                    }

#line 1420
                }

#line 1416
            }

#line 1406
        }

#line 1443
        if(nrcCut_0)
        {

            float3 _S398 = thr_2 * albedo_2 * float3((1.0f - fSel_1)) ;

#line 1446
            float3 _S399 = nrcQuery_0(p_11, n_9, kernelContext_42);

#line 1446
            Parts_add_0(&st_1->parts_0, depth_5, cls_4, _S398 * _S399);

#line 1446
            alive_0 = false;

#line 1446
            thr_1 = thr_2;

            break;
        }



        float lobe_0 = Rng_next_0(&rng_4);
        float u1_3 = Rng_next_0(&rng_4);
        float u2_3 = Rng_next_0(&rng_4);
        float u3_1 = Rng_next_0(&rng_4);

#line 1462
        if(((&surf_3)->coat_0) > 0.0f)
        {

#line 1462
            float _S400 = Rng_next_0(&rng_4);

#line 1462
            vv_0 = _S400;

#line 1462
        }
        else
        {

#line 1462
            vv_0 = 1.0f;

#line 1462
        }
        if(((&surf_3)->sheenP_0) > 0.0f)
        {

#line 1463
            float _S401 = Rng_next_0(&rng_4);

#line 1463
            us_0 = _S401;

#line 1463
        }
        else
        {

#line 1463
            us_0 = 1.0f;

#line 1463
        }
        if(vv_0 < ((&surf_3)->coatP_0))
        {
            float3 h_9 = sampleVndf_0(woL_6, (&surf_3)->coatAlpha_0, u1_3, u2_3);
            float woh_0 = dot(woL_6, h_9);
            float3 wiL_9 = float3((2.0f * woh_0))  * h_9 - woL_6;
            float _S402 = wiL_9.z;
            float3 _S403 = float3((fresnelDielectric_0(woh_0, 1.5f) / coatF_0 * G1_0(max(_S402, 0.0f), (&surf_3)->coatAlpha_0))) ;

#line 1470
            ok_0 = _S402 > 0.0f;

#line 1470
            lobeCls_0 = 1U;

#line 1470
            refracted_0 = false;

#line 1470
            wi_6 = wiL_9;

#line 1470
            li_0 = _S403;

#line 1464
        }
        else
        {

#line 1472
            if(us_0 < ((&surf_3)->sheenP_0))
            {

                float3 wiL_10 = cosineLocal_0(u1_3, u2_3);

                float _S404 = wiL_10.z;

#line 1477
                float3 _S405 = (&surf_3)->sheenColor_0 * float3(sheenCore_0(_S319, _S404, normalize(woL_6 + wiL_10).z, (&surf_3)->sheenAlpha_0))  * float3(3.1415927410125732f)  / float3((_S404 * (&surf_3)->sheenP_0)) ;

#line 1477
                ok_0 = true;

#line 1477
                lobeCls_0 = 1U;

#line 1477
                refracted_0 = false;

#line 1477
                wi_6 = wiL_10;

#line 1477
                li_0 = _S405;

#line 1472
            }
            else
            {

#line 1479
                if(lobe_0 < metallic_1)
                {
                    float3 h_10 = sampleVndf_0(woL_6, _S318, u1_3, u2_3);
                    float woh_1 = dot(woL_6, h_10);
                    float3 wiL_11 = float3((2.0f * woh_1))  * h_10 - woL_6;
                    float _S406 = wiL_11.z;

#line 1484
                    bool _S407 = _S406 > 0.0f;
                    float3 _S408 = schlick_0(albedo_2, woh_1);

#line 1485
                    thread Surface_0 _S409 = surf_3;

#line 1485
                    float3 _S410 = multiscatterFactor_0(&_S409, _S319, kernelContext_42);

#line 1485
                    float3 _S411 = _S408 * _S410 * float3(G1_0(max(_S406, 0.0f), _S318)) ;

#line 1485
                    ok_0 = _S407;

#line 1485
                    lobeCls_0 = 1U;

#line 1485
                    refracted_0 = false;

#line 1485
                    wi_6 = wiL_11;

#line 1485
                    li_0 = _S411;

#line 1479
                }
                else
                {

#line 1487
                    if(lobe_0 < (metallic_1 + (1.0f - metallic_1) * transmission_2))
                    {
                        float3 h_11 = sampleVndf_0(woL_6, _S318, u1_3, u2_3);
                        float woh_2 = dot(woL_6, h_11);
                        if(u3_1 < (fresnelDielectric_0(woh_2, eta_2)))
                        {
                            float3 wiL_12 = float3((2.0f * woh_2))  * h_11 - woL_6;
                            float _S412 = wiL_12.z;
                            float3 _S413 = float3((G1_0(max(_S412, 0.0f), _S318) * (&surf_3)->tComp_0)) ;

#line 1495
                            ok_0 = _S412 > 0.0f;

#line 1495
                            lobeCls_0 = 1U;

#line 1495
                            refracted_0 = false;

#line 1495
                            wi_6 = wiL_12;

#line 1495
                            li_0 = _S413;

#line 1491
                        }
                        else
                        {

#line 1499
                            float r_7 = 1.0f / eta_2;
                            float k_7 = 1.0f - r_7 * r_7 * (1.0f - woh_2 * woh_2);

#line 1500
                            float3 _S414 = float3(r_7) ;
                            float3 wiL_13 = - woL_6 * _S414 + float3((r_7 * woh_2 - sqrt(max(k_7, 0.0f))))  * h_11;
                            float _S415 = wiL_13.z;

#line 1502
                            if(_S415 < 0.0f)
                            {

#line 1502
                                ok_0 = k_7 > 0.0f;

#line 1502
                            }
                            else
                            {

#line 1502
                                ok_0 = false;

#line 1502
                            }



                            float3 _S416 = albedo_2 * float3(G1_0(max(- _S415, 0.0f), _S318))  * _S414 * _S414 * float3((&surf_3)->tComp_0) ;

#line 1506
                            lobeCls_0 = 2U;

#line 1506
                            refracted_0 = true;

#line 1506
                            wi_6 = wiL_13;

#line 1506
                            li_0 = _S416;

#line 1491
                        }

#line 1487
                    }
                    else
                    {

#line 1509
                        if(u3_1 < fSel_1)
                        {
                            float3 h_12 = sampleVndf_0(woL_6, _S318, u1_3, u2_3);
                            float woh_3 = dot(woL_6, h_12);
                            float3 wiL_14 = float3((2.0f * woh_3))  * h_12 - woL_6;
                            float _S417 = wiL_14.z;
                            float3 _S418 = float3((fresnelDielectric_0(woh_3, wB_0) / fSel_1 * G1_0(max(_S417, 0.0f), _S318))) ;

#line 1515
                            ok_0 = _S417 > 0.0f;

#line 1515
                            lobeCls_0 = 1U;

#line 1515
                            wi_6 = wiL_14;

#line 1515
                            li_0 = _S418;

#line 1509
                        }
                        else
                        {

#line 1519
                            float3 _S419 = cosineLocal_0(u1_3, u2_3);

#line 1519
                            ok_0 = true;

#line 1519
                            lobeCls_0 = 0U;

#line 1519
                            wi_6 = _S419;

#line 1519
                            li_0 = albedo_2;

#line 1509
                        }

#line 1509
                        refracted_0 = false;

#line 1487
                    }

#line 1479
                }

#line 1472
            }

#line 1464
        }

#line 1523
        if(!ok_0)
        {

#line 1523
            alive_0 = false;

#line 1523
            thr_1 = thr_2;
            break;
        }

#line 1525
        if(depth_5 == 0U)
        {

#line 1525
            cls_5 = lobeCls_0;

#line 1525
        }
        else
        {

#line 1525
            cls_5 = cls_4;

#line 1525
        }

        st_1->misPrev_0 = !refracted_0;
        if(refracted_0)
        {

#line 1528
            _S243 = 0.0f;

#line 1528
        }
        else
        {

#line 1528
            thread Surface_0 _S420 = surf_3;

#line 1528
            float _S421 = reflectivePdf_0(&_S420, woL_6, wi_6);

#line 1528
            _S243 = _S421;

#line 1528
        }

#line 1528
        st_1->qPrev_0 = _S243;
        st_1->prevInst_0 = _S257 + 1U;

        float3 dir_2 = normalize(float3(wi_6.x)  * T_2 + float3(wi_6.y)  * B_2 + float3(wi_6.z)  * n_9);

        float side_0 = dot(dir_2, ng_0);
        if(refracted_0)
        {

#line 1534
            track_0 = side_0 >= 0.0f;

#line 1534
        }
        else
        {

#line 1534
            track_0 = side_0 <= 0.0f;

#line 1534
        }

#line 1534
        if(track_0)
        {

#line 1534
            dir_1 = dir_2;

#line 1534
            cls_4 = cls_5;

#line 1534
            alive_0 = false;

#line 1534
            thr_1 = thr_2;
            break;
        }

#line 1536
        if(side_0 > 0.0f)
        {

#line 1536
            _S244 = 9.9999997473787516e-05f;

#line 1536
        }
        else
        {

#line 1536
            _S244 = -9.9999997473787516e-05f;

#line 1536
        }

#line 1536
        float3 _S422 = hit_1 + ng_0 * float3(_S244) ;
        float3 thr_4 = thr_2 * li_0;

        if(depth_5 >= 2U)
        {
            float pr_0 = clamp(max(thr_4.x, max(thr_4.y, thr_4.z)), 0.05000000074505806f, 0.94999998807907104f);
            float _S423 = Rng_next_0(&rng_4);

#line 1542
            if(_S423 > pr_0)
            {

#line 1542
                org_1 = _S422;

#line 1542
                dir_1 = dir_2;

#line 1542
                cls_4 = cls_5;

#line 1542
                alive_0 = false;

#line 1542
                thr_1 = thr_4;
                break;
            }

#line 1543
            thr_1 = thr_4 / float3(pr_0) ;

#line 1539
        }
        else
        {

#line 1539
            thr_1 = thr_4;

#line 1539
        }

#line 1018
        uint _S424 = once_0 + 1U;

#line 1018
        cls_4 = cls_5;

#line 1018
        dir_1 = dir_2;

#line 1018
        org_1 = _S422;

#line 1018
        chan_2 = chan_1;

#line 1018
        once_0 = _S424;

#line 1018
    }

#line 1547
    st_1->rng_0 = (&rng_4)->state_1;
    st_1->org_0 = org_1;
    st_1->dir_0 = dir_1;
    st_1->thr_0 = thr_1;
    st_1->cls_0 = cls_4;
    st_1->chan_0 = chan_1;
    if(depth_5 == 0U)
    {

#line 1553
        _S242 = st_1->gi_0;

#line 1553
    }
    else
    {

#line 1553
        _S242 = false;

#line 1553
    }

#line 1553
    if(_S242)
    {

        uint so_1 = restirScratch_0(pixel_7);

#line 1556
        k_6 = 0U;
        for(;;)
        {

#line 1557
            if(k_6 < 3U)
            {
            }
            else
            {

#line 1557
                break;
            }
            *(kernelContext_42->restir_0+(so_1 + 15U + k_6)) = thr_1[k_6];
            *(kernelContext_42->restir_0+(so_1 + 18U + k_6)) = (&st_1->parts_0)->total_0[k_6];

#line 1557
            k_6 = k_6 + 1U;

#line 1557
        }

#line 1562
        *(kernelContext_42->restir_0+(so_1 + 21U)) = st_1->qPrev_0;

#line 1553
    }

#line 1564
    return alive_0;
}


#line 27 "shaders/include/wf_state.slang"
void putF_0(uint f_3, uint p_12, float v_4, KernelContext_0 thread* kernelContext_43)
{

#line 27
    uint _S425 = pathCount_0(kernelContext_43);

#line 27
    *(kernelContext_43->state_0+(f_3 * _S425 + p_12)) = (as_type<uint>((v_4)));

#line 27
    return;
}


#line 29
void put3_0(uint f_4, uint p_13, float3 v_5, KernelContext_0 thread* kernelContext_44)
{

#line 29
    putF_0(f_4, p_13, v_5.x, kernelContext_44);

#line 29
    putF_0(f_4 + 1U, p_13, v_5.y, kernelContext_44);

#line 29
    putF_0(f_4 + 2U, p_13, v_5.z, kernelContext_44);

#line 29
    return;
}




void storePath_0(const PathState_0 thread* s_14, uint p_14, KernelContext_0 thread* kernelContext_45)
{

#line 35
    uint _S426 = pathCount_0(kernelContext_45);

#line 35
    put3_0(0U, p_14, s_14->org_0, kernelContext_45);

#line 35
    put3_0(3U, p_14, s_14->dir_0, kernelContext_45);

#line 35
    put3_0(6U, p_14, s_14->thr_0, kernelContext_45);

#line 41
    *(kernelContext_45->state_0+(9U * _S426 + p_14)) = s_14->rng_0;
    uint device* _S427 = kernelContext_45->state_0+(10U * _S426 + p_14);

#line 42
    uint _S428 = (s_14->cls_0) | (uint(s_14->chan_0 + int(1)) << 2U);

#line 42
    uint _S429;

#line 42
    if(s_14->misPrev_0)
    {

#line 42
        _S429 = 16U;

#line 42
    }
    else
    {

#line 42
        _S429 = 0U;

#line 42
    }

#line 42
    uint _S430 = _S428 | _S429;

#line 42
    if(s_14->restir_1)
    {

#line 42
        _S429 = 32U;

#line 42
    }
    else
    {

#line 42
        _S429 = 0U;

#line 42
    }

#line 42
    uint _S431 = _S430 | _S429;

#line 42
    if(s_14->gi_0)
    {

#line 42
        _S429 = 64U;

#line 42
    }
    else
    {

#line 42
        _S429 = 0U;

#line 42
    }

#line 42
    *_S427 = (_S431 | _S429) | ((s_14->prevInst_0) << 8U);

#line 42
    putF_0(11U, p_14, s_14->pathLen_0, kernelContext_45);

#line 42
    putF_0(12U, p_14, s_14->qPrev_0, kernelContext_45);

#line 42
    put3_0(13U, p_14, (&s_14->parts_0)->total_0, kernelContext_45);



    if(kernelContext_45->params_0[int(28)] != 0U)
    {

#line 46
        put3_0(16U, p_14, (&s_14->parts_0)->directDiffuse_0, kernelContext_45);

#line 46
        put3_0(19U, p_14, (&s_14->parts_0)->indirectDiffuse_0, kernelContext_45);

#line 46
        put3_0(22U, p_14, (&s_14->parts_0)->specular_0, kernelContext_45);

#line 46
        put3_0(25U, p_14, (&s_14->parts_0)->transmission_0, kernelContext_45);

#line 46
        put3_0(28U, p_14, (&s_14->parts_0)->emission_0, kernelContext_45);

#line 46
        putF_0(31U, p_14, s_14->visLit_0, kernelContext_45);

#line 46
        putF_0(32U, p_14, s_14->visTotal_0, kernelContext_45);

#line 46
    }

#line 56
    return;
}


#line 1588 "shaders/include/pt_core.slang"
float3 giFinish_0(float3 pathTotal_0, uint pixel_8, KernelContext_0 thread* kernelContext_46)
{
    uint co_3 = restirBase_0(pixel_8, kernelContext_46->params_0[int(6)] & 1U);
    uint so_2 = restirScratch_0(pixel_8);
    float wsum_5 = *(kernelContext_46->restir_0+so_2);
    float m_1 = *(kernelContext_46->restir_0+(so_2 + 1U)) + 1.0f;
    float _S432 = *(kernelContext_46->restir_0+(so_2 + 2U));
    float3 _S433 = float3(*(kernelContext_46->restir_0+(so_2 + 3U)), *(kernelContext_46->restir_0+(so_2 + 4U)), *(kernelContext_46->restir_0+(so_2 + 5U)));
    float3 _S434 = float3(*(kernelContext_46->restir_0+(so_2 + 6U)), *(kernelContext_46->restir_0+(so_2 + 7U)), *(kernelContext_46->restir_0+(so_2 + 8U)));
    float3 _S435 = float3(*(kernelContext_46->restir_0+(so_2 + 9U)), *(kernelContext_46->restir_0+(so_2 + 10U)), *(kernelContext_46->restir_0+(so_2 + 11U)));
    float3 _S436 = float3(*(kernelContext_46->restir_0+(so_2 + 12U)), *(kernelContext_46->restir_0+(so_2 + 13U)), *(kernelContext_46->restir_0+(so_2 + 14U)));
    float _S437 = *(kernelContext_46->restir_0+(so_2 + 15U));

#line 1599
    float _S438 = *(kernelContext_46->restir_0+(so_2 + 16U));

#line 1599
    float _S439 = *(kernelContext_46->restir_0+(so_2 + 17U));
    float3 d0_0 = float3(*(kernelContext_46->restir_0+(so_2 + 18U)), *(kernelContext_46->restir_0+(so_2 + 19U)), *(kernelContext_46->restir_0+(so_2 + 20U)));
    float qPrev_1 = *(kernelContext_46->restir_0+(so_2 + 21U));

#line 1601
    bool own_0;
    if((as_type<uint>((*(kernelContext_46->restir_0+(so_2 + 22U))))) != 0U)
    {

#line 1602
        own_0 = qPrev_1 > 0.0f;

#line 1602
    }
    else
    {

#line 1602
        own_0 = false;

#line 1602
    }
    float3 giTotal_0 = pathTotal_0 - d0_0;

#line 1603
    float pSel_2;

#line 1603
    float wsum_6;

#line 1603
    float W_1;

#line 1603
    float3 cSel_2;

#line 1603
    float3 xSel_2;

#line 1603
    float3 nSel_2;

#line 1603
    float3 lSel_2;

#line 1603
    float3 result_0;

    if(own_0)
    {
        float3 cOwn_0 = giTotal_0 * float3(qPrev_1) ;
        float pOwn_0 = lum_0(cOwn_0);
        if(pOwn_0 > 0.0f)
        {
            float wOwn_0 = pOwn_0 / qPrev_1;
            float wsum_7 = wsum_5 + wOwn_0;
            thread Rng_0 r_8;
            (&r_8)->state_1 = pcg_0(pixel_8 ^ (pcg_0(kernelContext_46->params_0[int(6)] * 2246822507U + 4660U + kernelContext_46->params_0[int(43)] * 1759714724U)));
            float _S440 = Rng_next_0(&r_8);

#line 1615
            if((_S440 * wsum_7) < wOwn_0)
            {


                float3 _S441 = float3(*(kernelContext_46->restir_0+(co_3 + 16U)), *(kernelContext_46->restir_0+(co_3 + 17U)), *(kernelContext_46->restir_0+(co_3 + 18U)));
                float3 _S442 = float3(*(kernelContext_46->restir_0+(co_3 + 19U)), *(kernelContext_46->restir_0+(co_3 + 20U)), *(kernelContext_46->restir_0+(co_3 + 21U)));
                if(_S437 > 9.99999997475242708e-07f)
                {

#line 1621
                    pSel_2 = giTotal_0.x / _S437;

#line 1621
                }
                else
                {

#line 1621
                    pSel_2 = 0.0f;

#line 1621
                }

#line 1621
                if(_S438 > 9.99999997475242708e-07f)
                {

#line 1621
                    wsum_6 = giTotal_0.y / _S438;

#line 1621
                }
                else
                {

#line 1621
                    wsum_6 = 0.0f;

#line 1621
                }

#line 1621
                if(_S439 > 9.99999997475242708e-07f)
                {

#line 1621
                    W_1 = giTotal_0.z / _S439;

#line 1621
                }
                else
                {

#line 1621
                    W_1 = 0.0f;

#line 1621
                }

#line 1621
                float3 _S443 = float3(pSel_2, wsum_6, W_1);

#line 1621
                pSel_2 = pOwn_0;

#line 1621
                cSel_2 = cOwn_0;

#line 1621
                xSel_2 = _S441;

#line 1621
                nSel_2 = _S442;

#line 1621
                lSel_2 = _S443;

#line 1615
            }
            else
            {

#line 1615
                pSel_2 = _S432;

#line 1615
                cSel_2 = _S433;

#line 1615
                xSel_2 = _S434;

#line 1615
                nSel_2 = _S435;

#line 1615
                lSel_2 = _S436;

#line 1615
            }

#line 1615
            wsum_6 = wsum_7;

#line 1609
        }
        else
        {

#line 1609
            pSel_2 = _S432;

#line 1609
            cSel_2 = _S433;

#line 1609
            xSel_2 = _S434;

#line 1609
            nSel_2 = _S435;

#line 1609
            lSel_2 = _S436;

#line 1609
            wsum_6 = wsum_5;

#line 1609
        }

#line 1609
        result_0 = d0_0;

#line 1605
    }
    else
    {

#line 1626
        float3 result_1 = d0_0 + giTotal_0;

#line 1626
        pSel_2 = _S432;

#line 1626
        cSel_2 = _S433;

#line 1626
        xSel_2 = _S434;

#line 1626
        nSel_2 = _S435;

#line 1626
        lSel_2 = _S436;

#line 1626
        wsum_6 = wsum_5;

#line 1626
        result_0 = result_1;

#line 1605
    }

#line 1627
    bool _S444 = pSel_2 > 0.0f;

#line 1627
    if(_S444)
    {

#line 1627
        W_1 = wsum_6 / (m_1 * pSel_2);

#line 1627
    }
    else
    {

#line 1627
        W_1 = 0.0f;

#line 1627
    }
    float3 result_2 = result_0 + cSel_2 * float3(W_1) ;

#line 1628
    uint k_8 = 0U;
    for(;;)
    {

#line 1629
        if(k_8 < 3U)
        {
        }
        else
        {

#line 1629
            break;
        }
        *(kernelContext_46->restir_0+(co_3 + 16U + k_8)) = xSel_2[k_8];
        *(kernelContext_46->restir_0+(co_3 + 19U + k_8)) = nSel_2[k_8];
        *(kernelContext_46->restir_0+(co_3 + 22U + k_8)) = lSel_2[k_8];

#line 1629
        k_8 = k_8 + 1U;

#line 1629
    }

#line 1635
    *(kernelContext_46->restir_0+(co_3 + 25U)) = W_1;
    *(kernelContext_46->restir_0+(co_3 + 26U)) = m_1;
    float device* _S445 = kernelContext_46->restir_0+(co_3 + 27U);

#line 1637
    if(_S444)
    {

#line 1637
        k_8 = 1U;

#line 1637
    }
    else
    {

#line 1637
        k_8 = 0U;

#line 1637
    }

#line 1637
    *_S445 = (as_type<float>((k_8)));
    return result_2;
}


void finishPath_0(const PathState_0 thread* st_2, uint pixel_9, KernelContext_0 thread* kernelContext_47)
{

#line 1642
    Parts_0 _S446 = st_2->parts_0;

#line 1642
    float _S447 = st_2->visLit_0;

#line 1642
    float _S448 = st_2->visTotal_0;

#line 1642
    float3 _S449 = (&st_2->parts_0)->total_0;

#line 1642
    float3 radiance_0;

#line 1648
    if(st_2->gi_0)
    {


        if((st_2->chan_0) >= int(0))
        {

#line 1653
            *(kernelContext_47->restir_0+(restirScratch_0(pixel_9) + 22U)) = (as_type<float>((0U)));

#line 1652
        }

#line 1652
        float3 _S450 = giFinish_0(_S449, pixel_9, kernelContext_47);

#line 1652
        radiance_0 = _S450;

#line 1648
    }
    else
    {

#line 1648
        radiance_0 = _S449;

#line 1648
    }

#line 1648
    bool _S451;

#line 1656
    if(any(isnan(radiance_0)))
    {

#line 1656
        _S451 = true;

#line 1656
    }
    else
    {

#line 1656
        _S451 = any(isinf(radiance_0));

#line 1656
    }

#line 1656
    Parts_0 parts_1;

#line 1656
    float visLit_1;

#line 1656
    float visTotal_1;

#line 1656
    if(_S451)
    {
        float3 _S452 = float3(0.0f) ;

#line 1658
        radiance_0 = _S452;

#line 1658
        (&parts_1)->total_0 = _S452;

#line 1658
        (&parts_1)->directDiffuse_0 = _S452;

#line 1658
        (&parts_1)->indirectDiffuse_0 = _S452;

#line 1658
        (&parts_1)->specular_0 = _S452;

#line 1658
        (&parts_1)->transmission_0 = _S452;

#line 1658
        (&parts_1)->emission_0 = _S452;

#line 1658
        visLit_1 = 0.0f;

#line 1658
        visTotal_1 = 0.0f;

#line 1656
    }
    else
    {

#line 1656
        parts_1 = _S446;

#line 1656
        visLit_1 = _S447;

#line 1656
        visTotal_1 = _S448;

#line 1656
    }

#line 1664
    uint o_9 = 3U * pixel_9;
    float device* _S453 = kernelContext_47->accum_0+o_9;

#line 1665
    *_S453 = *_S453 + radiance_0.x;
    uint _S454 = o_9 + 1U;

#line 1666
    float device* _S455 = kernelContext_47->accum_0+_S454;

#line 1666
    *_S455 = *_S455 + radiance_0.y;
    uint _S456 = o_9 + 2U;

#line 1667
    float device* _S457 = kernelContext_47->accum_0+_S456;

#line 1667
    *_S457 = *_S457 + radiance_0.z;
    if(kernelContext_47->params_0[int(32)] != 0U)
    {
        float l_3 = lum_0(radiance_0);
        float device* _S458 = kernelContext_47->pixelStats_0+o_9;

#line 1671
        *_S458 = *_S458 + 1.0f;
        float device* _S459 = kernelContext_47->pixelStats_0+_S454;

#line 1672
        *_S459 = *_S459 + l_3;
        float device* _S460 = kernelContext_47->pixelStats_0+_S456;

#line 1673
        *_S460 = *_S460 + l_3 * l_3;

#line 1668
    }

#line 1676
    if(kernelContext_47->params_0[int(28)] != 0U)
    {
        uint lo_3 = 65U * pixel_9;
        array<float3, int(5)> _S461 = { { parts_1.directDiffuse_0, parts_1.indirectDiffuse_0, parts_1.specular_0, parts_1.transmission_0, parts_1.emission_0 } };

#line 1679
        uint k_9 = 0U;
        for(;;)
        {

#line 1680
            if(k_9 < 5U)
            {
            }
            else
            {

#line 1680
                break;
            }
            uint _S462 = lo_3 + 3U * k_9;

#line 1682
            float device* _S463 = kernelContext_47->lighting_0+_S462;

#line 1682
            *_S463 = *_S463 + _S461[k_9].x;
            float device* _S464 = kernelContext_47->lighting_0+(_S462 + 1U);

#line 1683
            *_S464 = *_S464 + _S461[k_9].y;
            float device* _S465 = kernelContext_47->lighting_0+(_S462 + 2U);

#line 1684
            *_S465 = *_S465 + _S461[k_9].z;

#line 1680
            k_9 = k_9 + 1U;

#line 1680
        }

#line 1686
        float device* _S466 = kernelContext_47->lighting_0+(lo_3 + 15U);

#line 1686
        *_S466 = *_S466 + visLit_1;
        float device* _S467 = kernelContext_47->lighting_0+(lo_3 + 16U);

#line 1687
        *_S467 = *_S467 + visTotal_1;

#line 1676
    }

#line 1689
    return;
}


#line 7 "shaders/wf_shade.slang"
[[kernel]] void wf_shade(uint3 tid_0 [[thread_position_in_grid]], uint device* params_1 [[buffer(6)]], uint device* counts_1 [[buffer(24)]], uint device* queueIn_1 [[buffer(22)]], uint device* state_2 [[buffer(20)]], uint device* hits_1 [[buffer(21)]], float device* restir_2 [[buffer(19)]], float device* envPixels_1 [[buffer(10)]], uint device* instances_1 [[buffer(3)]], uint device* indices_1 [[buffer(2)]], float device* positions_1 [[buffer(1)]], float device* materials_1 [[buffer(4)]], float device* uvs_1 [[buffer(13)]], uint device* texInfo_1 [[buffer(15)]], float device* texels_1 [[buffer(14)]], float device* vnormals_1 [[buffer(16)]], uint device* lights_1 [[buffer(5)]], float device* emitters_1 [[buffer(8)]], metal::raytracing::acceleration_structure<metal::raytracing::instancing> scene_1 [[buffer(0)]], float device* lighting_1 [[buffer(17)]], float device* emitCdf_1 [[buffer(9)]], float device* envMarginal_1 [[buffer(11)]], float device* envCond_1 [[buffer(12)]], uint device* queueOut_1 [[buffer(23)]], float device* accum_1 [[buffer(7)]], float device* pixelStats_1 [[buffer(18)]])
{

#line 7
    thread KernelContext_0 kernelContext_48;

#line 7
    (&kernelContext_48)->params_0 = params_1;

#line 7
    (&kernelContext_48)->counts_0 = counts_1;

#line 7
    (&kernelContext_48)->queueIn_0 = queueIn_1;

#line 7
    (&kernelContext_48)->state_0 = state_2;

#line 7
    (&kernelContext_48)->hits_0 = hits_1;

#line 7
    (&kernelContext_48)->restir_0 = restir_2;

#line 7
    (&kernelContext_48)->envPixels_0 = envPixels_1;

#line 7
    (&kernelContext_48)->instances_0 = instances_1;

#line 7
    (&kernelContext_48)->indices_0 = indices_1;

#line 7
    (&kernelContext_48)->positions_0 = positions_1;

#line 7
    (&kernelContext_48)->materials_0 = materials_1;

#line 7
    (&kernelContext_48)->uvs_0 = uvs_1;

#line 7
    (&kernelContext_48)->texInfo_0 = texInfo_1;

#line 7
    (&kernelContext_48)->texels_0 = texels_1;

#line 7
    (&kernelContext_48)->vnormals_0 = vnormals_1;

#line 7
    (&kernelContext_48)->lights_0 = lights_1;

#line 7
    (&kernelContext_48)->emitters_0 = emitters_1;

#line 7
    (&kernelContext_48)->scene_0 = scene_1;

#line 7
    (&kernelContext_48)->lighting_0 = lighting_1;

#line 7
    (&kernelContext_48)->emitCdf_0 = emitCdf_1;

#line 7
    (&kernelContext_48)->envMarginal_0 = envMarginal_1;

#line 7
    (&kernelContext_48)->envCond_0 = envCond_1;

#line 7
    (&kernelContext_48)->queueOut_0 = queueOut_1;

#line 7
    (&kernelContext_48)->accum_0 = accum_1;

#line 7
    (&kernelContext_48)->pixelStats_0 = pixelStats_1;

    uint d_6 = params_1[int(30)];
    uint i_7 = tid_0.x;
    if(i_7 >= (*(counts_1+d_6)))
    {

#line 12
        return;
    }

#line 12
    uint _S468 = queuedPath_0(i_7, d_6, &kernelContext_48);

#line 12
    PathState_0 _S469 = loadPath_0(_S468, d_6, &kernelContext_48);

    thread PathState_0 st_3 = _S469;
    thread Hit_0 h_13;
    uint _S470 = 4U * _S468;

#line 16
    (&h_13)->hit_0 = (*((&kernelContext_48)->hits_0+_S470)) != 0U;
    (&h_13)->inst_2 = *((&kernelContext_48)->hits_0+(_S470 + 1U));
    (&h_13)->prim_1 = *((&kernelContext_48)->hits_0+(_S470 + 2U));
    (&h_13)->t_4 = (as_type<float>((*((&kernelContext_48)->hits_0+(_S470 + 3U)))));

#line 19
    thread Hit_0 _S471 = h_13;

#line 19
    bool _S472 = shadePath_0(&st_3, &_S471, d_6, _S468, &kernelContext_48);

#line 19
    bool _S473;
    if(_S472)
    {

#line 20
        _S473 = (d_6 + 1U) < ((&kernelContext_48)->params_0)[int(7)];

#line 20
    }
    else
    {

#line 20
        _S473 = false;

#line 20
    }

#line 20
    if(_S473)
    {

#line 20
        thread PathState_0 _S474 = st_3;

#line 20
        storePath_0(&_S474, _S468, &kernelContext_48);



        uint slot_3 = atomic_fetch_add_explicit(((atomic_uint device*)((&kernelContext_48)->counts_0+(d_6 + 1U))), 1U, memory_order_relaxed);
        *((&kernelContext_48)->queueOut_0+slot_3) = _S468;

#line 20
    }
    else
    {

#line 20
        thread PathState_0 _S475 = st_3;

#line 20
        finishPath_0(&_S475, _S468, &kernelContext_48);

#line 20
    }

#line 29
    return;
}

