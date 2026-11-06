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


#line 30 "shaders/include/pt_core.slang"
struct KernelContext_0
{
    uint device* params_0;
    float device* pixelStats_0;
    metal::raytracing::acceleration_structure<metal::raytracing::instancing> scene_0;
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
    float device* lighting_0;
    float device* emitCdf_0;
    float device* envMarginal_0;
    float device* envCond_0;
    float device* accum_0;
};


#line 89
float pf_0(uint i_0, KernelContext_0 thread* kernelContext_0)
{

#line 89
    return (as_type<float>((kernelContext_0->params_0[i_0])));
}


#line 1581
bool pixelActive_0(uint p_0, KernelContext_0 thread* kernelContext_1)
{
    uint _S1 = 3U * p_0;

#line 1583
    float device* _S2 = kernelContext_1->pixelStats_0+_S1;

#line 1583
    float n_0 = *_S2;
    if((*_S2) < float(kernelContext_1->params_0[int(34)]))
    {

#line 1585
        return true;
    }

#line 1586
    float mean_0 = *(kernelContext_1->pixelStats_0+(_S1 + 1U)) / n_0;

    float _S3 = sqrt(max(*(kernelContext_1->pixelStats_0+(_S1 + 2U)) / n_0 - mean_0 * mean_0, 0.0f) * n_0 / (n_0 - 1.0f) / n_0);

#line 1588
    float _S4 = pf_0(33U, kernelContext_1);

#line 1588
    return _S3 > (_S4 * max(mean_0, 0.05000000074505806f));
}


#line 72
uint pcg_0(uint v_0)
{
    uint s_0 = v_0 * 747796405U + 2891336453U;
    uint w_0 = ((s_0 >> ((s_0 >> 28U) + 4U)) ^ s_0) * 277803737U;
    return (w_0 >> 22U) ^ w_0;
}

struct Rng_0
{
    uint state_0;
};


#line 82
float Rng_next_0(Rng_0 thread* this_0)
{
    uint _S5 = pcg_0(this_0->state_0);

#line 84
    this_0->state_0 = _S5;
    return float(_S5 >> 8U) * 5.9604644775390625e-08f;
}


#line 513
struct Parts_0
{
    float3 total_0;
    float3 directDiffuse_0;
    float3 indirectDiffuse_0;
    float3 specular_0;
    float3 transmission_0;
    float3 emission_0;
};


#line 633
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


#line 662
PathState_0 generatePathFor_0(uint px_0, uint py_0, uint sample_0, KernelContext_0 thread* kernelContext_2)
{
    uint w_1 = kernelContext_2->params_0[int(0)];
    uint h_0 = kernelContext_2->params_0[int(1)];

    thread Rng_0 rng_1;
    (&rng_1)->state_0 = pcg_0((py_0 * w_1 + px_0) ^ (pcg_0(sample_0 * 2654435769U + 2135587861U + kernelContext_2->params_0[int(43)] * 1759714724U)));

#line 668
    float _S6 = pf_0(2U, kernelContext_2);

    float _S7 = float(w_1);

#line 670
    float _S8 = float(h_0);

#line 670
    float aspect_0 = _S7 / _S8;
    float _S9 = float(px_0);

#line 671
    float _S10 = Rng_next_0(&rng_1);

#line 671
    float _S11 = 2.0f * (_S9 + _S10) / _S7 - 1.0f;

#line 671
    float _S12 = pf_0(39U, kernelContext_2);

#line 671
    float u_0 = (_S11 + _S12) * aspect_0 * _S6;
    float _S13 = float(py_0);

#line 672
    float _S14 = Rng_next_0(&rng_1);

#line 672
    float _S15 = 1.0f - 2.0f * (_S13 + _S14) / _S8;

#line 672
    float _S16 = pf_0(40U, kernelContext_2);
    float3 _S17 = float3(u_0, (_S15 + _S16) * _S6, -1.0f);

#line 673
    float _S18 = pf_0(4U, kernelContext_2);

#line 673
    float3 focal_0 = _S17 * float3(_S18) ;

#line 673
    float _S19 = pf_0(3U, kernelContext_2);
    float _S20 = Rng_next_0(&rng_1);

#line 674
    float lensR_0 = _S19 * sqrt(_S20);
    float _S21 = Rng_next_0(&rng_1);

#line 675
    float lensA_0 = 6.2831854820251465f * _S21;
    float _S22 = lensR_0 * cos(lensA_0);

#line 676
    float _S23 = lensR_0 * sin(lensA_0);
    float3 _S24 = normalize(focal_0 - float3(_S22, _S23, 0.0f));
    thread PathState_0 s_1;

#line 678
    uint r_0 = 0U;
    for(;;)
    {

#line 679
        if(r_0 < 3U)
        {
        }
        else
        {

#line 679
            break;
        }
        uint _S25 = 4U * r_0;

#line 681
        uint _S26 = 8U + _S25;

#line 681
        uint _S27 = 9U + _S25;

#line 681
        uint _S28 = 10U + _S25;

#line 681
        (&s_1)->org_0[r_0] = (as_type<float>((kernelContext_2->params_0[_S26]))) * _S22 + (as_type<float>((kernelContext_2->params_0[_S27]))) * _S23 + (as_type<float>((kernelContext_2->params_0[_S28]))) * 0.0f + (as_type<float>((kernelContext_2->params_0[11U + _S25])));
        (&s_1)->dir_0[r_0] = (as_type<float>((kernelContext_2->params_0[_S26]))) * _S24.x + (as_type<float>((kernelContext_2->params_0[_S27]))) * _S24.y + (as_type<float>((kernelContext_2->params_0[_S28]))) * _S24.z;

#line 679
        r_0 = r_0 + 1U;

#line 679
    }

#line 684
    (&s_1)->dir_0 = normalize((&s_1)->dir_0);
    (&s_1)->thr_0 = float3(1.0f) ;
    (&s_1)->rng_0 = (&rng_1)->state_0;
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
    float3 _S29 = float3(0.0f) ;

#line 697
    (&(&s_1)->parts_0)->total_0 = _S29;

#line 697
    (&(&s_1)->parts_0)->directDiffuse_0 = _S29;

#line 697
    (&(&s_1)->parts_0)->indirectDiffuse_0 = _S29;

#line 697
    (&(&s_1)->parts_0)->specular_0 = _S29;

#line 697
    (&(&s_1)->parts_0)->transmission_0 = _S29;

#line 697
    (&(&s_1)->parts_0)->emission_0 = _S29;
    return s_1;
}


#line 653
struct Hit_0
{
    bool hit_0;
    uint inst_0;
    uint prim_0;
    float t_0;
};


#line 20995 "hlsl.meta.slang"
struct RayDesc_0
{
    float3 Origin_0;
    float TMin_0;
    float3 Direction_0;
    float TMax_0;
};


#line 701 "shaders/include/pt_core.slang"
Hit_0 traceClosest_0(float3 org_1, float3 dir_1, KernelContext_0 thread* kernelContext_3)
{
    thread RayDesc_0 ray_0;
    (&ray_0)->Origin_0 = org_1;
    (&ray_0)->Direction_0 = dir_1;
    (&ray_0)->TMin_0 = 0.0f;
    (&ray_0)->TMax_0 = 1.00000001504746622e+30f;
    thread raytracing::intersection_query<raytracing::triangle_data, raytracing::instancing> q_0;
    (&q_0)->reset({ (ray_0.Origin_0), (ray_0.Direction_0), (ray_0.TMin_0), (ray_0.TMax_0) }, (kernelContext_3->scene_0), (255U), _slang_ray_flags_to_intersection_params((1U)));
    for(;;)
    {

#line 710
        bool _S30 = ((&q_0)->next());

#line 710
        if(_S30)
        {
        }
        else
        {

#line 710
            break;
        }

#line 710
    }
    thread Hit_0 h_1;
    uint _S31 = (_slang_committed_intersection_type_to_uint((&q_0)->get_committed_intersection_type()));

#line 712
    bool _S32 = _S31 == 1U;

#line 712
    (&h_1)->hit_0 = _S32;

#line 712
    uint _S33;
    if(_S32)
    {

#line 713
        uint _S34 = ((&q_0)->get_committed_instance_id());

#line 713
        _S33 = _S34;

#line 713
    }
    else
    {

#line 713
        _S33 = 0U;

#line 713
    }

#line 713
    (&h_1)->inst_0 = _S33;
    if((&h_1)->hit_0)
    {

#line 714
        uint _S35 = ((&q_0)->get_committed_primitive_id());

#line 714
        _S33 = _S35;

#line 714
    }
    else
    {

#line 714
        _S33 = 0U;

#line 714
    }

#line 714
    (&h_1)->prim_0 = _S33;

#line 714
    float _S36;
    if((&h_1)->hit_0)
    {

#line 715
        float _S37 = ((&q_0)->get_committed_distance());

#line 715
        _S36 = _S37;

#line 715
    }
    else
    {

#line 715
        _S36 = 0.0f;

#line 715
    }

#line 715
    (&h_1)->t_0 = _S36;
    return h_1;
}


#line 54
constant bool fc_restirCompiled_0 [[function_constant(0)]];
constant bool restirCompiled_0 = is_function_constant_defined(fc_restirCompiled_0) ? fc_restirCompiled_0 : true;

#line 729
uint restirBase_0(uint pixel_0, uint which_0)
{

#line 729
    return pixel_0 * 80U + which_0 * 28U;
}


#line 1000
void restirClear_0(uint pixel_1, KernelContext_0 thread* kernelContext_4)
{
    uint co_0 = restirBase_0(pixel_1, kernelContext_4->params_0[int(6)] & 1U);
    float _S38 = (as_type<float>((0U)));

#line 1003
    *(kernelContext_4->restir_0+(co_0 + 14U)) = _S38;
    *(kernelContext_4->restir_0+(co_0 + 27U)) = _S38;
    return;
}


#line 542
void Parts_file_0(Parts_0 thread* this_1, uint depth_0, uint cls_1, float3 c_0)
{
    if(depth_0 == 0U)
    {

#line 545
        this_1->emission_0 = this_1->emission_0 + c_0;

#line 544
    }
    else
    {

#line 546
        if(cls_1 == 0U)
        {

#line 547
            this_1->indirectDiffuse_0 = this_1->indirectDiffuse_0 + c_0;

#line 546
        }
        else
        {

#line 548
            if(cls_1 == 1U)
            {

#line 549
                this_1->specular_0 = this_1->specular_0 + c_0;

#line 548
            }
            else
            {
                this_1->transmission_0 = this_1->transmission_0 + c_0;

#line 548
            }

#line 546
        }

#line 544
    }

#line 552
    return;
}


#line 523
void Parts_add_0(Parts_0 thread* this_2, uint depth_1, uint cls_2, float3 c_1)
{
    this_2->total_0 = this_2->total_0 + c_1;
    Parts_file_0(this_2, depth_1, cls_2, c_1);
    return;
}


#line 265
void envCoords_0(float3 d_0, uint thread* i_1, uint thread* j_0, KernelContext_0 thread* kernelContext_5)
{
    uint w_2 = kernelContext_5->params_0[int(24)];
    uint h_2 = kernelContext_5->params_0[int(25)];

    float v_1 = acos(clamp(d_0.y, -1.0f, 1.0f)) / 3.1415927410125732f;
    *i_1 = min(uint((atan2(d_0.x, - d_0.z) * 0.15915493667125702f + 0.5f) * float(w_2)), w_2 - 1U);
    *j_0 = min(uint(v_1 * float(h_2)), h_2 - 1U);
    return;
}


#line 258
float3 envTexel_0(uint i_2, uint j_1, KernelContext_0 thread* kernelContext_6)
{
    uint o_0 = 3U * (j_1 * kernelContext_6->params_0[int(24)] + i_2);
    return float3(kernelContext_6->envPixels_0[o_0], kernelContext_6->envPixels_0[o_0 + 1U], kernelContext_6->envPixels_0[o_0 + 2U]);
}


#line 198
float lum_0(float3 c_2)
{

#line 198
    return dot(c_2, float3(0.2125999927520752f, 0.71520000696182251f, 0.072200000286102295f));
}


#line 284
float envPdf_0(float3 d_1, KernelContext_0 thread* kernelContext_7)
{
    thread uint i_3;

#line 286
    thread uint j_2;

#line 286
    envCoords_0(d_1, &i_3, &j_2, kernelContext_7);

#line 286
    float3 _S39 = envTexel_0(i_3, j_2, kernelContext_7);

    float _S40 = lum_0(_S39);

#line 288
    float _S41 = pf_0(26U, kernelContext_7);

#line 288
    return _S40 * _S41;
}


#line 275
float3 envRadiance_0(float3 d_2, KernelContext_0 thread* kernelContext_8)
{
    thread uint i_4;

#line 277
    thread uint j_3;

#line 277
    envCoords_0(d_2, &i_4, &j_3, kernelContext_8);

#line 277
    float3 _S42 = envTexel_0(i_4, j_3, kernelContext_8);

    return _S42;
}


#line 105
float3 vertexPos_0(uint v_2, KernelContext_0 thread* kernelContext_9)
{

#line 105
    uint _S43 = 3U * v_2;

#line 105
    return float3(kernelContext_9->positions_0[_S43], kernelContext_9->positions_0[_S43 + 1U], kernelContext_9->positions_0[_S43 + 2U]);
}


#line 107
float3 transformPoint_0(uint base_0, float3 p_1, KernelContext_0 thread* kernelContext_10)
{
    thread float3 r_1;

#line 109
    uint row_0 = 0U;
    for(;;)
    {

#line 110
        if(row_0 < 3U)
        {
        }
        else
        {

#line 110
            break;
        }
        uint o_1 = base_0 + 4U * row_0;
        r_1[row_0] = (as_type<float>((kernelContext_10->instances_0[o_1]))) * p_1.x + (as_type<float>((kernelContext_10->instances_0[o_1 + 1U]))) * p_1.y + (as_type<float>((kernelContext_10->instances_0[o_1 + 2U]))) * p_1.z + (as_type<float>((kernelContext_10->instances_0[o_1 + 3U])));

#line 110
        row_0 = row_0 + 1U;

#line 110
    }

#line 115
    return r_1;
}


#line 326
float3 texelAt_0(uint base_1, uint w_3, uint h_3, int x_1, int y_0, KernelContext_0 thread* kernelContext_11)
{
    int _S44 = int(w_3);

#line 328
    int _S45 = x_1 % _S44;

#line 328
    int _S46 = (_S45 + _S44) % _S44;

#line 328
    uint xi_0 = uint(_S46);
    int _S47 = int(h_3);

#line 329
    int _S48 = y_0 % _S47;

#line 329
    int _S49 = (_S48 + _S47) % _S47;
    uint o_2 = 3U * (base_1 + uint(_S49) * w_3 + xi_0);
    return float3(kernelContext_11->texels_0[o_2], kernelContext_11->texels_0[o_2 + 1U], kernelContext_11->texels_0[o_2 + 2U]);
}

float3 bilinear_0(uint base_2, uint w_4, uint h_4, float2 uv_0, KernelContext_0 thread* kernelContext_12)
{
    float fx_0 = uv_0.x * float(w_4) - 0.5f;
    float fy_0 = uv_0.y * float(h_4) - 0.5f;
    int x0_0 = int(floor(fx_0));
    int y0_0 = int(floor(fy_0));
    float tx_0 = fx_0 - float(x0_0);
    float ty_0 = fy_0 - float(y0_0);

#line 341
    float3 _S50 = texelAt_0(base_2, w_4, h_4, x0_0, y0_0, kernelContext_12);
    int _S51 = x0_0 + int(1);

#line 342
    float3 _S52 = texelAt_0(base_2, w_4, h_4, _S51, y0_0, kernelContext_12);

#line 342
    float3 _S53 = float3(tx_0) ;

#line 342
    float3 a_0 = mix(_S50, _S52, _S53);
    int _S54 = y0_0 + int(1);

#line 343
    float3 _S55 = texelAt_0(base_2, w_4, h_4, x0_0, _S54, kernelContext_12);

#line 343
    float3 _S56 = texelAt_0(base_2, w_4, h_4, _S51, _S54, kernelContext_12);
    return mix(a_0, mix(_S55, _S56, _S53), float3(ty_0) );
}


float3 sampleTexture_0(uint tex_0, float2 uv_1, float footprint_0, KernelContext_0 thread* kernelContext_13)
{
    uint ti_0 = tex_0 * 4U;
    uint base_3 = kernelContext_13->texInfo_0[ti_0];
    uint w_5 = kernelContext_13->texInfo_0[ti_0 + 1U];
    uint h_5 = kernelContext_13->texInfo_0[ti_0 + 2U];
    uint levels_0 = kernelContext_13->texInfo_0[ti_0 + 3U];
    float lod_0 = clamp(log2(max(footprint_0 * float(max(w_5, h_5)), 9.99999993922529029e-09f)), 0.0f, float(levels_0 - 1U));
    uint l0_0 = uint(floor(lod_0));
    float t_1 = lod_0 - float(l0_0);

#line 357
    uint lw_0 = w_5;

#line 357
    uint lh_0 = h_5;

#line 357
    uint k_0 = 0U;

#line 357
    uint off_0 = base_3;



    for(;;)
    {

#line 361
        if(k_0 < l0_0)
        {
        }
        else
        {

#line 361
            break;
        }
        uint off_1 = off_0 + lw_0 * lh_0;
        uint _S57 = max(lw_0 / 2U, 1U);
        uint _S58 = max(lh_0 / 2U, 1U);

#line 361
        uint _S59 = k_0 + 1U;

#line 361
        lw_0 = _S57;

#line 361
        lh_0 = _S58;

#line 361
        k_0 = _S59;

#line 361
        off_0 = off_1;

#line 361
    }

#line 361
    float3 _S60 = bilinear_0(off_0, lw_0, lh_0, uv_1, kernelContext_13);

#line 361
    bool _S61;

#line 368
    if((l0_0 + 1U) >= levels_0)
    {

#line 368
        _S61 = true;

#line 368
    }
    else
    {

#line 368
        _S61 = t_1 <= 0.0f;

#line 368
    }

#line 368
    if(_S61)
    {

#line 369
        return _S60;
    }

#line 369
    float3 _S62 = bilinear_0(off_0 + lw_0 * lh_0, max(lw_0 / 2U, 1U), max(lh_0 / 2U, 1U), uv_1, kernelContext_13);


    return mix(_S60, _S62, float3(t_1) );
}


#line 578
float opacityAt_0(uint instIdx_0, uint prim_1, float2 bary_0, KernelContext_0 thread* kernelContext_14)
{
    uint _S63 = instIdx_0 * 16U;

#line 580
    uint mi_0 = kernelContext_14->instances_0[_S63 + 2U] * 24U;
    float op_0 = kernelContext_14->materials_0[mi_0 + 22U];
    uint tex_1 = uint(kernelContext_14->materials_0[mi_0 + 23U]);

#line 582
    bool _S64;
    if(tex_1 > 0U)
    {

#line 583
        _S64 = op_0 > 0.0f;

#line 583
    }
    else
    {

#line 583
        _S64 = false;

#line 583
    }

#line 583
    float op_1;

#line 583
    if(_S64)
    {
        uint tri_0 = kernelContext_14->instances_0[_S63 + 1U] + 3U * prim_1;
        uint vo_0 = kernelContext_14->instances_0[_S63];
        float2 uv0_0 = float2(kernelContext_14->uvs_0[2U * (kernelContext_14->indices_0[tri_0] + vo_0)], kernelContext_14->uvs_0[2U * (kernelContext_14->indices_0[tri_0] + vo_0) + 1U]);
        uint _S65 = tri_0 + 1U;
        uint _S66 = tri_0 + 2U;

#line 589
        float3 _S67 = sampleTexture_0(tex_1 - 1U, uv0_0 + float2(bary_0.x)  * (float2(kernelContext_14->uvs_0[2U * (kernelContext_14->indices_0[_S65] + vo_0)], kernelContext_14->uvs_0[2U * (kernelContext_14->indices_0[_S65] + vo_0) + 1U]) - uv0_0) + float2(bary_0.y)  * (float2(kernelContext_14->uvs_0[2U * (kernelContext_14->indices_0[_S66] + vo_0)], kernelContext_14->uvs_0[2U * (kernelContext_14->indices_0[_S66] + vo_0) + 1U]) - uv0_0), 0.0f, kernelContext_14);

#line 589
        op_1 = op_0 * _S67.x;

#line 583
    }
    else
    {

#line 583
        op_1 = op_0;

#line 583
    }

#line 592
    return op_1;
}


#line 730
uint restirScratch_0(uint pixel_2)
{

#line 730
    return pixel_2 * 80U + 56U;
}


#line 130
float3 vertexNormal_0(uint v_3, KernelContext_0 thread* kernelContext_15)
{

#line 130
    uint _S68 = 3U * v_3;

#line 130
    return float3(kernelContext_15->vnormals_0[_S68], kernelContext_15->vnormals_0[_S68 + 1U], kernelContext_15->vnormals_0[_S68 + 2U]);
}


#line 120
float3 transformNormal_0(uint base_4, float3 n_1, KernelContext_0 thread* kernelContext_16)
{
    float3 r0_0 = float3((as_type<float>((kernelContext_16->instances_0[base_4]))), (as_type<float>((kernelContext_16->instances_0[base_4 + 1U]))), (as_type<float>((kernelContext_16->instances_0[base_4 + 2U]))));
    float3 r1_0 = float3((as_type<float>((kernelContext_16->instances_0[base_4 + 4U]))), (as_type<float>((kernelContext_16->instances_0[base_4 + 5U]))), (as_type<float>((kernelContext_16->instances_0[base_4 + 6U]))));
    float3 r2_0 = float3((as_type<float>((kernelContext_16->instances_0[base_4 + 8U]))), (as_type<float>((kernelContext_16->instances_0[base_4 + 9U]))), (as_type<float>((kernelContext_16->instances_0[base_4 + 10U]))));
    float3 c0_0 = cross(r1_0, r2_0);

#line 125
    float s_2;
    if((dot(r0_0, c0_0)) < 0.0f)
    {

#line 126
        s_2 = -1.0f;

#line 126
    }
    else
    {

#line 126
        s_2 = 1.0f;

#line 126
    }
    return float3(s_2)  * float3(dot(c0_0, n_1), dot(cross(r2_0, r0_0), n_1), dot(cross(r0_0, r1_0), n_1));
}


#line 212
uint emitMask_0(uint inst_1, KernelContext_0 thread* kernelContext_17)
{

#line 212
    return kernelContext_17->lights_0[kernelContext_17->params_0[int(5)] * 16U + 5888U + 2U * inst_1 + 1U];
}


#line 211
uint recvMask_0(uint inst_2, KernelContext_0 thread* kernelContext_18)
{

#line 211
    return kernelContext_18->lights_0[kernelContext_18->params_0[int(5)] * 16U + 5888U + 2U * inst_2];
}


#line 172
void basis_0(float3 n_2, float3 thread* t_2, float3 thread* b_0)
{

#line 172
    float3 a_1;

    if((abs(n_2.x)) > 0.89999997615814209f)
    {

#line 174
        a_1 = float3(0.0f, 1.0f, 0.0f);

#line 174
    }
    else
    {

#line 174
        a_1 = float3(1.0f, 0.0f, 0.0f);

#line 174
    }
    float3 _S69 = normalize(cross(n_2, a_1));

#line 175
    *b_0 = _S69;
    *t_2 = cross(_S69, n_2);
    return;
}


#line 161
float fresnelDielectric_0(float cosi_0, float eta_0)
{
    float s2_0 = (1.0f - cosi_0 * cosi_0) / (eta_0 * eta_0);
    if(s2_0 >= 1.0f)
    {

#line 165
        return 1.0f;
    }

#line 166
    float cost_0 = sqrt(1.0f - s2_0);
    float _S70 = eta_0 * cost_0;

#line 167
    float rs_0 = (cosi_0 - _S70) / (cosi_0 + _S70);
    float _S71 = eta_0 * cosi_0;

#line 168
    float rp_0 = (_S71 - cost_0) / (_S71 + cost_0);
    return 0.5f * (rs_0 * rs_0 + rp_0 * rp_0);
}


#line 209
float albedoAt_0(uint i_5, KernelContext_0 thread* kernelContext_19)
{

#line 209
    return (as_type<float>((kernelContext_19->lights_0[kernelContext_19->params_0[int(5)] * 16U + i_5])));
}


#line 427
float dielectricAlbedo_0(float cosO_0, float rough_0, float ior_0, bool outside_0, KernelContext_0 thread* kernelContext_20)
{
    float x_2 = saturate(cosO_0) * 15.0f;
    float y_1 = saturate(rough_0) * 15.0f;
    float z_0 = clamp((ior_0 - 1.0f) * 4.0f, 0.0f, 7.999000072479248f);
    uint _S72 = min(uint(x_2), 14U);
    uint _S73 = min(uint(y_1), 14U);
    uint z0_0 = uint(z_0);
    float _S74 = x_2 - float(_S72);
    float _S75 = y_1 - float(_S73);
    float fz_0 = z_0 - float(z0_0);

#line 437
    uint k_1;
    if(outside_0)
    {

#line 438
        k_1 = 0U;

#line 438
    }
    else
    {

#line 438
        k_1 = 9U;

#line 438
    }

#line 438
    uint _S76 = k_1 * 16U * 16U;
    thread array<float, int(2)> c_3;

#line 439
    k_1 = 0U;
    for(;;)
    {

#line 440
        if(k_1 < 2U)
        {
        }
        else
        {

#line 440
            break;
        }

        uint _S77 = 1280U + (_S76 + ((z0_0 + k_1) * 16U + _S73) * 16U + _S72);

#line 443
        float _S78 = albedoAt_0(_S77, kernelContext_20);

#line 443
        float _S79 = albedoAt_0(_S77 + 1U, kernelContext_20);

#line 443
        float a_2 = mix(_S78, _S79, _S74);
        uint _S80 = _S77 + 16U;

#line 444
        float _S81 = albedoAt_0(_S80, kernelContext_20);

#line 444
        float _S82 = albedoAt_0(_S80 + 1U, kernelContext_20);
        c_3[k_1] = mix(a_2, mix(_S81, _S82, _S74), _S75);

#line 440
        k_1 = k_1 + 1U;

#line 440
    }

#line 447
    return mix(c_3[int(0)], c_3[int(1)], fz_0);
}


float sheenAlbedo_0(float cosO_1, float r_2, KernelContext_0 thread* kernelContext_21)
{
    float x_3 = saturate(cosO_1) * 15.0f;
    float y_2 = saturate(r_2) * 15.0f;
    uint _S83 = min(uint(x_3), 14U);
    uint _S84 = min(uint(y_2), 14U);
    float fx_1 = x_3 - float(_S83);
    float fy_1 = y_2 - float(_S84);
    uint _S85 = 1024U + _S84 * 16U + _S83;

#line 459
    float _S86 = albedoAt_0(_S85, kernelContext_21);

#line 459
    float _S87 = albedoAt_0(_S85 + 1U, kernelContext_21);

#line 459
    float a_3 = mix(_S86, _S87, fx_1);
    uint _S88 = 1024U + (_S84 + 1U) * 16U + _S83;

#line 460
    float _S89 = albedoAt_0(_S88, kernelContext_21);

#line 460
    float _S90 = albedoAt_0(_S88 + 1U, kernelContext_21);
    return mix(a_3, mix(_S89, _S90, fx_1), fy_1);
}


#line 56
constant bool fc_nrcCompiled_0 [[function_constant(1)]];
constant bool nrcCompiled_0 = is_function_constant_defined(fc_nrcCompiled_0) ? fc_nrcCompiled_0 : true;

#line 97
bool nrcFallback_0(uint pixel_3, KernelContext_0 thread* kernelContext_22)
{
    uint w_6 = kernelContext_22->params_0[int(0)];
    uint _S91 = pixel_3 / w_6;

#line 100
    uint _S92 = _S91 * 32U / kernelContext_22->params_0[int(1)];

#line 100
    uint _S93 = _S92 * 32U;

#line 100
    uint _S94 = pixel_3 % w_6;

#line 100
    uint _S95 = _S94 * 32U / w_6;

#line 100
    uint tile_0 = _S93 + _S95;
    return ((kernelContext_22->params_0[49U + tile_0 / 32U] >> (tile_0 % 32U)) & 1U) != 0U;
}


#line 216
float iesFactor_0(uint po_0, float3 d_3, KernelContext_0 thread* kernelContext_23)
{



    float th_0 = degrees_0(acos(clamp(- dot(d_3, float3((as_type<float>((kernelContext_23->lights_0[po_0 + 6U]))), (as_type<float>((kernelContext_23->lights_0[po_0 + 7U]))), (as_type<float>((kernelContext_23->lights_0[po_0 + 8U]))))), -1.0f, 1.0f)));
    float ph_0 = degrees_0(atan2(dot(d_3, float3((as_type<float>((kernelContext_23->lights_0[po_0 + 3U]))), (as_type<float>((kernelContext_23->lights_0[po_0 + 4U]))), (as_type<float>((kernelContext_23->lights_0[po_0 + 5U]))))), dot(d_3, float3((as_type<float>((kernelContext_23->lights_0[po_0]))), (as_type<float>((kernelContext_23->lights_0[po_0 + 1U]))), (as_type<float>((kernelContext_23->lights_0[po_0 + 2U])))))));

#line 222
    float ph_1;
    if(ph_0 < 0.0f)
    {

#line 223
        ph_1 = ph_0 + 360.0f;

#line 223
    }
    else
    {

#line 223
        ph_1 = ph_0;

#line 223
    }

    uint _S96 = min(uint(th_0), 179U);
    uint _S97 = min(uint(ph_1), 359U);
    float ft_0 = th_0 - float(_S96);

    uint t_3 = po_0 + 9U;
    uint _S98 = t_3 + _S97 * 181U + _S96;
    uint _S99 = t_3 + (_S97 + 1U) * 181U + _S96;
    return mix(mix((as_type<float>((kernelContext_23->lights_0[_S98]))), (as_type<float>((kernelContext_23->lights_0[_S98 + 1U]))), ft_0), mix((as_type<float>((kernelContext_23->lights_0[_S99]))), (as_type<float>((kernelContext_23->lights_0[_S99 + 1U]))), ft_0), ph_1 - float(_S97));
}


#line 597
bool occluded_0(float3 o_3, float3 d_4, float tmax_0, KernelContext_0 thread* kernelContext_24)
{

#line 597
    uint layer_0 = 0U;

#line 597
    float3 _S100 = o_3;

#line 597
    float _S101 = tmax_0;

    for(;;)
    {

#line 599
        if(layer_0 < 8U)
        {
        }
        else
        {

#line 599
            break;
        }
        thread RayDesc_0 ray_1;
        (&ray_1)->Origin_0 = _S100;
        (&ray_1)->Direction_0 = d_4;
        (&ray_1)->TMin_0 = 0.0f;
        (&ray_1)->TMax_0 = _S101;
        thread raytracing::intersection_query<raytracing::triangle_data, raytracing::instancing> q_1;
        (&q_1)->reset({ (ray_1.Origin_0), (ray_1.Direction_0), (ray_1.TMin_0), (ray_1.TMax_0) }, (kernelContext_24->scene_0), (255U), _slang_ray_flags_to_intersection_params((5U)));
        for(;;)
        {

#line 608
            bool _S102 = ((&q_1)->next());

#line 608
            if(_S102)
            {
            }
            else
            {

#line 608
                break;
            }

#line 608
        }
        uint _S103 = (_slang_committed_intersection_type_to_uint((&q_1)->get_committed_intersection_type()));

#line 609
        if(_S103 != 1U)
        {

#line 610
            return false;
        }

#line 611
        uint _S104 = ((&q_1)->get_committed_instance_id());

#line 611
        uint _S105 = ((&q_1)->get_committed_primitive_id());

#line 611
        float2 _S106 = ((&q_1)->get_committed_triangle_barycentric_coord());

#line 611
        float _S107 = opacityAt_0(_S104, _S105, _S106, kernelContext_24);
        if(_S107 >= 1.0f)
        {

#line 613
            return true;
        }
        uint h_6 = (((((((as_type<uint>((_S100.x))) * 73856093U) ^ ((as_type<uint>((_S100.y))) * 19349663U)) ^ ((as_type<uint>((_S100.z))) * 83492791U)) ^ ((as_type<uint>((d_4.x))) * 2654435761U)) ^ ((as_type<uint>((d_4.y))) * 40503U)) ^ ((as_type<uint>((d_4.z))) * 2246822519U)) ^ (layer_0 * 3266489917U);

        uint h_7 = (h_6 ^ (h_6 >> 16U)) * 2146121005U;

        uint h_8 = (h_7 ^ (h_7 >> 15U)) * 2221713035U;

        if((float((h_8 ^ (h_8 >> 16U)) >> 8U) * 5.9604644775390625e-08f) < _S107)
        {

#line 622
            return true;
        }

#line 623
        float _S108 = ((&q_1)->get_committed_distance());

#line 623
        float adv_0 = _S108 + 9.9999997473787516e-05f;
        float3 _S109 = _S100 + d_4 * float3(adv_0) ;
        float _S110 = _S101 - adv_0;
        if(_S110 <= 0.0f)
        {

#line 627
            return false;
        }

#line 599
        layer_0 = layer_0 + 1U;

#line 599
        _S100 = _S109;

#line 599
        _S101 = _S110;

#line 599
    }

#line 629
    return true;
}


#line 146
float D_0(float hz_0, float alpha_0)
{
    float a2_0 = alpha_0 * alpha_0;
    float d_5 = hz_0 * hz_0 * (a2_0 - 1.0f) + 1.0f;
    return a2_0 / (3.1415927410125732f * d_5 * d_5);
}


#line 139
float G1_0(float cosT_0, float alpha_1)
{
    float c2_0 = cosT_0 * cosT_0;

    return 2.0f / (1.0f + sqrt(1.0f + alpha_1 * alpha_1 * ((1.0f - c2_0) / max(c2_0, 9.99999993922529029e-09f))));
}


#line 153
float3 schlick_0(float3 f0_0, float c_4)
{
    float m_0 = 1.0f - saturate(c_4);
    float m2_0 = m_0 * m_0;
    return f0_0 + (float3(1.0f)  - f0_0) * float3((m2_0 * m2_0 * m_0)) ;
}


#line 401
float ggxAlbedo_0(float cosO_2, float alpha_2, KernelContext_0 thread* kernelContext_25)
{
    float x_4 = saturate(cosO_2) * 31.0f;
    float y_3 = saturate(sqrt(alpha_2)) * 31.0f;
    uint _S111 = min(uint(x_4), 30U);
    uint _S112 = min(uint(y_3), 30U);
    float fx_2 = x_4 - float(_S111);
    float fy_2 = y_3 - float(_S112);
    uint _S113 = _S112 * 32U + _S111;

#line 409
    float _S114 = albedoAt_0(_S113, kernelContext_25);

#line 409
    float _S115 = albedoAt_0(_S113 + 1U, kernelContext_25);

#line 409
    float a_4 = mix(_S114, _S115, fx_2);
    uint _S116 = (_S112 + 1U) * 32U + _S111;

#line 410
    float _S117 = albedoAt_0(_S116, kernelContext_25);

#line 410
    float _S118 = albedoAt_0(_S116 + 1U, kernelContext_25);
    return mix(a_4, mix(_S117, _S118, fx_2), fy_2);
}


#line 375
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


#line 418
float3 multiscatterFactor_0(const Surface_0 thread* s_3, float cosO_3, KernelContext_0 thread* kernelContext_26)
{
    if(kernelContext_26->params_0[int(29)] == 0U)
    {

#line 421
        return float3(1.0f) ;
    }

#line 421
    float3 _S119 = s_3->albedo_0;

#line 421
    float _S120 = ggxAlbedo_0(cosO_3, s_3->alpha_3, kernelContext_26);
    return float3(1.0f)  + _S119 * float3((1.0f / max(_S120, 0.05000000074505806f) - 1.0f)) ;
}


#line 466
float sheenCore_0(float woz_0, float wiz_0, float hz_1, float alpha_4)
{



    return (2.0f + 1.0f / alpha_4) * pow(sqrt(max(1.0f - hz_1 * hz_1, 0.0f)), 1.0f / alpha_4) / 6.2831854820251465f * (1.0f / (4.0f * (wiz_0 + woz_0 - wiz_0 * woz_0))) * wiz_0;
}


#line 393
struct Lobes_0
{
    float3 diffuse_0;
    float3 specular_1;
};


#line 476
Lobes_0 evalLobes_0(const Surface_0 thread* s_4, float3 woL_0, float3 wiL_0, KernelContext_0 thread* kernelContext_27)
{
    float3 hh_0 = normalize(woL_0 + wiL_0);
    float _S121 = max(dot(woL_0, hh_0), 0.0f);

    float _S122 = hh_0.z;

#line 481
    float _S123 = woL_0.z;

#line 481
    float _S124 = wiL_0.z;

#line 481
    float _S125 = 4.0f * _S123;

#line 481
    float core_0 = D_0(_S122, s_4->alpha_3) * G1_0(_S123, s_4->alpha_3) * G1_0(_S124, s_4->alpha_3) / _S125;

#line 481
    float _S126 = s_4->transmission_1;

    thread Lobes_0 l_0;

#line 483
    float _S127 = s_4->metallic_0;

#line 483
    float3 _S128 = s_4->albedo_0;
    float3 _S129 = float3(s_4->metallic_0)  * schlick_0(s_4->albedo_0, _S121);

#line 484
    float3 _S130 = multiscatterFactor_0(s_4, _S123, kernelContext_27);
    float _S131 = 1.0f - _S127;

#line 485
    float _S132 = 1.0f - _S126;

#line 484
    (&l_0)->specular_1 = _S129 * _S130 * float3(core_0)  + float3((_S131 * (_S126 * fresnelDielectric_0(_S121, s_4->eta_1) * s_4->tComp_0 + _S132 * fresnelDielectric_0(_S121, s_4->ior_1)) * core_0)) ;

    (&l_0)->diffuse_0 = float3((_S131 * _S132 * (1.0f - s_4->fSel_0)))  * _S128 * float3((_S124 / 3.1415927410125732f)) ;

#line 486
    float _S133 = s_4->sheenP_0;

    if((s_4->sheenP_0) > 0.0f)
    {

#line 488
        float3 _S134 = float3((1.0f - _S133)) ;

        (&l_0)->specular_1 = _S134 * (&l_0)->specular_1 + s_4->sheenColor_0 * float3(sheenCore_0(_S123, _S124, _S122, s_4->sheenAlpha_0)) ;
        (&l_0)->diffuse_0 = (&l_0)->diffuse_0 * _S134;

#line 488
    }

#line 488
    float _S135 = s_4->coat_0;

#line 493
    if((s_4->coat_0) > 0.0f)
    {

#line 493
        float3 _S136 = float3((1.0f - s_4->coatP_0)) ;

#line 499
        (&l_0)->specular_1 = _S136 * (&l_0)->specular_1 + float3((_S135 * fresnelDielectric_0(_S121, 1.5f) * (D_0(_S122, s_4->coatAlpha_0) * G1_0(_S123, s_4->coatAlpha_0) * G1_0(_S124, s_4->coatAlpha_0) / _S125))) ;
        (&l_0)->diffuse_0 = (&l_0)->diffuse_0 * _S136;

#line 493
    }

#line 502
    return l_0;
}


#line 530
void Parts_addLight_0(Parts_0 thread* this_3, uint depth_2, uint cls_3, float3 c_5, float3 cd_0, float3 cs_0)
{
    this_3->total_0 = this_3->total_0 + c_5;
    if(depth_2 == 0U)
    {
        this_3->directDiffuse_0 = this_3->directDiffuse_0 + cd_0;
        this_3->specular_0 = this_3->specular_0 + cs_0;

#line 533
    }
    else
    {



        Parts_file_0(this_3, depth_2, cls_3, cd_0 + cs_0);

#line 533
    }

#line 540
    return;
}


#line 237
void addSlot_0(uint pixel_4, uint slot_0, float3 u_1, float3 s_5, float3 wi_0, float lit_0, float r_3, KernelContext_0 thread* kernelContext_28)
{

#line 237
    bool _S137;

    if(any(isnan(u_1)))
    {

#line 239
        _S137 = true;

#line 239
    }
    else
    {

#line 239
        _S137 = any(isinf(u_1));

#line 239
    }

#line 239
    if(_S137)
    {

#line 239
        _S137 = true;

#line 239
    }
    else
    {

#line 239
        _S137 = any(isnan(s_5));

#line 239
    }

#line 239
    if(_S137)
    {

#line 239
        _S137 = true;

#line 239
    }
    else
    {

#line 239
        _S137 = any(isinf(s_5));

#line 239
    }

#line 239
    if(_S137)
    {

#line 240
        return;
    }

#line 241
    uint o_4 = 65U * pixel_4 + 17U + 12U * slot_0;
    float w_7 = lum_0(u_1);
    float wd_0 = w_7 + lum_0(s_5);
    float device* _S138 = kernelContext_28->lighting_0+o_4;

#line 244
    *_S138 = *_S138 + u_1.x;
    float device* _S139 = kernelContext_28->lighting_0+(o_4 + 1U);

#line 245
    *_S139 = *_S139 + u_1.y;
    float device* _S140 = kernelContext_28->lighting_0+(o_4 + 2U);

#line 246
    *_S140 = *_S140 + u_1.z;
    float device* _S141 = kernelContext_28->lighting_0+(o_4 + 3U);

#line 247
    *_S141 = *_S141 + w_7;
    float device* _S142 = kernelContext_28->lighting_0+(o_4 + 4U);

#line 248
    *_S142 = *_S142 + w_7 * r_3;
    float device* _S143 = kernelContext_28->lighting_0+(o_4 + 5U);

#line 249
    *_S143 = *_S143 + s_5.x;
    float device* _S144 = kernelContext_28->lighting_0+(o_4 + 6U);

#line 250
    *_S144 = *_S144 + s_5.y;
    float device* _S145 = kernelContext_28->lighting_0+(o_4 + 7U);

#line 251
    *_S145 = *_S145 + s_5.z;
    float device* _S146 = kernelContext_28->lighting_0+(o_4 + 8U);

#line 252
    *_S146 = *_S146 + wd_0 * wi_0.x;
    float device* _S147 = kernelContext_28->lighting_0+(o_4 + 9U);

#line 253
    *_S147 = *_S147 + wd_0 * wi_0.y;
    float device* _S148 = kernelContext_28->lighting_0+(o_4 + 10U);

#line 254
    *_S148 = *_S148 + wd_0 * wi_0.z;
    float device* _S149 = kernelContext_28->lighting_0+(o_4 + 11U);

#line 255
    *_S149 = *_S149 + wd_0 * lit_0;
    return;
}


#line 902
void restirGbuffer_0(uint pixel_5, float3 p_2, float3 n_3, KernelContext_0 thread* kernelContext_29)
{
    uint co_1 = restirBase_0(pixel_5, kernelContext_29->params_0[int(6)] & 1U);
    *(kernelContext_29->restir_0+(co_1 + 8U)) = p_2.x;
    *(kernelContext_29->restir_0+(co_1 + 9U)) = p_2.y;
    *(kernelContext_29->restir_0+(co_1 + 10U)) = p_2.z;
    *(kernelContext_29->restir_0+(co_1 + 11U)) = n_3.x;
    *(kernelContext_29->restir_0+(co_1 + 12U)) = n_3.y;
    *(kernelContext_29->restir_0+(co_1 + 13U)) = n_3.z;
    *(kernelContext_29->restir_0+(co_1 + 14U)) = (as_type<float>((1U)));
    return;
}


#line 505
float3 evalReflective_0(const Surface_0 thread* s_6, float3 woL_1, float3 wiL_1, KernelContext_0 thread* kernelContext_30)
{

#line 505
    Lobes_0 _S150 = evalLobes_0(s_6, woL_1, wiL_1, kernelContext_30);


    return _S150.specular_1 + _S150.diffuse_0;
}


#line 918
void restirGIPrepare_0(uint pixel_6, float3 p_3, float3 n_4, float pHitT_0, const Surface_0 thread* surf_0, float3 T_0, float3 B_0, float3 woL_2, Rng_0 thread* rng_2, KernelContext_0 thread* kernelContext_31)
{
    uint w_8 = kernelContext_31->params_0[int(0)];
    uint _S151 = kernelContext_31->params_0[int(6)] & 1U;
    float _S152 = float(max(kernelContext_31->params_0[int(38)], 1U));



    float3 _S153 = float3(0.0f) ;

#line 926
    float pSel_0;

#line 926
    float mTotal_0;

#line 926
    float wsum_0;

#line 926
    float3 cSel_0;

#line 926
    float3 xSel_0;

#line 926
    float3 nSel_0;

#line 926
    float3 lSel_0;

#line 926
    uint k_2;



    if(kernelContext_31->params_0[int(6)] > 0U)
    {
        uint _S154 = pixel_6 % w_8;

#line 932
        int nx_0 = int(_S154);
        uint _S155 = pixel_6 / w_8;

#line 933
        int ny_0 = int(_S155);

#line 933
        pSel_0 = 0.0f;

#line 933
        cSel_0 = _S153;

#line 933
        xSel_0 = _S153;

#line 933
        nSel_0 = _S153;

#line 933
        lSel_0 = _S153;

#line 933
        k_2 = 0U;

#line 933
        mTotal_0 = 0.0f;

#line 933
        wsum_0 = 0.0f;
        for(;;)
        {

#line 934
            if(k_2 < 3U)
            {
            }
            else
            {

#line 934
                break;
            }

#line 934
            bool _S156;

#line 934
            bool _S157;

#line 934
            bool _S158;

#line 934
            int ny_1;

#line 934
            int nx_1;



            if(k_2 > 0U)
            {
                float _S159 = Rng_next_0(rng_2);

#line 940
                int nx_2 = nx_0 + (int(_S159 * 13.0f) - int(6));
                float _S160 = Rng_next_0(rng_2);

#line 941
                int ny_2 = ny_0 + (int(_S160 * 13.0f) - int(6));
                if(nx_2 < int(0))
                {

#line 942
                    _S156 = true;

#line 942
                }
                else
                {

#line 942
                    _S156 = ny_2 < int(0);

#line 942
                }

#line 942
                if(_S156)
                {

#line 942
                    _S157 = true;

#line 942
                }
                else
                {

#line 942
                    _S157 = nx_2 >= int(w_8);

#line 942
                }

#line 942
                if(_S157)
                {

#line 942
                    _S158 = true;

#line 942
                }
                else
                {

#line 942
                    _S158 = ny_2 >= int(kernelContext_31->params_0[int(1)]);

#line 942
                }

#line 942
                if(_S158)
                {

#line 943
                    k_2 = k_2 + 1U;

#line 934
                    continue;
                }

#line 934
                ny_1 = ny_2;

#line 934
                nx_1 = nx_2;



            }
            else
            {

#line 938
                ny_1 = ny_0;

#line 938
                nx_1 = nx_0;

#line 938
            }

#line 945
            uint ro_0 = restirBase_0(uint(ny_1) * w_8 + uint(nx_1), _S151 ^ 1U);
            if((as_type<uint>((*(kernelContext_31->restir_0+(ro_0 + 14U))))) == 0U)
            {

#line 946
                _S156 = true;

#line 946
            }
            else
            {

#line 946
                _S156 = (as_type<uint>((*(kernelContext_31->restir_0+(ro_0 + 27U))))) == 0U;

#line 946
            }

#line 946
            if(_S156)
            {

#line 947
                k_2 = k_2 + 1U;

#line 934
                continue;
            }

#line 948
            float3 pq_0 = float3(*(kernelContext_31->restir_0+(ro_0 + 8U)), *(kernelContext_31->restir_0+(ro_0 + 9U)), *(kernelContext_31->restir_0+(ro_0 + 10U)));

            if((dot(float3(*(kernelContext_31->restir_0+(ro_0 + 11U)), *(kernelContext_31->restir_0+(ro_0 + 12U)), *(kernelContext_31->restir_0+(ro_0 + 13U))), n_4)) < 0.89999997615814209f)
            {

#line 950
                _S157 = true;

#line 950
            }
            else
            {

#line 950
                _S157 = (length(pq_0 - p_3)) > (0.05000000074505806f * max(pHitT_0, 0.0099999997764825821f));

#line 950
            }

#line 950
            if(_S157)
            {

#line 951
                k_2 = k_2 + 1U;

#line 934
                continue;
            }

#line 952
            float3 x2_0 = float3(*(kernelContext_31->restir_0+(ro_0 + 16U)), *(kernelContext_31->restir_0+(ro_0 + 17U)), *(kernelContext_31->restir_0+(ro_0 + 18U)));
            float3 n2_0 = float3(*(kernelContext_31->restir_0+(ro_0 + 19U)), *(kernelContext_31->restir_0+(ro_0 + 20U)), *(kernelContext_31->restir_0+(ro_0 + 21U)));
            float3 l2_0 = float3(*(kernelContext_31->restir_0+(ro_0 + 22U)), *(kernelContext_31->restir_0+(ro_0 + 23U)), *(kernelContext_31->restir_0+(ro_0 + 24U)));
            float _S161 = min(*(kernelContext_31->restir_0+(ro_0 + 26U)), _S152);
            float mTotal_1 = mTotal_0 + _S161;
            float3 toX_0 = x2_0 - p_3;
            float dR_0 = length(toX_0);
            float3 wi_1 = toX_0 / float3(max(dR_0, 9.99999997475242708e-07f)) ;
            float dQ_0 = length(x2_0 - pq_0);
            float cosT_1 = dot(n_4, wi_1);
            float cosR_0 = abs(dot(n2_0, wi_1));
            float cosQ_0 = abs(dot(n2_0, normalize(pq_0 - x2_0)));
            if(cosT_1 <= 0.0f)
            {

#line 964
                _S158 = true;

#line 964
            }
            else
            {

#line 964
                _S158 = dR_0 < 0.0010000000474974513f;

#line 964
            }

#line 964
            bool _S162;

#line 964
            if(_S158)
            {

#line 964
                _S162 = true;

#line 964
            }
            else
            {

#line 964
                _S162 = cosR_0 < 0.0010000000474974513f;

#line 964
            }

#line 964
            bool _S163;

#line 964
            if(_S162)
            {

#line 964
                _S163 = true;

#line 964
            }
            else
            {

#line 964
                _S163 = cosQ_0 < 0.0010000000474974513f;

#line 964
            }

#line 964
            if(_S163)
            {

#line 964
                mTotal_0 = mTotal_1;
                k_2 = k_2 + 1U;

#line 934
                continue;
            }

#line 966
            float jac_0 = cosR_0 / cosQ_0 * (dQ_0 * dQ_0) / (dR_0 * dR_0);

#line 966
            bool _S164;
            if(jac_0 > 10.0f)
            {

#line 967
                _S164 = true;

#line 967
            }
            else
            {

#line 967
                _S164 = jac_0 < 0.10000000149011612f;

#line 967
            }

#line 967
            if(_S164)
            {

#line 967
                mTotal_0 = mTotal_1;
                k_2 = k_2 + 1U;

#line 934
                continue;
            }

#line 934
            float3 _S165 = evalReflective_0(surf_0, woL_2, float3(dot(wi_1, T_0), dot(wi_1, B_0), cosT_1), kernelContext_31);

#line 969
            float3 c_6 = _S165 * l2_0;
            float phat_0 = lum_0(c_6);

#line 970
            bool _S166;
            if(phat_0 <= 0.0f)
            {

#line 971
                _S166 = true;

#line 971
            }
            else
            {

#line 971
                bool _S167 = occluded_0(p_3, wi_1, dR_0 * 0.99900001287460327f, kernelContext_31);

#line 971
                _S166 = _S167;

#line 971
            }

#line 971
            if(_S166)
            {

#line 971
                mTotal_0 = mTotal_1;
                k_2 = k_2 + 1U;

#line 934
                continue;
            }

#line 973
            float wgt_0 = phat_0 * *(kernelContext_31->restir_0+(ro_0 + 25U)) * _S161 * jac_0;
            float wsum_1 = wsum_0 + wgt_0;
            float _S168 = Rng_next_0(rng_2);

#line 975
            float pSel_1;

#line 975
            float3 cSel_1;

#line 975
            float3 xSel_1;

#line 975
            float3 nSel_1;

#line 975
            float3 lSel_1;

#line 975
            if((_S168 * wsum_1) < wgt_0)
            {

#line 975
                pSel_1 = phat_0;

#line 975
                cSel_1 = c_6;

#line 975
                xSel_1 = x2_0;

#line 975
                nSel_1 = n2_0;

#line 975
                lSel_1 = l2_0;

#line 975
            }
            else
            {

#line 975
                pSel_1 = pSel_0;

#line 975
                cSel_1 = cSel_0;

#line 975
                xSel_1 = xSel_0;

#line 975
                nSel_1 = nSel_0;

#line 975
                lSel_1 = lSel_0;

#line 975
            }

#line 975
            pSel_0 = pSel_1;

#line 975
            cSel_0 = cSel_1;

#line 975
            xSel_0 = xSel_1;

#line 975
            nSel_0 = nSel_1;

#line 975
            lSel_0 = lSel_1;

#line 975
            mTotal_0 = mTotal_1;

#line 975
            wsum_0 = wsum_1;

#line 934
            k_2 = k_2 + 1U;

#line 934
        }

#line 930
    }
    else
    {

#line 930
        pSel_0 = 0.0f;

#line 930
        cSel_0 = _S153;

#line 930
        xSel_0 = _S153;

#line 930
        nSel_0 = _S153;

#line 930
        lSel_0 = _S153;

#line 930
        wsum_0 = 0.0f;

#line 930
        mTotal_0 = 0.0f;

#line 930
    }

#line 985
    uint so_0 = restirScratch_0(pixel_6);
    *(kernelContext_31->restir_0+so_0) = wsum_0;
    *(kernelContext_31->restir_0+(so_0 + 1U)) = mTotal_0;
    *(kernelContext_31->restir_0+(so_0 + 2U)) = pSel_0;

#line 988
    k_2 = 0U;
    for(;;)
    {

#line 989
        if(k_2 < 3U)
        {
        }
        else
        {

#line 989
            break;
        }
        *(kernelContext_31->restir_0+(so_0 + 3U + k_2)) = cSel_0[k_2];
        *(kernelContext_31->restir_0+(so_0 + 6U + k_2)) = xSel_0[k_2];
        *(kernelContext_31->restir_0+(so_0 + 9U + k_2)) = nSel_0[k_2];
        *(kernelContext_31->restir_0+(so_0 + 12U + k_2)) = lSel_0[k_2];

#line 989
        k_2 = k_2 + 1U;

#line 989
    }

#line 996
    *(kernelContext_31->restir_0+(so_0 + 22U)) = (as_type<float>((0U)));
    return;
}


#line 735
bool restirLight_0(uint e_0, uint recv_0, float3 x_5, float3 p_4, float3 n_5, float3 thread* wi_2, float thread* dist_0, float thread* cosi_1, float3 thread* g_0, float thread* plsa_0, KernelContext_0 thread* kernelContext_32)
{
    uint o_5 = e_0 * 16U;
    float3 a_5 = float3(kernelContext_32->emitters_0[o_5], kernelContext_32->emitters_0[o_5 + 1U], kernelContext_32->emitters_0[o_5 + 2U]);
    float3 b_1 = float3(kernelContext_32->emitters_0[o_5 + 3U], kernelContext_32->emitters_0[o_5 + 4U], kernelContext_32->emitters_0[o_5 + 5U]);
    float3 c_7 = float3(kernelContext_32->emitters_0[o_5 + 6U], kernelContext_32->emitters_0[o_5 + 7U], kernelContext_32->emitters_0[o_5 + 8U]);
    float3 toL_0 = x_5 - p_4;
    float d2_0 = dot(toL_0, toL_0);
    float _S169 = sqrt(d2_0);

#line 743
    *dist_0 = _S169;
    float3 _S170 = toL_0 / float3(max(_S169, 9.99999997475242708e-07f)) ;

#line 744
    *wi_2 = _S170;
    float cosl_0 = abs(dot(normalize(cross(b_1 - a_5, c_7 - a_5)), _S170));
    *cosi_1 = dot(n_5, _S170);
    *g_0 = float3(kernelContext_32->emitters_0[o_5 + 9U], kernelContext_32->emitters_0[o_5 + 10U], kernelContext_32->emitters_0[o_5 + 11U]) * float3((cosl_0 / max(d2_0, 9.999999960041972e-13f))) ;


    *plsa_0 = kernelContext_32->emitters_0[o_5 + 13U] * d2_0 / (max(kernelContext_32->emitters_0[o_5 + 12U], 1.00000000317107685e-30f) * max(cosl_0, 9.9999997473787516e-06f));

#line 750
    bool _S171;

    if((*cosi_1) > 0.0f)
    {

#line 752
        _S171 = cosl_0 > 9.9999997473787516e-06f;

#line 752
    }
    else
    {

#line 752
        _S171 = false;

#line 752
    }

#line 752
    if(_S171)
    {

#line 752
        _S171 = d2_0 > 9.999999960041972e-13f;

#line 752
    }
    else
    {

#line 752
        _S171 = false;

#line 752
    }

#line 752
    if(_S171)
    {

#line 752
        _S171 = ((as_type<uint>((kernelContext_32->emitters_0[o_5 + 14U]))) & recv_0) != 0U;

#line 752
    }
    else
    {

#line 752
        _S171 = false;

#line 752
    }

#line 752
    return _S171;
}


#line 557
float reflectivePdf_0(const Surface_0 thread* s_7, float3 woL_3, float3 wiL_2)
{
    float3 hh_1 = normalize(woL_3 + wiL_2);

    float _S172 = woL_3.z;

#line 561
    float _S173 = hh_1.z;

#line 561
    float _S174 = 4.0f * _S172;

    float _S175 = 1.0f - s_7->metallic_0;

#line 563
    float _S176 = 1.0f - s_7->transmission_1;
    float _S177 = wiL_2.z;
    float q_2 = (s_7->metallic_0 + _S175 * (s_7->transmission_1 * fresnelDielectric_0(max(dot(woL_3, hh_1), 0.0f), s_7->eta_1) + _S176 * s_7->fSel_0)) * (G1_0(_S172, s_7->alpha_3) * D_0(_S173, s_7->alpha_3) / _S174) + _S175 * _S176 * (1.0f - s_7->fSel_0) * _S177 / 3.1415927410125732f;

#line 565
    float _S178 = s_7->sheenP_0;

#line 565
    float q_3;
    if((s_7->sheenP_0) > 0.0f)
    {

#line 566
        q_3 = (1.0f - _S178) * q_2 + _S178 * _S177 / 3.1415927410125732f;

#line 566
    }
    else
    {

#line 566
        q_3 = q_2;

#line 566
    }

    if((s_7->coat_0) > 0.0f)
    {

#line 568
        q_3 = (1.0f - s_7->coatP_0) * q_3 + s_7->coatP_0 * (G1_0(_S172, s_7->coatAlpha_0) * D_0(_S173, s_7->coatAlpha_0) / _S174);

#line 568
    }

#line 573
    return q_3;
}


#line 756
float restirMis_0(const Surface_0 thread* surf_1, float3 woL_4, float3 wiL_3, float plsa_1)
{

#line 756
    float _S179 = reflectivePdf_0(surf_1, woL_4, wiL_3);


    float _S180 = plsa_1 * plsa_1;

#line 759
    return _S180 / max(_S180 + _S179 * _S179, 1.00000000317107685e-30f);
}

struct RestirPick_0
{
    bool valid_0;
    uint e_1;
    float3 x_6;
    float W_0;
    bool occ_0;
};


#line 776
RestirPick_0 restirDI_0(uint pixel_7, uint recv_1, float3 p_5, float3 n_6, float pHitT_1, const Surface_0 thread* surf_2, float3 T_1, float3 B_1, float3 woL_5, Rng_0 thread* rng_3, KernelContext_0 thread* kernelContext_33)
{

#line 776
    uint lo_0;

#line 776
    float q_4;

#line 776
    float phat_1;

#line 776
    float selPhat_0;

#line 776
    float3 selX_0;

#line 776
    bool _S181;

    uint w_9 = kernelContext_33->params_0[int(0)];
    uint cur_0 = kernelContext_33->params_0[int(6)] & 1U;
    uint _S182 = kernelContext_33->params_0[int(23)];
    float _S183 = float(max(kernelContext_33->params_0[int(38)], 1U));



    float3 _S184 = float3(0.0f) ;

#line 785
    uint selE_0 = 0U;

#line 785
    float selPhat_1 = 0.0f;

#line 785
    float3 selX_1 = _S184;

#line 785
    uint k_3 = 0U;

#line 785
    float mTotal_2 = 0.0f;

#line 785
    float wsum_2 = 0.0f;

    for(;;)
    {

#line 787
        if(k_3 < (max(kernelContext_33->params_0[int(37)], 1U)))
        {
        }
        else
        {

#line 787
            break;
        }
        float _S185 = Rng_next_0(rng_3);
        float ua_0 = Rng_next_0(rng_3);
        float ub_0 = Rng_next_0(rng_3);

        uint _S186 = _S182 - 1U;

#line 793
        lo_0 = 0U;

#line 793
        uint hi_0 = _S186;
        for(;;)
        {

#line 794
            if(lo_0 < hi_0)
            {
            }
            else
            {

#line 794
                break;
            }
            uint mid_0 = (lo_0 + hi_0) / 2U;
            if(kernelContext_33->emitCdf_0[mid_0] >= _S185)
            {

#line 797
                hi_0 = mid_0;

#line 797
            }
            else
            {

#line 797
                lo_0 = mid_0 + 1U;

#line 797
            }

#line 794
        }

#line 802
        uint o_6 = lo_0 * 16U;



        float su_0 = sqrt(ua_0);
        float3 x_7 = float3(kernelContext_33->emitters_0[o_6], kernelContext_33->emitters_0[o_6 + 1U], kernelContext_33->emitters_0[o_6 + 2U]) * float3((1.0f - su_0))  + float3(kernelContext_33->emitters_0[o_6 + 3U], kernelContext_33->emitters_0[o_6 + 4U], kernelContext_33->emitters_0[o_6 + 5U]) * float3((su_0 * (1.0f - ub_0)))  + float3(kernelContext_33->emitters_0[o_6 + 6U], kernelContext_33->emitters_0[o_6 + 7U], kernelContext_33->emitters_0[o_6 + 8U]) * float3((su_0 * ub_0)) ;
        float area_0 = kernelContext_33->emitters_0[o_6 + 12U];
        if(area_0 > 0.0f)
        {

#line 809
            q_4 = kernelContext_33->emitters_0[o_6 + 13U] / area_0;

#line 809
        }
        else
        {

#line 809
            q_4 = 0.0f;

#line 809
        }
        thread float3 wi_3;

#line 810
        thread float3 g_1;
        thread float dist_1;

#line 811
        thread float cosi_2;

#line 811
        thread float plsa_2;

        if(q_4 > 0.0f)
        {

#line 813
            bool _S187 = restirLight_0(lo_0, recv_1, x_7, p_5, n_6, &wi_3, &dist_1, &cosi_2, &g_1, &plsa_2, kernelContext_33);

#line 813
            _S181 = _S187;

#line 813
        }
        else
        {

#line 813
            _S181 = false;

#line 813
        }

#line 813
        if(_S181)
        {
            float3 wiL_4 = float3(dot(wi_3, T_1), dot(wi_3, B_1), cosi_2);

#line 815
            float3 _S188 = evalReflective_0(surf_2, woL_5, wiL_4, kernelContext_33);
            float _S189 = lum_0(_S188 * g_1);

#line 816
            float _S190 = restirMis_0(surf_2, woL_5, wiL_4, plsa_2);

#line 816
            phat_1 = _S189 * _S190;

#line 813
        }
        else
        {

#line 813
            phat_1 = 0.0f;

#line 813
        }

#line 818
        float wgt_1 = phat_1 / max(q_4, 1.00000000317107685e-30f);
        float mTotal_3 = mTotal_2 + 1.0f;
        if(phat_1 > 0.0f)
        {
            float wsum_3 = wsum_2 + wgt_1;
            float _S191 = Rng_next_0(rng_3);

#line 823
            uint selE_1;

#line 823
            if((_S191 * wsum_3) < wgt_1)
            {

#line 823
                selE_1 = lo_0 + 1U;

#line 823
                selPhat_0 = phat_1;

#line 823
                selX_0 = x_7;

#line 823
            }
            else
            {

#line 823
                selE_1 = selE_0;

#line 823
                selPhat_0 = selPhat_1;

#line 823
                selX_0 = selX_1;

#line 823
            }

#line 823
            selE_0 = selE_1;

#line 823
            selPhat_1 = selPhat_0;

#line 823
            selX_1 = selX_0;

#line 823
            wsum_2 = wsum_3;

#line 820
        }

#line 787
        k_3 = k_3 + 1U;

#line 787
        mTotal_2 = mTotal_3;

#line 787
    }

#line 831
    if(kernelContext_33->params_0[int(6)] > 0U)
    {
        uint _S192 = pixel_7 % w_9;

#line 833
        int nx_3 = int(_S192);
        uint _S193 = pixel_7 / w_9;

#line 834
        int ny_3 = int(_S193);

#line 834
        k_3 = 0U;
        for(;;)
        {

#line 835
            if(k_3 < 3U)
            {
            }
            else
            {

#line 835
                break;
            }

#line 835
            bool _S194;

#line 835
            int ny_4;

#line 835
            int nx_4;



            if(k_3 > 0U)
            {
                float _S195 = Rng_next_0(rng_3);

#line 841
                int nx_5 = nx_3 + (int(_S195 * 13.0f) - int(6));
                float _S196 = Rng_next_0(rng_3);

#line 842
                int ny_5 = ny_3 + (int(_S196 * 13.0f) - int(6));
                if(nx_5 < int(0))
                {

#line 843
                    _S181 = true;

#line 843
                }
                else
                {

#line 843
                    _S181 = ny_5 < int(0);

#line 843
                }

#line 843
                if(_S181)
                {

#line 843
                    _S194 = true;

#line 843
                }
                else
                {

#line 843
                    _S194 = nx_5 >= int(w_9);

#line 843
                }

#line 843
                bool _S197;

#line 843
                if(_S194)
                {

#line 843
                    _S197 = true;

#line 843
                }
                else
                {

#line 843
                    _S197 = ny_5 >= int(kernelContext_33->params_0[int(1)]);

#line 843
                }

#line 843
                if(_S197)
                {

#line 844
                    k_3 = k_3 + 1U;

#line 835
                    continue;
                }

#line 835
                ny_4 = ny_5;

#line 835
                nx_4 = nx_5;



            }
            else
            {

#line 839
                ny_4 = ny_3;

#line 839
                nx_4 = nx_3;

#line 839
            }

#line 846
            uint ro_1 = restirBase_0(uint(ny_4) * w_9 + uint(nx_4), cur_0 ^ 1U);
            uint ei_0 = (as_type<uint>((*(kernelContext_33->restir_0+ro_1))));
            if((as_type<uint>((*(kernelContext_33->restir_0+(ro_1 + 14U))))) == 0U)
            {

#line 848
                _S181 = true;

#line 848
            }
            else
            {

#line 848
                _S181 = ei_0 == 0U;

#line 848
            }

#line 848
            if(_S181)
            {

#line 849
                k_3 = k_3 + 1U;

#line 835
                continue;
            }

#line 851
            float3 pp_0 = float3(*(kernelContext_33->restir_0+(ro_1 + 8U)), *(kernelContext_33->restir_0+(ro_1 + 9U)), *(kernelContext_33->restir_0+(ro_1 + 10U)));
            if((dot(float3(*(kernelContext_33->restir_0+(ro_1 + 11U)), *(kernelContext_33->restir_0+(ro_1 + 12U)), *(kernelContext_33->restir_0+(ro_1 + 13U))), n_6)) < 0.89999997615814209f)
            {

#line 852
                _S194 = true;

#line 852
            }
            else
            {

#line 852
                _S194 = (length(pp_0 - p_5)) > (0.05000000074505806f * max(pHitT_1, 0.0099999997764825821f));

#line 852
            }

#line 852
            if(_S194)
            {

#line 853
                k_3 = k_3 + 1U;

#line 835
                continue;
            }

#line 854
            float3 xc_0 = float3(*(kernelContext_33->restir_0+(ro_1 + 1U)), *(kernelContext_33->restir_0+(ro_1 + 2U)), *(kernelContext_33->restir_0+(ro_1 + 3U)));
            float _S198 = min(*(kernelContext_33->restir_0+(ro_1 + 5U)), _S183);
            thread float3 wi_4;

#line 856
            thread float3 g_2;
            thread float dist_2;

#line 857
            thread float cosi_3;

#line 857
            thread float plsa_3;

#line 857
            bool _S199 = restirLight_0(ei_0 - 1U, recv_1, xc_0, p_5, n_6, &wi_4, &dist_2, &cosi_3, &g_2, &plsa_3, kernelContext_33);

            if(_S199)
            {
                float3 wiL_5 = float3(dot(wi_4, T_1), dot(wi_4, B_1), cosi_3);

#line 861
                float3 _S200 = evalReflective_0(surf_2, woL_5, wiL_5, kernelContext_33);
                float _S201 = lum_0(_S200 * g_2);

#line 862
                float _S202 = restirMis_0(surf_2, woL_5, wiL_5, plsa_3);

#line 862
                q_4 = _S201 * _S202;

#line 859
            }
            else
            {

#line 859
                q_4 = 0.0f;

#line 859
            }

#line 864
            float wgt_2 = q_4 * *(kernelContext_33->restir_0+(ro_1 + 4U)) * _S198;
            float mTotal_4 = mTotal_2 + _S198;
            if(wgt_2 > 0.0f)
            {
                float wsum_4 = wsum_2 + wgt_2;
                float _S203 = Rng_next_0(rng_3);

#line 869
                if((_S203 * wsum_4) < wgt_2)
                {

#line 869
                    lo_0 = ei_0;

#line 869
                    phat_1 = q_4;

#line 869
                    selX_0 = xc_0;

#line 869
                }
                else
                {

#line 869
                    lo_0 = selE_0;

#line 869
                    phat_1 = selPhat_1;

#line 869
                    selX_0 = selX_1;

#line 869
                }

#line 869
                selPhat_0 = wsum_4;

#line 866
            }
            else
            {

#line 866
                lo_0 = selE_0;

#line 866
                phat_1 = selPhat_1;

#line 866
                selX_0 = selX_1;

#line 866
                selPhat_0 = wsum_2;

#line 866
            }

#line 866
            selE_0 = lo_0;

#line 866
            selPhat_1 = phat_1;

#line 866
            selX_1 = selX_0;

#line 866
            mTotal_2 = mTotal_4;

#line 866
            wsum_2 = selPhat_0;

#line 835
            k_3 = k_3 + 1U;

#line 835
        }

#line 831
    }

#line 878
    thread RestirPick_0 r_4;
    if(selE_0 != 0U)
    {

#line 879
        _S181 = selPhat_1 > 0.0f;

#line 879
    }
    else
    {

#line 879
        _S181 = false;

#line 879
    }

#line 879
    (&r_4)->valid_0 = _S181;
    (&r_4)->e_1 = selE_0;
    (&r_4)->x_6 = selX_1;
    if(_S181)
    {

#line 882
        selPhat_1 = wsum_2 / (mTotal_2 * selPhat_1);

#line 882
    }
    else
    {

#line 882
        selPhat_1 = 0.0f;

#line 882
    }

#line 882
    (&r_4)->W_0 = selPhat_1;
    (&r_4)->occ_0 = false;
    if((&r_4)->valid_0)
    {
        thread float3 wi_5;

#line 886
        thread float3 g_3;
        thread float dist_3;

#line 887
        thread float cosi_4;

#line 887
        thread float plsa_4;

#line 887
        bool _S204 = restirLight_0(selE_0 - 1U, recv_1, selX_1, p_5, n_6, &wi_5, &dist_3, &cosi_4, &g_3, &plsa_4, kernelContext_33);

#line 887
        bool _S205 = occluded_0(p_5, wi_5, dist_3 * 0.99900001287460327f, kernelContext_33);

        (&r_4)->occ_0 = _S205;

#line 884
    }

#line 891
    uint co_2 = restirBase_0(pixel_7, cur_0);
    *(kernelContext_33->restir_0+co_2) = (as_type<float>((selE_0)));
    *(kernelContext_33->restir_0+(co_2 + 1U)) = selX_1.x;
    *(kernelContext_33->restir_0+(co_2 + 2U)) = selX_1.y;
    *(kernelContext_33->restir_0+(co_2 + 3U)) = selX_1.z;
    float device* _S206 = kernelContext_33->restir_0+(co_2 + 4U);

#line 896
    if((&r_4)->occ_0)
    {

#line 896
        selPhat_1 = 0.0f;

#line 896
    }
    else
    {

#line 896
        selPhat_1 = (&r_4)->W_0;

#line 896
    }

#line 896
    *_S206 = selPhat_1;
    *(kernelContext_33->restir_0+(co_2 + 5U)) = mTotal_2;
    return r_4;
}


#line 291
float3 envSample_0(float u1_0, float u2_0, float u3_0, float u4_0, float thread* pdf_0, float3 thread* le_0, KernelContext_0 thread* kernelContext_34)
{

#line 291
    uint lo_1;

    uint w_10 = kernelContext_34->params_0[int(24)];
    uint h_9 = kernelContext_34->params_0[int(25)];

    uint _S207 = h_9 - 1U;

#line 296
    uint lo_2 = 0U;

#line 296
    uint hi_1 = _S207;
    for(;;)
    {

#line 297
        if(lo_2 < hi_1)
        {
        }
        else
        {

#line 297
            break;
        }
        uint mid_1 = (lo_2 + hi_1) / 2U;
        if(kernelContext_34->envMarginal_0[mid_1] >= u1_0)
        {

#line 300
            lo_1 = lo_2;

#line 300
            hi_1 = mid_1;

#line 300
        }
        else
        {

#line 300
            lo_1 = mid_1 + 1U;

#line 300
        }

#line 300
        lo_2 = lo_1;

#line 297
    }

#line 307
    uint _S208 = w_10 - 1U;

#line 307
    lo_1 = 0U;

#line 307
    hi_1 = _S208;
    for(;;)
    {

#line 308
        if(lo_1 < hi_1)
        {
        }
        else
        {

#line 308
            break;
        }
        uint mid_2 = (lo_1 + hi_1) / 2U;
        if(kernelContext_34->envCond_0[lo_2 * w_10 + mid_2] >= u2_0)
        {

#line 311
            hi_1 = mid_2;

#line 311
        }
        else
        {

#line 311
            lo_1 = mid_2 + 1U;

#line 311
        }

#line 308
    }

#line 317
    float phi_0 = ((float(lo_1) + u3_0) / float(w_10) - 0.5f) * 2.0f * 3.1415927410125732f;
    float theta_0 = (float(lo_2) + u4_0) / float(h_9) * 3.1415927410125732f;
    float st_0 = sin(theta_0);

#line 319
    float3 _S209 = envTexel_0(lo_1, lo_2, kernelContext_34);
    *le_0 = _S209;
    float _S210 = lum_0(_S209);

#line 321
    float _S211 = pf_0(26U, kernelContext_34);

#line 321
    *pdf_0 = _S210 * _S211;
    return float3(st_0 * sin(phi_0), cos(theta_0), - st_0 * cos(phi_0));
}


#line 94
float4 nrcBounds_0(KernelContext_0 thread* kernelContext_35)
{

#line 94
    float _S212 = pf_0(45U, kernelContext_35);

#line 94
    float _S213 = pf_0(46U, kernelContext_35);

#line 94
    float _S214 = pf_0(47U, kernelContext_35);

#line 94
    float _S215 = pf_0(48U, kernelContext_35);

#line 94
    return float4(_S212, _S213, _S214, _S215);
}


#line 53 "shaders/include/nrc_net.slang"
float3 nrcUnit_0(float3 p_6, KernelContext_0 thread* kernelContext_36)
{

#line 53
    float4 _S216 = nrcBounds_0(kernelContext_36);

#line 53
    return saturate((p_6 - _S216.xyz) * float3(_S216.w) );
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
void nrcCorner_0(float3 u_2, uint level_1, uint k_4, uint thread* slot_1, float thread* w_11)
{

    float3 s_8 = u_2 * float3(nrcLevelRes_0(level_1)) ;
    float3 f_0 = floor(s_8);
    float3 t_4 = s_8 - f_0;
    uint _S217 = k_4 & 1U;

#line 47
    uint _S218 = (k_4 >> 1U) & 1U;

#line 47
    uint _S219 = (k_4 >> 2U) & 1U;
    uint3 c_9 = uint3(f_0) + uint3(_S217, _S218, _S219);

#line 48
    float _S220;
    if(_S217 != 0U)
    {

#line 49
        _S220 = t_4.x;

#line 49
    }
    else
    {

#line 49
        _S220 = 1.0f - t_4.x;

#line 49
    }

#line 49
    float _S221;

#line 49
    if(_S218 != 0U)
    {

#line 49
        _S221 = t_4.y;

#line 49
    }
    else
    {

#line 49
        _S221 = 1.0f - t_4.y;

#line 49
    }

#line 49
    float _S222 = _S220 * _S221;

#line 49
    if(_S219 != 0U)
    {

#line 49
        _S220 = t_4.z;

#line 49
    }
    else
    {

#line 49
        _S220 = 1.0f - t_4.z;

#line 49
    }

#line 49
    *w_11 = _S222 * _S220;
    *slot_1 = (level_1 * 32768U + nrcHash_0(c_9, level_1)) * 2U;
    return;
}


float nrcSoftplus_0(float x_8)
{

#line 55
    float _S223;

#line 55
    if(x_8 > 20.0f)
    {

#line 55
        _S223 = x_8;

#line 55
    }
    else
    {

#line 55
        _S223 = log(1.0f + exp(x_8));

#line 55
    }

#line 55
    return _S223;
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
NrcAct_0 nrcForward_0(float3 p_7, float3 n_7, KernelContext_0 thread* kernelContext_37)
{

#line 57
    uint k_5;

#line 57
    float f0_1;

    thread NrcAct_0 a_6;

#line 59
    float3 _S224 = nrcUnit_0(p_7, kernelContext_37);

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
            thread float w_12;
            nrcCorner_0(_S224, l_2, k_5, &slot_2, &w_12);
            float f0_2 = f0_1 + w_12 * *(kernelContext_37->restir_0+slot_2);
            float f1_1 = f1_0 + w_12 * *(kernelContext_37->restir_0+(slot_2 + 1U));

#line 64
            k_5 = k_5 + 1U;

#line 64
            f0_1 = f0_2;

#line 64
            f1_0 = f1_1;

#line 64
        }

#line 72
        uint _S225 = 2U * l_2;

#line 72
        (&a_6)->x_9[_S225] = f0_1;
        (&a_6)->x_9[_S225 + 1U] = f1_0;

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
        (&a_6)->x_9[16U + k_5] = n_7[k_5];

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
        float device* _S226 = kernelContext_37->restir_0+(524896U + j_4);

#line 79
        k_5 = 0U;

#line 79
        f0_1 = *_S226;
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
            float s_9 = f0_1 + *(kernelContext_37->restir_0+(524288U + j_4 * 19U + k_5)) * (&a_6)->x_9[k_5];

#line 80
            k_5 = k_5 + 1U;

#line 80
            f0_1 = s_9;

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
        float device* _S227 = kernelContext_37->restir_0+(525952U + j_4);

#line 86
        k_5 = 0U;

#line 86
        f0_1 = *_S227;
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
            float s_10 = f0_1 + *(kernelContext_37->restir_0+(524928U + j_4 * 32U + k_5)) * (&a_6)->a1_0[k_5];

#line 87
            k_5 = k_5 + 1U;

#line 87
            f0_1 = s_10;

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
        float device* _S228 = kernelContext_37->restir_0+(526080U + o_7);

#line 93
        k_5 = 0U;

#line 93
        f0_1 = *_S228;
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
            float s_11 = f0_1 + *(kernelContext_37->restir_0+(525984U + o_7 * 32U + k_5)) * (&a_6)->a2_1[k_5];

#line 94
            k_5 = k_5 + 1U;

#line 94
            f0_1 = s_11;

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

float3 nrcQuery_0(float3 p_8, float3 n_8, KernelContext_0 thread* kernelContext_38)
{

#line 102
    NrcAct_0 _S229 = nrcForward_0(p_8, n_8, kernelContext_38);

#line 102
    return _S229.y_4;
}


#line 180 "shaders/include/pt_core.slang"
float3 sampleVndf_0(float3 wo_0, float alpha_5, float u1_1, float u2_1)
{
    float3 vh_0 = normalize(float3(alpha_5 * wo_0.x, alpha_5 * wo_0.y, wo_0.z));
    float _S230 = vh_0.x;

#line 183
    float _S231 = vh_0.y;

#line 183
    float lensq_0 = _S230 * _S230 + _S231 * _S231;

#line 183
    float3 t1_0;
    if(lensq_0 > 0.0f)
    {

#line 184
        t1_0 = float3(- _S231, _S230, 0.0f) * float3(rsqrt(lensq_0)) ;

#line 184
    }
    else
    {

#line 184
        t1_0 = float3(1.0f, 0.0f, 0.0f);

#line 184
    }

    float r_5 = sqrt(u1_1);
    float phi_1 = 6.2831854820251465f * u2_1;
    float a_7 = r_5 * cos(phi_1);

    float s_12 = 0.5f * (1.0f + vh_0.z);
    float _S232 = 1.0f - a_7 * a_7;

#line 191
    float b_2 = (1.0f - s_12) * sqrt(_S232) + s_12 * (r_5 * sin(phi_1));
    float3 nh_0 = float3(a_7)  * t1_0 + float3(b_2)  * cross(vh_0, t1_0) + float3(sqrt(max(0.0f, _S232 - b_2 * b_2)))  * vh_0;
    return normalize(float3(alpha_5 * nh_0.x, alpha_5 * nh_0.y, max(0.0f, nh_0.z)));
}


#line 132
float3 cosineLocal_0(float u1_2, float u2_2)
{
    float r_6 = sqrt(u1_2);
    float phi_2 = 6.2831854820251465f * u2_2;
    return float3(r_6 * cos(phi_2), r_6 * sin(phi_2), sqrt(max(0.0f, 1.0f - u1_2)));
}


#line 1009
bool shadePath_0(PathState_0 thread* st_1, const Hit_0 thread* hq_0, uint depth_3, uint pixel_8, KernelContext_0 thread* kernelContext_39)
{

#line 1009
    uint k_6;

#line 1009
    int chan_1;

#line 1009
    bool alive_0;

#line 1009
    bool _S233;

#line 1009
    float dist_4;

#line 1009
    float vv_0;

#line 1009
    float us_0;

#line 1009
    float _S234;

#line 1009
    float _S235;

#line 1009
    float3 wi_6;

#line 1009
    float3 li_0;

#line 1009
    bool _S236;

#line 1009
    bool _S237;

#line 1009
    bool chooseEnv_0;

#line 1009
    bool _S238;

#line 1009
    bool track_0;

#line 1009
    float _S239 = pf_0(20U, kernelContext_39);

#line 1009
    float _S240 = pf_0(21U, kernelContext_39);

#line 1009
    float _S241 = pf_0(22U, kernelContext_39);

    float3 _S242 = float3(_S239, _S240, _S241);
    bool _S243 = kernelContext_39->params_0[int(28)] != 0U;
    uint _S244 = kernelContext_39->params_0[int(5)];
    uint emitterCount_0 = kernelContext_39->params_0[int(23)];
    bool hasEnv_0 = kernelContext_39->params_0[int(24)] > 0U;

#line 1015
    float _S245;

    if(hasEnv_0)
    {

#line 1017
        if(emitterCount_0 > 0U)
        {

#line 1017
            _S245 = 0.5f;

#line 1017
        }
        else
        {

#line 1017
            _S245 = 1.0f;

#line 1017
        }

#line 1017
    }
    else
    {

#line 1017
        _S245 = 0.0f;

#line 1017
    }
    thread Rng_0 rng_4;
    (&rng_4)->state_0 = st_1->rng_0;

#line 1019
    uint cls_4 = st_1->cls_0;

#line 1019
    float3 dir_2 = st_1->dir_0;

#line 1019
    float3 org_2 = st_1->org_0;

#line 1019
    int chan_2 = st_1->chan_0;

#line 1019
    uint once_0 = 0U;

#line 1019
    float3 thr_1 = st_1->thr_0;

#line 1026
    for(;;)
    {

#line 1026
        if(once_0 < 1U)
        {
        }
        else
        {

#line 1026
            chan_1 = chan_2;

#line 1026
            alive_0 = true;

#line 1026
            break;
        }

#line 1026
        float wB_0;

        if(!hq_0->hit_0)
        {
            if(restirCompiled_0)
            {

#line 1030
                alive_0 = depth_3 == 0U;

#line 1030
            }
            else
            {

#line 1030
                alive_0 = false;

#line 1030
            }

#line 1030
            if(alive_0)
            {

#line 1030
                alive_0 = kernelContext_39->params_0[int(36)] != 0U;

#line 1030
            }
            else
            {

#line 1030
                alive_0 = false;

#line 1030
            }

#line 1030
            if(alive_0)
            {

#line 1030
                restirClear_0(pixel_8, kernelContext_39);

#line 1030
            }


            if(depth_3 == 0U)
            {

#line 1033
                alive_0 = kernelContext_39->params_0[int(42)] != 0U;

#line 1033
            }
            else
            {

#line 1033
                alive_0 = false;

#line 1033
            }

#line 1033
            if(alive_0)
            {

#line 1033
                chan_1 = chan_2;

#line 1033
                alive_0 = false;


                break;
            }

            Parts_add_0(&st_1->parts_0, depth_3, cls_4, thr_1 * _S242);
            if(hasEnv_0)
            {

                if(st_1->misPrev_0)
                {
                    if(st_1->restir_1)
                    {

#line 1045
                        alive_0 = depth_3 == 1U;

#line 1045
                    }
                    else
                    {

#line 1045
                        alive_0 = false;

#line 1045
                    }

#line 1045
                    if(alive_0)
                    {

#line 1045
                        _S245 = 1.0f;

#line 1045
                    }

#line 1045
                    float _S246 = envPdf_0(dir_2, kernelContext_39);

#line 1045
                    float pl_0 = _S245 * _S246;
                    float den_0 = st_1->qPrev_0 * st_1->qPrev_0 + pl_0 * pl_0;
                    if(den_0 > 0.0f)
                    {

#line 1047
                        _S245 = st_1->qPrev_0 * st_1->qPrev_0 / den_0;

#line 1047
                    }
                    else
                    {

#line 1047
                        _S245 = 1.0f;

#line 1047
                    }

#line 1047
                    wB_0 = _S245;

#line 1043
                }
                else
                {

#line 1043
                    wB_0 = 1.0f;

#line 1043
                }

#line 1043
                float3 _S247 = envRadiance_0(dir_2, kernelContext_39);

#line 1049
                Parts_add_0(&st_1->parts_0, depth_3, cls_4, thr_1 * _S247 * float3(wB_0) );

#line 1040
            }

#line 1040
            chan_1 = chan_2;

#line 1040
            alive_0 = false;

#line 1051
            break;
        }

#line 1051
        uint _S248 = hq_0->inst_0;


        uint inst_3 = hq_0->inst_0 * 16U;

#line 1054
        uint _S249 = hq_0->prim_0;
        uint tri_1 = kernelContext_39->instances_0[inst_3 + 1U] + 3U * hq_0->prim_0;
        uint vo_1 = kernelContext_39->instances_0[inst_3];
        uint _S250 = inst_3 + 4U;

#line 1057
        float3 _S251 = vertexPos_0(kernelContext_39->indices_0[tri_1] + vo_1, kernelContext_39);

#line 1057
        float3 _S252 = transformPoint_0(_S250, _S251, kernelContext_39);
        uint _S253 = tri_1 + 1U;

#line 1058
        float3 _S254 = vertexPos_0(kernelContext_39->indices_0[_S253] + vo_1, kernelContext_39);

#line 1058
        float3 _S255 = transformPoint_0(_S250, _S254, kernelContext_39);
        uint _S256 = tri_1 + 2U;

#line 1059
        float3 _S257 = vertexPos_0(kernelContext_39->indices_0[_S256] + vo_1, kernelContext_39);

#line 1059
        float3 _S258 = transformPoint_0(_S250, _S257, kernelContext_39);

        float3 _S259 = _S255 - _S252;

#line 1061
        float3 _S260 = _S258 - _S252;

#line 1061
        float3 _S261 = cross(_S259, _S260);

#line 1061
        float3 nOut_0 = normalize(_S261);
        float3 wo_1 = - dir_2;
        bool outside_1 = (dot(nOut_0, wo_1)) > 0.0f;

#line 1063
        float3 ng_0;
        if(outside_1)
        {

#line 1064
            ng_0 = nOut_0;

#line 1064
        }
        else
        {

#line 1064
            ng_0 = - nOut_0;

#line 1064
        }

#line 1064
        float _S262 = hq_0->t_0;

        st_1->pathLen_0 = st_1->pathLen_0 + hq_0->t_0;
        float3 hit_1 = org_2 + dir_2 * float3(_S262) ;

#line 1073
        float3 e3_0 = hit_1 - _S252;
        float d11_0 = dot(_S259, _S259);
        float d12_0 = dot(_S259, _S260);
        float d22_0 = dot(_S260, _S260);
        float _S263 = max(d11_0 * d22_0 - d12_0 * d12_0, 9.99999968265522539e-21f);
        float _S264 = dot(e3_0, _S259);

#line 1078
        float _S265 = dot(e3_0, _S260);

#line 1078
        float b1_0 = (d22_0 * _S264 - d12_0 * _S265) / _S263;
        float b2_0 = (d11_0 * _S265 - d12_0 * _S264) / _S263;

#line 1079
        float _S266 = opacityAt_0(_S248, _S249, float2(b1_0, b2_0), kernelContext_39);


        if(_S266 < 1.0f)
        {

#line 1082
            float _S267 = Rng_next_0(&rng_4);

#line 1082
            alive_0 = _S267 >= _S266;

#line 1082
        }
        else
        {

#line 1082
            alive_0 = false;

#line 1082
        }

#line 1082
        if(alive_0)
        {

#line 1082
            org_2 = hit_1 + dir_2 * float3(9.9999997473787516e-05f) ;

#line 1082
            chan_1 = chan_2;

#line 1082
            alive_0 = true;


            break;
        }

        float3 p_9 = hit_1 + ng_0 * float3(9.9999997473787516e-05f) ;
        bool _S268 = depth_3 == 1U;

#line 1089
        if(_S268)
        {

#line 1089
            _S233 = st_1->gi_0;

#line 1089
        }
        else
        {

#line 1089
            _S233 = false;

#line 1089
        }

#line 1089
        if(_S233)
        {

            uint _S269 = restirBase_0(pixel_8, kernelContext_39->params_0[int(6)] & 1U);

#line 1092
            k_6 = 0U;
            for(;;)
            {

#line 1093
                if(k_6 < 3U)
                {
                }
                else
                {

#line 1093
                    break;
                }
                *(kernelContext_39->restir_0+(_S269 + 16U + k_6)) = hit_1[k_6];
                *(kernelContext_39->restir_0+(_S269 + 19U + k_6)) = ng_0[k_6];

#line 1093
                k_6 = k_6 + 1U;

#line 1093
            }

#line 1098
            *(kernelContext_39->restir_0+(restirScratch_0(pixel_8) + 22U)) = (as_type<float>((1U)));

#line 1089
        }

#line 1103
        float _S270 = 1.0f - b1_0 - b2_0;

#line 1103
        float3 _S271 = vertexNormal_0(kernelContext_39->indices_0[tri_1] + vo_1, kernelContext_39);

#line 1103
        float3 _S272 = float3(_S270)  * _S271;

#line 1103
        float3 _S273 = vertexNormal_0(kernelContext_39->indices_0[_S253] + vo_1, kernelContext_39);

#line 1103
        float3 _S274 = _S272 + float3(b1_0)  * _S273;

#line 1103
        float3 _S275 = vertexNormal_0(kernelContext_39->indices_0[_S256] + vo_1, kernelContext_39);

#line 1103
        float3 nsObj_0 = _S274 + float3(b2_0)  * _S275;

#line 1103
        float3 ns_0;

        if((dot(nsObj_0, nsObj_0)) > 9.999999960041972e-13f)
        {

#line 1105
            float3 _S276 = transformNormal_0(_S250, nsObj_0, kernelContext_39);

            float3 ns_1 = normalize(_S276);
            if((dot(ns_1, nOut_0)) < 0.0f)
            {

#line 1108
                ns_0 = - ns_1;

#line 1108
            }
            else
            {

#line 1108
                ns_0 = ns_1;

#line 1108
            }

#line 1105
        }
        else
        {

#line 1105
            ns_0 = nOut_0;

#line 1105
        }

#line 1105
        float3 _S277;

#line 1111
        if(outside_1)
        {

#line 1111
            _S277 = ns_0;

#line 1111
        }
        else
        {

#line 1111
            _S277 = - ns_0;

#line 1111
        }

        uint mi_1 = kernelContext_39->instances_0[inst_3 + 2U] * 24U;
        float3 albedo_1 = float3(kernelContext_39->materials_0[mi_1], kernelContext_39->materials_0[mi_1 + 1U], kernelContext_39->materials_0[mi_1 + 2U]);

        uint texBase_0 = uint(kernelContext_39->materials_0[mi_1 + 10U]);
        uint texMR_0 = uint(kernelContext_39->materials_0[mi_1 + 11U]);
        uint texEm_0 = uint(kernelContext_39->materials_0[mi_1 + 12U]);
        uint texNm_0 = uint(kernelContext_39->materials_0[mi_1 + 13U]);
        float2 _S278 = float2(1.0f) ;
        float3 _S279 = float3(1.0f) ;

#line 1121
        float3 albedo_2;

#line 1121
        float3 texEmission_0;

#line 1121
        float3 n_9;

#line 1121
        float3 n_10;

#line 1121
        bool _S280;

#line 1121
        float2 texRM_0;
        if((texBase_0 + texMR_0 + texEm_0 + texNm_0) > 0U)
        {
            float2 uv0_1 = float2(kernelContext_39->uvs_0[2U * (kernelContext_39->indices_0[tri_1] + vo_1)], kernelContext_39->uvs_0[2U * (kernelContext_39->indices_0[tri_1] + vo_1) + 1U]);


            float2 _S281 = float2(kernelContext_39->uvs_0[2U * (kernelContext_39->indices_0[_S253] + vo_1)], kernelContext_39->uvs_0[2U * (kernelContext_39->indices_0[_S253] + vo_1) + 1U]) - uv0_1;

#line 1127
            float2 _S282 = float2(kernelContext_39->uvs_0[2U * (kernelContext_39->indices_0[_S256] + vo_1)], kernelContext_39->uvs_0[2U * (kernelContext_39->indices_0[_S256] + vo_1) + 1U]) - uv0_1;

#line 1127
            float2 uv_2 = uv0_1 + float2(b1_0)  * _S281 + float2(b2_0)  * _S282;


            float _S283 = _S281.x;

#line 1130
            float _S284 = _S282.y;

#line 1130
            float _S285 = _S283 * _S284;

#line 1130
            float _S286 = _S281.y;

#line 1130
            float _S287 = _S282.x;

#line 1130
            float uvPerWorld_0 = sqrt(abs(_S285 - _S286 * _S287) / max(length(_S261), 9.99999968265522539e-21f));
            float _S288 = st_1->pathLen_0;

#line 1131
            float _S289 = pf_0(27U, kernelContext_39);

#line 1131
            float footprint_1 = _S288 * _S289 / max(abs(dot(nOut_0, dir_2)), 0.10000000149011612f) * uvPerWorld_0;
            if(texBase_0 > 0U)
            {

#line 1132
                float3 _S290 = sampleTexture_0(texBase_0 - 1U, uv_2, footprint_1, kernelContext_39);

#line 1132
                albedo_2 = albedo_1 * _S290;

#line 1132
            }
            else
            {

#line 1132
                albedo_2 = albedo_1;

#line 1132
            }

            if(texMR_0 > 0U)
            {

#line 1134
                float3 _S291 = sampleTexture_0(texMR_0 - 1U, uv_2, footprint_1, kernelContext_39);

#line 1134
                texRM_0 = _S291.yz;

#line 1134
            }
            else
            {

#line 1134
                texRM_0 = _S278;

#line 1134
            }

            if(texEm_0 > 0U)
            {

#line 1136
                float3 _S292 = sampleTexture_0(texEm_0 - 1U, uv_2, footprint_1, kernelContext_39);

#line 1136
                texEmission_0 = _S292;

#line 1136
            }
            else
            {

#line 1136
                texEmission_0 = _S279;

#line 1136
            }

            if(texNm_0 > 0U)
            {

                float det_0 = _S285 - _S287 * _S286;

#line 1141
                float3 _S293 = float3(det_0) ;
                float3 dPdu_0 = (_S259 * float3(_S284)  - _S260 * float3(_S286) ) / _S293;
                float3 dPdv_0 = (_S260 * float3(_S283)  - _S259 * float3(_S287) ) / _S293;
                float3 tg_0 = dPdu_0 - ns_0 * float3(dot(ns_0, dPdu_0)) ;
                if((abs(det_0)) > 9.99999968265522539e-21f)
                {

#line 1145
                    _S280 = (dot(tg_0, tg_0)) > 9.99999968265522539e-21f;

#line 1145
                }
                else
                {

#line 1145
                    _S280 = false;

#line 1145
                }

#line 1145
                if(_S280)
                {
                    float3 tg_1 = normalize(tg_0);
                    float3 bt_0 = cross(ns_0, tg_1);
                    if((dot(bt_0, dPdv_0)) > 0.0f)
                    {

#line 1149
                        n_9 = - bt_0;

#line 1149
                    }
                    else
                    {

#line 1149
                        n_9 = bt_0;

#line 1149
                    }

#line 1149
                    float3 _S294 = sampleTexture_0(texNm_0 - 1U, uv_2, footprint_1, kernelContext_39);

                    float3 nt_0 = _S294 * float3(2.0f)  - float3(1.0f) ;
                    uint _S295 = mi_1 + 14U;

#line 1152
                    float3 ns_2 = normalize(float3((nt_0.x * kernelContext_39->materials_0[_S295]))  * tg_1 + float3((nt_0.y * kernelContext_39->materials_0[_S295]))  * n_9 + float3(nt_0.z)  * ns_0);
                    if(outside_1)
                    {

#line 1153
                        n_10 = ns_2;

#line 1153
                    }
                    else
                    {

#line 1153
                        n_10 = - ns_2;

#line 1153
                    }

#line 1153
                    n_9 = n_10;

#line 1145
                }
                else
                {

#line 1145
                    n_9 = _S277;

#line 1145
                }

#line 1138
            }
            else
            {

#line 1138
                n_9 = _S277;

#line 1138
            }

#line 1122
        }
        else
        {

#line 1122
            n_9 = _S277;

#line 1122
            texEmission_0 = _S279;

#line 1122
            texRM_0 = _S278;

#line 1122
            albedo_2 = albedo_1;

#line 1122
        }

#line 1159
        float woN_0 = dot(n_9, wo_1);
        if(woN_0 < 0.05000000074505806f)
        {

#line 1160
            n_10 = normalize(n_9 + wo_1 * float3((0.05000000074505806f - woN_0)) );

#line 1160
        }
        else
        {

#line 1160
            n_10 = n_9;

#line 1160
        }


        float3 _S296 = float3(kernelContext_39->materials_0[mi_1 + 3U], kernelContext_39->materials_0[mi_1 + 4U], kernelContext_39->materials_0[mi_1 + 5U]) * texEmission_0;

        if((st_1->prevInst_0) != 0U)
        {

#line 1165
            uint _S297 = emitMask_0(_S248, kernelContext_39);

#line 1165
            uint _S298 = recvMask_0(st_1->prevInst_0 - 1U, kernelContext_39);

#line 1165
            _S280 = (_S297 & _S298) == 0U;

#line 1165
        }
        else
        {

#line 1165
            _S280 = false;

#line 1165
        }

#line 1165
        float3 le_1;

#line 1165
        if(_S280)
        {

#line 1165
            le_1 = float3(0.0f) ;

#line 1165
        }
        else
        {

#line 1165
            le_1 = _S296;

#line 1165
        }

#line 1165
        bool _S299;

#line 1165
        bool _S300;

        if(any(le_1 > (float3(0.0f) )))
        {

            uint eb_0 = kernelContext_39->instances_0[inst_3 + 3U];
            if(st_1->misPrev_0)
            {

#line 1171
                _S299 = eb_0 != 0U;

#line 1171
            }
            else
            {

#line 1171
                _S299 = false;

#line 1171
            }

#line 1171
            if(_S299)
            {
                uint e_2 = (eb_0 - 1U + _S249) * 16U;
                float _S301 = max(abs(dot(nOut_0, dir_2)), 9.9999997473787516e-05f);
                if(st_1->restir_1)
                {

#line 1175
                    _S300 = _S268;

#line 1175
                }
                else
                {

#line 1175
                    _S300 = false;

#line 1175
                }

#line 1175
                if(_S300)
                {

#line 1175
                    wB_0 = 1.0f;

#line 1175
                }
                else
                {

#line 1175
                    wB_0 = 1.0f - _S245;

#line 1175
                }

#line 1175
                float pl_1 = wB_0 * kernelContext_39->emitters_0[e_2 + 13U] * _S262 * _S262 / (kernelContext_39->emitters_0[e_2 + 12U] * _S301);

#line 1175
                wB_0 = st_1->qPrev_0 * st_1->qPrev_0 / (st_1->qPrev_0 * st_1->qPrev_0 + pl_1 * pl_1);

#line 1171
            }
            else
            {

#line 1171
                wB_0 = 1.0f;

#line 1171
            }

#line 1178
            float3 _S302 = thr_1 * le_1 * float3(wB_0) ;

#line 1178
            Parts_add_0(&st_1->parts_0, depth_3, cls_4, _S302);
            if(_S268)
            {

#line 1179
                _S300 = st_1->gi_0;

#line 1179
            }
            else
            {

#line 1179
                _S300 = false;

#line 1179
            }

#line 1179
            if(_S300)
            {


                uint _S303 = restirScratch_0(pixel_8) + 18U;

#line 1183
                k_6 = 0U;
                for(;;)
                {

#line 1184
                    if(k_6 < 3U)
                    {
                    }
                    else
                    {

#line 1184
                        break;
                    }

#line 1185
                    float device* _S304 = kernelContext_39->restir_0+(_S303 + k_6);

#line 1185
                    *_S304 = *_S304 + _S302[k_6];

#line 1184
                    k_6 = k_6 + 1U;

#line 1184
                }

#line 1179
            }

#line 1167
        }

#line 1188
        float metallic_1 = kernelContext_39->materials_0[mi_1 + 6U] * texRM_0.y;
        float rough_1 = kernelContext_39->materials_0[mi_1 + 7U] * texRM_0.x;
        float transmission_2 = kernelContext_39->materials_0[mi_1 + 8U];
        float ior_2 = kernelContext_39->materials_0[mi_1 + 9U];
        float dispersion_0 = kernelContext_39->materials_0[mi_1 + 21U];
        if(dispersion_0 > 0.0f)
        {

#line 1193
            _S299 = transmission_2 > 0.0f;

#line 1193
        }
        else
        {

#line 1193
            _S299 = false;

#line 1193
        }

#line 1193
        float eta_2;

#line 1193
        float _S305;

#line 1193
        float3 thr_2;

#line 1193
        if(_S299)
        {


            if(chan_2 < int(0))
            {
                float _S306 = Rng_next_0(&rng_4);

#line 1199
                int _S307 = min(int(_S306 * 3.0f), int(2));
                if(_S307 == int(0))
                {

#line 1200
                    wB_0 = 1.0f;

#line 1200
                }
                else
                {

#line 1200
                    wB_0 = 0.0f;

#line 1200
                }

#line 1200
                if(_S307 == int(1))
                {

#line 1200
                    eta_2 = 1.0f;

#line 1200
                }
                else
                {

#line 1200
                    eta_2 = 0.0f;

#line 1200
                }

#line 1200
                if(_S307 == int(2))
                {

#line 1200
                    _S305 = 1.0f;

#line 1200
                }
                else
                {

#line 1200
                    _S305 = 0.0f;

#line 1200
                }

#line 1200
                float3 thr_3 = thr_1 * (float3(3.0f)  * float3(wB_0, eta_2, _S305));

#line 1200
                chan_1 = _S307;

#line 1200
                thr_2 = thr_3;

#line 1197
            }
            else
            {

#line 1197
                chan_1 = chan_2;

#line 1197
                thr_2 = thr_1;

#line 1197
            }

#line 1197
            wB_0 = max(ior_2 + float(chan_1 - int(1)) * (ior_2 - 1.0f) * 0.02500000037252903f * dispersion_0, 1.0f);

#line 1193
        }
        else
        {

#line 1193
            wB_0 = ior_2;

#line 1193
            chan_1 = chan_2;

#line 1193
            thr_2 = thr_1;

#line 1193
        }

#line 1206
        if(_S268)
        {

#line 1206
            _S300 = st_1->gi_0;

#line 1206
        }
        else
        {

#line 1206
            _S300 = false;

#line 1206
        }

#line 1206
        bool _S308;

#line 1206
        if(_S300)
        {

#line 1206
            _S308 = transmission_2 > 0.0f;

#line 1206
        }
        else
        {

#line 1206
            _S308 = false;

#line 1206
        }

#line 1206
        if(_S308)
        {

#line 1207
            *(kernelContext_39->restir_0+(restirScratch_0(pixel_8) + 22U)) = (as_type<float>((0U)));

#line 1206
        }

        float _S309 = max(rough_1 * rough_1, 0.0010000000474974513f);
        if(outside_1)
        {

#line 1209
            eta_2 = wB_0;

#line 1209
        }
        else
        {

#line 1209
            eta_2 = 1.0f / wB_0;

#line 1209
        }

        thread float3 T_2;

#line 1211
        thread float3 B_2;
        basis_0(n_10, &T_2, &B_2);
        float _S310 = max(dot(wo_1, n_10), 9.9999997473787516e-05f);

#line 1213
        float3 woL_6 = float3(dot(wo_1, T_2), dot(wo_1, B_2), _S310);
        float fSel_1 = fresnelDielectric_0(_S310, wB_0);
        thread Surface_0 surf_3;
        (&surf_3)->albedo_0 = albedo_2;
        (&surf_3)->metallic_0 = metallic_1;
        (&surf_3)->alpha_3 = _S309;
        (&surf_3)->transmission_1 = transmission_2;
        (&surf_3)->ior_1 = wB_0;
        (&surf_3)->eta_1 = eta_2;
        (&surf_3)->fSel_0 = fSel_1;


        (&surf_3)->tComp_0 = 1.0f;

#line 1225
        bool _S311;
        if(kernelContext_39->params_0[int(29)] != 0U)
        {

#line 1226
            _S311 = transmission_2 > 0.0f;

#line 1226
        }
        else
        {

#line 1226
            _S311 = false;

#line 1226
        }

#line 1226
        bool _S312;

#line 1226
        if(_S311)
        {

#line 1226
            _S312 = rough_1 > 0.0f;

#line 1226
        }
        else
        {

#line 1226
            _S312 = false;

#line 1226
        }

#line 1226
        if(_S312)
        {

#line 1226
            float _S313 = dielectricAlbedo_0(_S310, rough_1, wB_0, outside_1, kernelContext_39);
            (&surf_3)->tComp_0 = 1.0f / max(_S313, 0.10000000149011612f);

#line 1226
        }


        if(outside_1)
        {

#line 1229
            _S305 = kernelContext_39->materials_0[mi_1 + 15U];

#line 1229
        }
        else
        {

#line 1229
            _S305 = 0.0f;

#line 1229
        }

#line 1229
        (&surf_3)->coat_0 = _S305;
        uint _S314 = mi_1 + 16U;

#line 1230
        (&surf_3)->coatAlpha_0 = max(kernelContext_39->materials_0[_S314] * kernelContext_39->materials_0[_S314], 0.0010000000474974513f);
        float coatF_0 = fresnelDielectric_0(_S310, 1.5f);
        (&surf_3)->coatP_0 = _S305 * coatF_0;

#line 1232
        float3 _S315;
        if(outside_1)
        {

#line 1233
            _S315 = float3(kernelContext_39->materials_0[mi_1 + 18U], kernelContext_39->materials_0[mi_1 + 19U], kernelContext_39->materials_0[mi_1 + 20U]);

#line 1233
        }
        else
        {

#line 1233
            _S315 = float3(0.0f) ;

#line 1233
        }

#line 1233
        (&surf_3)->sheenColor_0 = _S315;
        float _S316 = max(_S315.x, max(_S315.y, _S315.z));
        float _S317 = max(kernelContext_39->materials_0[mi_1 + 17U], 0.070000000298023224f);
        (&surf_3)->sheenAlpha_0 = _S317 * _S317;

#line 1236
        float _S318;
        if(_S316 > 0.0f)
        {

#line 1237
            float _S319 = sheenAlbedo_0(_S310, _S317, kernelContext_39);

#line 1237
            _S318 = _S316 * _S319;

#line 1237
        }
        else
        {

#line 1237
            _S318 = 0.0f;

#line 1237
        }

#line 1237
        (&surf_3)->sheenP_0 = _S318;

#line 1237
        bool _S320;



        if(nrcCompiled_0)
        {

#line 1241
            _S320 = kernelContext_39->params_0[int(44)] != 0U;

#line 1241
        }
        else
        {

#line 1241
            _S320 = false;

#line 1241
        }

#line 1241
        bool _S321;

#line 1241
        if(_S320)
        {

#line 1241
            _S321 = _S268;

#line 1241
        }
        else
        {

#line 1241
            _S321 = false;

#line 1241
        }

#line 1241
        bool _S322;

#line 1241
        if(_S321)
        {

#line 1241
            _S322 = cls_4 == 0U;

#line 1241
        }
        else
        {

#line 1241
            _S322 = false;

#line 1241
        }

#line 1241
        bool _S323;

#line 1241
        if(_S322)
        {

#line 1241
            _S323 = !st_1->gi_0;

#line 1241
        }
        else
        {

#line 1241
            _S323 = false;

#line 1241
        }

#line 1241
        bool _S324;

#line 1241
        if(_S323)
        {

#line 1241
            bool _S325 = nrcFallback_0(pixel_8, kernelContext_39);

#line 1241
            _S324 = !_S325;

#line 1241
        }
        else
        {

#line 1241
            _S324 = false;

#line 1241
        }

#line 1241
        bool _S326;
        if(_S324)
        {

#line 1242
            _S326 = metallic_1 == 0.0f;

#line 1242
        }
        else
        {

#line 1242
            _S326 = false;

#line 1242
        }

#line 1242
        bool _S327;

#line 1242
        if(_S326)
        {

#line 1242
            _S327 = transmission_2 == 0.0f;

#line 1242
        }
        else
        {

#line 1242
            _S327 = false;

#line 1242
        }

#line 1242
        bool _S328;

#line 1242
        if(_S327)
        {

#line 1242
            _S328 = ((&surf_3)->coat_0) == 0.0f;

#line 1242
        }
        else
        {

#line 1242
            _S328 = false;

#line 1242
        }

#line 1242
        bool nrcCut_0;

#line 1242
        if(_S328)
        {

#line 1242
            nrcCut_0 = ((&surf_3)->sheenP_0) == 0.0f;

#line 1242
        }
        else
        {

#line 1242
            nrcCut_0 = false;

#line 1242
        }

#line 1242
        k_6 = 0U;



        for(;;)
        {

#line 1246
            if(k_6 < _S244)
            {
            }
            else
            {

#line 1246
                break;
            }
            uint o_8 = k_6 * 16U;
            float3 col_0 = float3((as_type<float>((kernelContext_39->lights_0[o_8 + 1U]))), (as_type<float>((kernelContext_39->lights_0[o_8 + 2U]))), (as_type<float>((kernelContext_39->lights_0[o_8 + 3U])))) * float3((as_type<float>((kernelContext_39->lights_0[o_8 + 4U])))) ;
            float3 vec_0 = float3((as_type<float>((kernelContext_39->lights_0[o_8 + 5U]))), (as_type<float>((kernelContext_39->lights_0[o_8 + 6U]))), (as_type<float>((kernelContext_39->lights_0[o_8 + 7U]))));

            bool virt_0 = kernelContext_39->lights_0[o_8] == 3U;
            if(virt_0)
            {

#line 1253
                if(_S243)
                {

#line 1253
                    _S236 = depth_3 == 0U;

#line 1253
                }
                else
                {

#line 1253
                    _S236 = false;

#line 1253
                }

#line 1253
                _S236 = !_S236;

#line 1253
            }
            else
            {

#line 1253
                _S236 = false;

#line 1253
            }

#line 1253
            if(_S236)
            {

#line 1254
                k_6 = k_6 + 1U;

#line 1246
                continue;
            }

#line 1256
            uint _S329 = kernelContext_39->lights_0[o_8 + 14U];

#line 1256
            uint _S330 = recvMask_0(_S248, kernelContext_39);

#line 1256
            if((_S329 & _S330) == 0U)
            {

#line 1257
                k_6 = k_6 + 1U;

#line 1246
                continue;
            }

#line 1261
            if(kernelContext_39->lights_0[o_8] == 1U)
            {

#line 1261
                _S237 = true;

#line 1261
            }
            else
            {

#line 1261
                _S237 = virt_0;

#line 1261
            }

#line 1261
            if(_S237)
            {

#line 1261
                wi_6 = - normalize(vec_0);

#line 1261
                dist_4 = 1.00000001504746622e+30f;

#line 1261
                li_0 = col_0;

#line 1261
            }
            else
            {

#line 1269
                float3 toL_1 = vec_0 - p_9;
                float d2_1 = dot(toL_1, toL_1);
                float dist_5 = sqrt(d2_1);
                float3 wi_7 = toL_1 / float3(dist_5) ;
                float3 li_1 = col_0 / float3(d2_1) ;
                uint _S331 = o_8 + 15U;

#line 1274
                if(kernelContext_39->lights_0[_S331] != 0U)
                {

#line 1274
                    float _S332 = iesFactor_0(kernelContext_39->lights_0[_S331] - 1U, - wi_7, kernelContext_39);

#line 1274
                    wi_6 = li_1 * float3(_S332) ;

#line 1274
                }
                else
                {

#line 1274
                    wi_6 = li_1;

#line 1274
                }

                if(kernelContext_39->lights_0[o_8] == 2U)
                {

                    float att_0 = saturate(dot(float3((as_type<float>((kernelContext_39->lights_0[o_8 + 8U]))), (as_type<float>((kernelContext_39->lights_0[o_8 + 9U]))), (as_type<float>((kernelContext_39->lights_0[o_8 + 10U])))), - wi_7) * (as_type<float>((kernelContext_39->lights_0[o_8 + 11U]))) + (as_type<float>((kernelContext_39->lights_0[o_8 + 12U]))));

#line 1279
                    li_0 = wi_6 * float3((att_0 * att_0)) ;

#line 1276
                }
                else
                {

#line 1276
                    li_0 = wi_6;

#line 1276
                }

#line 1276
                wi_6 = wi_7;

#line 1276
                dist_4 = dist_5;

#line 1261
            }

#line 1283
            float c_10 = dot(n_10, wi_6);
            if(c_10 > 0.0f)
            {

#line 1284
                bool _S333 = occluded_0(p_9, wi_6, dist_4 - 0.0010000000474974513f, kernelContext_39);


                if(_S243)
                {

#line 1287
                    track_0 = depth_3 == 0U;

#line 1287
                }
                else
                {

#line 1287
                    track_0 = false;

#line 1287
                }
                bool _S334 = !_S333;

#line 1288
                if(_S334)
                {

#line 1288
                    chooseEnv_0 = true;

#line 1288
                }
                else
                {

#line 1288
                    chooseEnv_0 = track_0;

#line 1288
                }

#line 1288
                if(chooseEnv_0)
                {
                    float3 _S335 = float3(dot(wi_6, T_2), dot(wi_6, B_2), c_10);

#line 1290
                    thread Surface_0 _S336 = surf_3;

#line 1290
                    Lobes_0 _S337 = evalLobes_0(&_S336, woL_6, _S335, kernelContext_39);
                    float3 cd_1 = thr_2 * _S337.diffuse_0 * li_0;
                    float3 cs_1 = thr_2 * _S337.specular_1 * li_0;
                    if(_S334)
                    {

#line 1293
                        _S238 = !virt_0;

#line 1293
                    }
                    else
                    {

#line 1293
                        _S238 = false;

#line 1293
                    }

#line 1293
                    if(_S238)
                    {

#line 1294
                        Parts_addLight_0(&st_1->parts_0, depth_3, cls_4, thr_2 * (_S337.diffuse_0 + _S337.specular_1) * li_0, cd_1, cs_1);

#line 1293
                    }

                    if(track_0)
                    {
                        if(virt_0)
                        {

#line 1297
                            vv_0 = 0.0f;

#line 1297
                        }
                        else
                        {

#line 1297
                            vv_0 = lum_0(cd_1 + cs_1);

#line 1297
                        }
                        st_1->visTotal_0 = st_1->visTotal_0 + vv_0;
                        if(_S333)
                        {

#line 1299
                            us_0 = 0.0f;

#line 1299
                        }
                        else
                        {

#line 1299
                            us_0 = vv_0;

#line 1299
                        }

#line 1299
                        st_1->visLit_0 = st_1->visLit_0 + us_0;
                        uint _S338 = kernelContext_39->lights_0[o_8 + 13U];

#line 1300
                        float3 _S339 = float3(c_10) ;

#line 1300
                        float3 _S340 = cd_1 / _S339;

#line 1300
                        float3 _S341 = cs_1 / _S339;

#line 1300
                        if(_S333)
                        {

#line 1300
                            _S234 = 0.0f;

#line 1300
                        }
                        else
                        {

#line 1300
                            _S234 = 1.0f;

#line 1300
                        }

#line 1300
                        if(_S333)
                        {

#line 1300
                            _S235 = 0.0f;

#line 1300
                        }
                        else
                        {

#line 1300
                            _S235 = c_10;

#line 1300
                        }

#line 1300
                        addSlot_0(pixel_8, _S338, _S340, _S341, wi_6, _S234, _S235, kernelContext_39);

#line 1295
                    }

#line 1288
                }

#line 1284
            }

#line 1246
            k_6 = k_6 + 1U;

#line 1246
        }

#line 1309
        if(restirCompiled_0)
        {

#line 1309
            _S236 = depth_3 == 0U;

#line 1309
        }
        else
        {

#line 1309
            _S236 = false;

#line 1309
        }

#line 1309
        if(_S236)
        {

#line 1309
            _S237 = kernelContext_39->params_0[int(36)] != 0U;

#line 1309
        }
        else
        {

#line 1309
            _S237 = false;

#line 1309
        }

#line 1309
        bool suits_0;

#line 1309
        bool ok_0;

#line 1309
        bool reDI_0;

#line 1309
        bool refracted_0;

#line 1309
        if(_S237)
        {

#line 1309
            float _S342 = pf_0(3U, kernelContext_39);

            if(_S342 == 0.0f)
            {

#line 1311
                chooseEnv_0 = transmission_2 == 0.0f;

#line 1311
            }
            else
            {

#line 1311
                chooseEnv_0 = false;

#line 1311
            }

#line 1311
            if(chooseEnv_0)
            {

#line 1311
                _S238 = ((&surf_3)->alpha_3) >= 0.15000000596046448f;

#line 1311
            }
            else
            {

#line 1311
                _S238 = false;

#line 1311
            }
            if(_S238)
            {

#line 1312
                if(((&surf_3)->coat_0) == 0.0f)
                {

#line 1312
                    suits_0 = true;

#line 1312
                }
                else
                {

#line 1312
                    suits_0 = ((&surf_3)->coatAlpha_0) >= 0.15000000596046448f;

#line 1312
                }

#line 1312
            }
            else
            {

#line 1312
                suits_0 = false;

#line 1312
            }
            if(suits_0)
            {

#line 1313
                ok_0 = (kernelContext_39->params_0[int(36)] & 1U) != 0U;

#line 1313
            }
            else
            {

#line 1313
                ok_0 = false;

#line 1313
            }

#line 1313
            if(ok_0)
            {

#line 1313
                reDI_0 = emitterCount_0 > 0U;

#line 1313
            }
            else
            {

#line 1313
                reDI_0 = false;

#line 1313
            }

            if(suits_0)
            {

#line 1315
                refracted_0 = (kernelContext_39->params_0[int(36)] & 2U) != 0U;

#line 1315
            }
            else
            {

#line 1315
                refracted_0 = false;

#line 1315
            }

#line 1315
            if(refracted_0)
            {

#line 1315
                track_0 = !_S243;

#line 1315
            }
            else
            {

#line 1315
                track_0 = false;

#line 1315
            }
            st_1->restir_1 = reDI_0;
            st_1->gi_0 = track_0;
            if(suits_0)
            {

#line 1318
                restirGbuffer_0(pixel_8, p_9, n_10, kernelContext_39);


                if(track_0)
                {

#line 1321
                    thread Surface_0 _S343 = surf_3;

#line 1321
                    restirGIPrepare_0(pixel_8, p_9, n_10, _S262, &_S343, T_2, B_2, woL_6, &rng_4, kernelContext_39);

#line 1321
                }

#line 1318
            }
            else
            {

#line 1318
                restirClear_0(pixel_8, kernelContext_39);

#line 1318
            }

#line 1309
        }
        else
        {

#line 1309
            reDI_0 = false;

#line 1309
        }

#line 1327
        if(reDI_0)
        {

#line 1327
            uint _S344 = recvMask_0(_S248, kernelContext_39);

#line 1327
            thread Surface_0 _S345 = surf_3;

#line 1327
            RestirPick_0 _S346 = restirDI_0(pixel_8, _S344, p_9, n_10, _S262, &_S345, T_2, B_2, woL_6, &rng_4, kernelContext_39);


            if(_S346.valid_0)
            {


                uint _S347 = _S346.e_1 - 1U;

#line 1334
                uint _S348 = recvMask_0(_S248, kernelContext_39);

#line 1332
                thread float3 wi_8;

#line 1332
                thread float3 g_4;
                thread float dist_6;

#line 1333
                thread float cosi_5;

#line 1333
                thread float plsa_5;

#line 1333
                bool _S349 = restirLight_0(_S347, _S348, _S346.x_6, p_9, n_10, &wi_8, &dist_6, &cosi_5, &g_4, &plsa_5, kernelContext_39);


                bool _S350 = !_S346.occ_0;

#line 1336
                if(_S350)
                {

#line 1336
                    chooseEnv_0 = true;

#line 1336
                }
                else
                {

#line 1336
                    chooseEnv_0 = _S243;

#line 1336
                }

#line 1336
                if(chooseEnv_0)
                {
                    float3 wiL_6 = float3(dot(wi_8, T_2), dot(wi_8, B_2), cosi_5);

#line 1338
                    thread Surface_0 _S351 = surf_3;

#line 1338
                    float _S352 = restirMis_0(&_S351, woL_6, wiL_6, plsa_5);

#line 1338
                    thread Surface_0 _S353 = surf_3;

#line 1338
                    Lobes_0 _S354 = evalLobes_0(&_S353, woL_6, wiL_6, kernelContext_39);

#line 1338
                    float3 _S355 = float3((_S352 * _S346.W_0)) ;


                    float3 cd_2 = thr_2 * _S354.diffuse_0 * g_4 * _S355;
                    float3 cs_2 = thr_2 * _S354.specular_1 * g_4 * _S355;
                    if(_S350)
                    {

#line 1344
                        Parts_addLight_0(&st_1->parts_0, depth_3, cls_4, cd_2 + cs_2, cd_2, cs_2);

#line 1343
                    }

                    if(_S243)
                    {
                        float vv_1 = lum_0(cd_2 + cs_2);
                        st_1->visTotal_0 = st_1->visTotal_0 + vv_1;
                        if(_S346.occ_0)
                        {

#line 1349
                            dist_4 = 0.0f;

#line 1349
                        }
                        else
                        {

#line 1349
                            dist_4 = vv_1;

#line 1349
                        }

#line 1349
                        st_1->visLit_0 = st_1->visLit_0 + dist_4;
                        float3 _S356 = cd_2 / float3(cosi_5) ;

#line 1350
                        float3 _S357 = cs_2 / float3(cosi_5) ;

#line 1350
                        float3 _S358 = wi_8;

#line 1350
                        if(_S346.occ_0)
                        {

#line 1350
                            vv_0 = 0.0f;

#line 1350
                        }
                        else
                        {

#line 1350
                            vv_0 = 1.0f;

#line 1350
                        }

#line 1350
                        if(_S346.occ_0)
                        {

#line 1350
                            us_0 = 0.0f;

#line 1350
                        }
                        else
                        {

#line 1350
                            us_0 = cosi_5;

#line 1350
                        }

#line 1350
                        addSlot_0(pixel_8, 3U, _S356, _S357, _S358, vv_0, us_0, kernelContext_39);

#line 1345
                    }

#line 1336
                }

#line 1330
            }

#line 1327
        }

#line 1357
        float chooseLight_0 = Rng_next_0(&rng_4);
        if(reDI_0)
        {

#line 1358
            if(hasEnv_0)
            {

#line 1358
                dist_4 = 1.0f;

#line 1358
            }
            else
            {

#line 1358
                dist_4 = 0.0f;

#line 1358
            }

#line 1358
        }
        else
        {

#line 1358
            dist_4 = _S245;

#line 1358
        }
        if(hasEnv_0)
        {

#line 1359
            chooseEnv_0 = chooseLight_0 < dist_4;

#line 1359
        }
        else
        {

#line 1359
            chooseEnv_0 = false;

#line 1359
        }
        if(emitterCount_0 > 0U)
        {

#line 1360
            _S238 = !chooseEnv_0;

#line 1360
        }
        else
        {

#line 1360
            _S238 = false;

#line 1360
        }

#line 1360
        if(_S238)
        {

#line 1360
            suits_0 = !reDI_0;

#line 1360
        }
        else
        {

#line 1360
            suits_0 = false;

#line 1360
        }

#line 1360
        uint lobeCls_0;

#line 1360
        uint cls_5;

#line 1360
        if(suits_0)
        {
            float _S359 = Rng_next_0(&rng_4);
            float ua_1 = Rng_next_0(&rng_4);
            float ub_1 = Rng_next_0(&rng_4);

            uint _S360 = emitterCount_0 - 1U;

#line 1366
            lobeCls_0 = 0U;

#line 1366
            cls_5 = _S360;
            for(;;)
            {

#line 1367
                if(lobeCls_0 < cls_5)
                {
                }
                else
                {

#line 1367
                    break;
                }
                uint mid_3 = (lobeCls_0 + cls_5) / 2U;
                if(kernelContext_39->emitCdf_0[mid_3] >= _S359)
                {

#line 1370
                    cls_5 = mid_3;

#line 1370
                }
                else
                {

#line 1370
                    lobeCls_0 = mid_3 + 1U;

#line 1370
                }

#line 1367
            }

#line 1375
            uint e_3 = lobeCls_0 * 16U;
            float3 a_8 = float3(kernelContext_39->emitters_0[e_3], kernelContext_39->emitters_0[e_3 + 1U], kernelContext_39->emitters_0[e_3 + 2U]);
            float3 b_3 = float3(kernelContext_39->emitters_0[e_3 + 3U], kernelContext_39->emitters_0[e_3 + 4U], kernelContext_39->emitters_0[e_3 + 5U]);
            float3 c_11 = float3(kernelContext_39->emitters_0[e_3 + 6U], kernelContext_39->emitters_0[e_3 + 7U], kernelContext_39->emitters_0[e_3 + 8U]);
            float su_1 = sqrt(ua_1);

            float3 toL_2 = a_8 * float3((1.0f - su_1))  + b_3 * float3((su_1 * (1.0f - ub_1)))  + c_11 * float3((su_1 * ub_1))  - p_9;
            float d2_2 = dot(toL_2, toL_2);
            float dist_7 = sqrt(d2_2);
            float3 wi_9 = toL_2 / float3(dist_7) ;
            float cosl_1 = abs(dot(normalize(cross(b_3 - a_8, c_11 - a_8)), wi_9));
            float cosi_6 = dot(n_10, wi_9);
            if(cosi_6 > 0.0f)
            {

#line 1387
                ok_0 = cosl_1 > 9.9999997473787516e-06f;

#line 1387
            }
            else
            {

#line 1387
                ok_0 = false;

#line 1387
            }

#line 1387
            if(ok_0)
            {

#line 1387
                uint _S361 = (as_type<uint>((kernelContext_39->emitters_0[e_3 + 14U])));

#line 1387
                uint _S362 = recvMask_0(_S248, kernelContext_39);

#line 1387
                refracted_0 = (_S361 & _S362) != 0U;

#line 1387
            }
            else
            {

#line 1387
                refracted_0 = false;

#line 1387
            }

#line 1387
            if(refracted_0)
            {

#line 1387
                bool _S363 = occluded_0(p_9, wi_9, dist_7 * 0.99900001287460327f, kernelContext_39);


                if(_S243)
                {

#line 1390
                    track_0 = depth_3 == 0U;

#line 1390
                }
                else
                {

#line 1390
                    track_0 = false;

#line 1390
                }
                bool _S364 = !_S363;

#line 1391
                bool _S365;

#line 1391
                if(_S364)
                {

#line 1391
                    _S365 = true;

#line 1391
                }
                else
                {

#line 1391
                    _S365 = track_0;

#line 1391
                }

#line 1391
                if(_S365)
                {
                    float pl_2 = (1.0f - _S245) * kernelContext_39->emitters_0[e_3 + 13U] * d2_2 / (kernelContext_39->emitters_0[e_3 + 12U] * cosl_1);
                    float3 wiL_7 = float3(dot(wi_9, T_2), dot(wi_9, B_2), cosi_6);

#line 1394
                    thread Surface_0 _S366 = surf_3;

#line 1394
                    float _S367 = reflectivePdf_0(&_S366, woL_6, wiL_7);

                    if(nrcCut_0)
                    {

#line 1396
                        vv_0 = 1.0f;

#line 1396
                    }
                    else
                    {

#line 1396
                        float _S368 = pl_2 * pl_2;

#line 1396
                        vv_0 = _S368 / (_S368 + _S367 * _S367);

#line 1396
                    }
                    float3 le_2 = float3(kernelContext_39->emitters_0[e_3 + 9U], kernelContext_39->emitters_0[e_3 + 10U], kernelContext_39->emitters_0[e_3 + 11U]);

#line 1397
                    thread Surface_0 _S369 = surf_3;

#line 1397
                    Lobes_0 _S370 = evalLobes_0(&_S369, woL_6, wiL_7, kernelContext_39);

#line 1397
                    float3 _S371 = float3(pl_2) ;

                    float3 cd_3 = thr_2 * _S370.diffuse_0 * le_2 / _S371 * float3(vv_0) ;
                    float3 cs_3 = thr_2 * _S370.specular_1 * le_2 / _S371 * float3(vv_0) ;
                    if(_S364)
                    {

#line 1401
                        thread Surface_0 _S372 = surf_3;

#line 1401
                        float3 _S373 = evalReflective_0(&_S372, woL_6, wiL_7, kernelContext_39);
                        Parts_addLight_0(&st_1->parts_0, depth_3, cls_4, thr_2 * _S373 * le_2 / _S371 * float3(vv_0) , cd_3, cs_3);

#line 1401
                    }

                    if(track_0)
                    {
                        float vv_2 = lum_0(cd_3 + cs_3);
                        st_1->visTotal_0 = st_1->visTotal_0 + vv_2;
                        if(_S363)
                        {

#line 1407
                            us_0 = 0.0f;

#line 1407
                        }
                        else
                        {

#line 1407
                            us_0 = vv_2;

#line 1407
                        }

#line 1407
                        st_1->visLit_0 = st_1->visLit_0 + us_0;

#line 1407
                        float3 _S374 = float3(cosi_6) ;
                        float3 _S375 = cd_3 / _S374;

#line 1408
                        float3 _S376 = cs_3 / _S374;

#line 1408
                        if(_S363)
                        {

#line 1408
                            _S234 = 0.0f;

#line 1408
                        }
                        else
                        {

#line 1408
                            _S234 = 1.0f;

#line 1408
                        }

#line 1408
                        if(_S363)
                        {

#line 1408
                            _S235 = 0.0f;

#line 1408
                        }
                        else
                        {

#line 1408
                            _S235 = cosi_6;

#line 1408
                        }

#line 1408
                        addSlot_0(pixel_8, 3U, _S375, _S376, wi_9, _S234, _S235, kernelContext_39);

#line 1403
                    }

#line 1391
                }

#line 1387
            }

#line 1360
        }

#line 1414
        if(chooseEnv_0)
        {
            float e1_0 = Rng_next_0(&rng_4);
            float e2_0 = Rng_next_0(&rng_4);
            float e3_1 = Rng_next_0(&rng_4);
            float e4_0 = Rng_next_0(&rng_4);
            thread float pdfE_0;
            thread float3 leE_0;

#line 1421
            float3 _S377 = envSample_0(e1_0, e2_0, e3_1, e4_0, &pdfE_0, &leE_0, kernelContext_39);

            float cosi_7 = dot(n_10, _S377);
            if(pdfE_0 > 0.0f)
            {

#line 1424
                ok_0 = cosi_7 > 0.0f;

#line 1424
            }
            else
            {

#line 1424
                ok_0 = false;

#line 1424
            }

#line 1424
            if(ok_0)
            {

#line 1424
                bool _S378 = occluded_0(p_9, _S377, 1.00000001504746622e+30f, kernelContext_39);


                if(_S243)
                {

#line 1427
                    track_0 = depth_3 == 0U;

#line 1427
                }
                else
                {

#line 1427
                    track_0 = false;

#line 1427
                }
                bool _S379 = !_S378;

#line 1428
                if(_S379)
                {

#line 1428
                    refracted_0 = true;

#line 1428
                }
                else
                {

#line 1428
                    refracted_0 = track_0;

#line 1428
                }

#line 1428
                if(refracted_0)
                {
                    float pl_3 = dist_4 * pdfE_0;
                    float3 wiL_8 = float3(dot(_S377, T_2), dot(_S377, B_2), cosi_7);

#line 1431
                    thread Surface_0 _S380 = surf_3;

#line 1431
                    float _S381 = reflectivePdf_0(&_S380, woL_6, wiL_8);

                    if(nrcCut_0)
                    {

#line 1433
                        vv_0 = 1.0f;

#line 1433
                    }
                    else
                    {

#line 1433
                        float _S382 = pl_3 * pl_3;

#line 1433
                        vv_0 = _S382 / (_S382 + _S381 * _S381);

#line 1433
                    }

#line 1433
                    thread Surface_0 _S383 = surf_3;

#line 1433
                    Lobes_0 _S384 = evalLobes_0(&_S383, woL_6, wiL_8, kernelContext_39);

#line 1433
                    float3 _S385 = float3(pl_3) ;

                    float3 cd_4 = thr_2 * _S384.diffuse_0 * leE_0 / _S385 * float3(vv_0) ;
                    float3 cs_4 = thr_2 * _S384.specular_1 * leE_0 / _S385 * float3(vv_0) ;
                    if(_S379)
                    {

#line 1437
                        thread Surface_0 _S386 = surf_3;

#line 1437
                        float3 _S387 = evalReflective_0(&_S386, woL_6, wiL_8, kernelContext_39);
                        Parts_addLight_0(&st_1->parts_0, depth_3, cls_4, thr_2 * _S387 * leE_0 / _S385 * float3(vv_0) , cd_4, cs_4);

#line 1437
                    }

                    if(track_0)
                    {
                        float vv_3 = lum_0(cd_4 + cs_4);
                        st_1->visTotal_0 = st_1->visTotal_0 + vv_3;
                        if(_S378)
                        {

#line 1443
                            us_0 = 0.0f;

#line 1443
                        }
                        else
                        {

#line 1443
                            us_0 = vv_3;

#line 1443
                        }

#line 1443
                        st_1->visLit_0 = st_1->visLit_0 + us_0;
                        if(kernelContext_39->params_0[int(41)] == 0U)
                        {

#line 1444
                            float3 _S388 = float3(cosi_7) ;
                            float3 _S389 = cd_4 / _S388;

#line 1445
                            float3 _S390 = cs_4 / _S388;

#line 1445
                            if(_S378)
                            {

#line 1445
                                _S234 = 0.0f;

#line 1445
                            }
                            else
                            {

#line 1445
                                _S234 = 1.0f;

#line 1445
                            }

#line 1445
                            if(_S378)
                            {

#line 1445
                                _S235 = 0.0f;

#line 1445
                            }
                            else
                            {

#line 1445
                                _S235 = cosi_7;

#line 1445
                            }

#line 1445
                            addSlot_0(pixel_8, 3U, _S389, _S390, _S377, _S234, _S235, kernelContext_39);

#line 1444
                        }

#line 1439
                    }

#line 1428
                }

#line 1424
            }

#line 1414
        }

#line 1451
        if(nrcCut_0)
        {

            float3 _S391 = thr_2 * albedo_2 * float3((1.0f - fSel_1)) ;

#line 1454
            float3 _S392 = nrcQuery_0(p_9, n_10, kernelContext_39);

#line 1454
            Parts_add_0(&st_1->parts_0, depth_3, cls_4, _S391 * _S392);

#line 1454
            alive_0 = false;

#line 1454
            thr_1 = thr_2;

            break;
        }



        float lobe_0 = Rng_next_0(&rng_4);
        float u1_3 = Rng_next_0(&rng_4);
        float u2_3 = Rng_next_0(&rng_4);
        float u3_1 = Rng_next_0(&rng_4);

#line 1470
        if(((&surf_3)->coat_0) > 0.0f)
        {

#line 1470
            float _S393 = Rng_next_0(&rng_4);

#line 1470
            vv_0 = _S393;

#line 1470
        }
        else
        {

#line 1470
            vv_0 = 1.0f;

#line 1470
        }
        if(((&surf_3)->sheenP_0) > 0.0f)
        {

#line 1471
            float _S394 = Rng_next_0(&rng_4);

#line 1471
            us_0 = _S394;

#line 1471
        }
        else
        {

#line 1471
            us_0 = 1.0f;

#line 1471
        }
        if(vv_0 < ((&surf_3)->coatP_0))
        {
            float3 h_10 = sampleVndf_0(woL_6, (&surf_3)->coatAlpha_0, u1_3, u2_3);
            float woh_0 = dot(woL_6, h_10);
            float3 wiL_9 = float3((2.0f * woh_0))  * h_10 - woL_6;
            float _S395 = wiL_9.z;
            float3 _S396 = float3((fresnelDielectric_0(woh_0, 1.5f) / coatF_0 * G1_0(max(_S395, 0.0f), (&surf_3)->coatAlpha_0))) ;

#line 1478
            ok_0 = _S395 > 0.0f;

#line 1478
            lobeCls_0 = 1U;

#line 1478
            refracted_0 = false;

#line 1478
            wi_6 = wiL_9;

#line 1478
            li_0 = _S396;

#line 1472
        }
        else
        {

#line 1480
            if(us_0 < ((&surf_3)->sheenP_0))
            {

                float3 wiL_10 = cosineLocal_0(u1_3, u2_3);

                float _S397 = wiL_10.z;

#line 1485
                float3 _S398 = (&surf_3)->sheenColor_0 * float3(sheenCore_0(_S310, _S397, normalize(woL_6 + wiL_10).z, (&surf_3)->sheenAlpha_0))  * float3(3.1415927410125732f)  / float3((_S397 * (&surf_3)->sheenP_0)) ;

#line 1485
                ok_0 = true;

#line 1485
                lobeCls_0 = 1U;

#line 1485
                refracted_0 = false;

#line 1485
                wi_6 = wiL_10;

#line 1485
                li_0 = _S398;

#line 1480
            }
            else
            {

#line 1487
                if(lobe_0 < metallic_1)
                {
                    float3 h_11 = sampleVndf_0(woL_6, _S309, u1_3, u2_3);
                    float woh_1 = dot(woL_6, h_11);
                    float3 wiL_11 = float3((2.0f * woh_1))  * h_11 - woL_6;
                    float _S399 = wiL_11.z;

#line 1492
                    bool _S400 = _S399 > 0.0f;
                    float3 _S401 = schlick_0(albedo_2, woh_1);

#line 1493
                    thread Surface_0 _S402 = surf_3;

#line 1493
                    float3 _S403 = multiscatterFactor_0(&_S402, _S310, kernelContext_39);

#line 1493
                    float3 _S404 = _S401 * _S403 * float3(G1_0(max(_S399, 0.0f), _S309)) ;

#line 1493
                    ok_0 = _S400;

#line 1493
                    lobeCls_0 = 1U;

#line 1493
                    refracted_0 = false;

#line 1493
                    wi_6 = wiL_11;

#line 1493
                    li_0 = _S404;

#line 1487
                }
                else
                {

#line 1495
                    if(lobe_0 < (metallic_1 + (1.0f - metallic_1) * transmission_2))
                    {
                        float3 h_12 = sampleVndf_0(woL_6, _S309, u1_3, u2_3);
                        float woh_2 = dot(woL_6, h_12);
                        if(u3_1 < (fresnelDielectric_0(woh_2, eta_2)))
                        {
                            float3 wiL_12 = float3((2.0f * woh_2))  * h_12 - woL_6;
                            float _S405 = wiL_12.z;
                            float3 _S406 = float3((G1_0(max(_S405, 0.0f), _S309) * (&surf_3)->tComp_0)) ;

#line 1503
                            ok_0 = _S405 > 0.0f;

#line 1503
                            lobeCls_0 = 1U;

#line 1503
                            refracted_0 = false;

#line 1503
                            wi_6 = wiL_12;

#line 1503
                            li_0 = _S406;

#line 1499
                        }
                        else
                        {

#line 1507
                            float r_7 = 1.0f / eta_2;
                            float k_7 = 1.0f - r_7 * r_7 * (1.0f - woh_2 * woh_2);

#line 1508
                            float3 _S407 = float3(r_7) ;
                            float3 wiL_13 = - woL_6 * _S407 + float3((r_7 * woh_2 - sqrt(max(k_7, 0.0f))))  * h_12;
                            float _S408 = wiL_13.z;

#line 1510
                            if(_S408 < 0.0f)
                            {

#line 1510
                                ok_0 = k_7 > 0.0f;

#line 1510
                            }
                            else
                            {

#line 1510
                                ok_0 = false;

#line 1510
                            }



                            float3 _S409 = albedo_2 * float3(G1_0(max(- _S408, 0.0f), _S309))  * _S407 * _S407 * float3((&surf_3)->tComp_0) ;

#line 1514
                            lobeCls_0 = 2U;

#line 1514
                            refracted_0 = true;

#line 1514
                            wi_6 = wiL_13;

#line 1514
                            li_0 = _S409;

#line 1499
                        }

#line 1495
                    }
                    else
                    {

#line 1517
                        if(u3_1 < fSel_1)
                        {
                            float3 h_13 = sampleVndf_0(woL_6, _S309, u1_3, u2_3);
                            float woh_3 = dot(woL_6, h_13);
                            float3 wiL_14 = float3((2.0f * woh_3))  * h_13 - woL_6;
                            float _S410 = wiL_14.z;
                            float3 _S411 = float3((fresnelDielectric_0(woh_3, wB_0) / fSel_1 * G1_0(max(_S410, 0.0f), _S309))) ;

#line 1523
                            ok_0 = _S410 > 0.0f;

#line 1523
                            lobeCls_0 = 1U;

#line 1523
                            wi_6 = wiL_14;

#line 1523
                            li_0 = _S411;

#line 1517
                        }
                        else
                        {

#line 1527
                            float3 _S412 = cosineLocal_0(u1_3, u2_3);

#line 1527
                            ok_0 = true;

#line 1527
                            lobeCls_0 = 0U;

#line 1527
                            wi_6 = _S412;

#line 1527
                            li_0 = albedo_2;

#line 1517
                        }

#line 1517
                        refracted_0 = false;

#line 1495
                    }

#line 1487
                }

#line 1480
            }

#line 1472
        }

#line 1531
        if(!ok_0)
        {

#line 1531
            alive_0 = false;

#line 1531
            thr_1 = thr_2;
            break;
        }

#line 1533
        if(depth_3 == 0U)
        {

#line 1533
            cls_5 = lobeCls_0;

#line 1533
        }
        else
        {

#line 1533
            cls_5 = cls_4;

#line 1533
        }

        st_1->misPrev_0 = !refracted_0;
        if(refracted_0)
        {

#line 1536
            _S234 = 0.0f;

#line 1536
        }
        else
        {

#line 1536
            thread Surface_0 _S413 = surf_3;

#line 1536
            float _S414 = reflectivePdf_0(&_S413, woL_6, wi_6);

#line 1536
            _S234 = _S414;

#line 1536
        }

#line 1536
        st_1->qPrev_0 = _S234;
        st_1->prevInst_0 = _S248 + 1U;

        float3 dir_3 = normalize(float3(wi_6.x)  * T_2 + float3(wi_6.y)  * B_2 + float3(wi_6.z)  * n_10);

        float side_0 = dot(dir_3, ng_0);
        if(refracted_0)
        {

#line 1542
            track_0 = side_0 >= 0.0f;

#line 1542
        }
        else
        {

#line 1542
            track_0 = side_0 <= 0.0f;

#line 1542
        }

#line 1542
        if(track_0)
        {

#line 1542
            dir_2 = dir_3;

#line 1542
            cls_4 = cls_5;

#line 1542
            alive_0 = false;

#line 1542
            thr_1 = thr_2;
            break;
        }

#line 1544
        if(side_0 > 0.0f)
        {

#line 1544
            _S235 = 9.9999997473787516e-05f;

#line 1544
        }
        else
        {

#line 1544
            _S235 = -9.9999997473787516e-05f;

#line 1544
        }

#line 1544
        float3 _S415 = hit_1 + ng_0 * float3(_S235) ;
        float3 thr_4 = thr_2 * li_0;

        if(depth_3 >= 2U)
        {
            float pr_0 = clamp(max(thr_4.x, max(thr_4.y, thr_4.z)), 0.05000000074505806f, 0.94999998807907104f);
            float _S416 = Rng_next_0(&rng_4);

#line 1550
            if(_S416 > pr_0)
            {

#line 1550
                org_2 = _S415;

#line 1550
                dir_2 = dir_3;

#line 1550
                cls_4 = cls_5;

#line 1550
                alive_0 = false;

#line 1550
                thr_1 = thr_4;
                break;
            }

#line 1551
            thr_1 = thr_4 / float3(pr_0) ;

#line 1547
        }
        else
        {

#line 1547
            thr_1 = thr_4;

#line 1547
        }

#line 1026
        uint _S417 = once_0 + 1U;

#line 1026
        cls_4 = cls_5;

#line 1026
        dir_2 = dir_3;

#line 1026
        org_2 = _S415;

#line 1026
        chan_2 = chan_1;

#line 1026
        once_0 = _S417;

#line 1026
    }

#line 1555
    st_1->rng_0 = (&rng_4)->state_0;
    st_1->org_0 = org_2;
    st_1->dir_0 = dir_2;
    st_1->thr_0 = thr_1;
    st_1->cls_0 = cls_4;
    st_1->chan_0 = chan_1;
    if(depth_3 == 0U)
    {

#line 1561
        _S233 = st_1->gi_0;

#line 1561
    }
    else
    {

#line 1561
        _S233 = false;

#line 1561
    }

#line 1561
    if(_S233)
    {

        uint so_1 = restirScratch_0(pixel_8);

#line 1564
        k_6 = 0U;
        for(;;)
        {

#line 1565
            if(k_6 < 3U)
            {
            }
            else
            {

#line 1565
                break;
            }
            *(kernelContext_39->restir_0+(so_1 + 15U + k_6)) = thr_1[k_6];
            *(kernelContext_39->restir_0+(so_1 + 18U + k_6)) = (&st_1->parts_0)->total_0[k_6];

#line 1565
            k_6 = k_6 + 1U;

#line 1565
        }

#line 1570
        *(kernelContext_39->restir_0+(so_1 + 21U)) = st_1->qPrev_0;

#line 1561
    }

#line 1572
    return alive_0;
}


#line 1596
float3 giFinish_0(float3 pathTotal_0, uint pixel_9, KernelContext_0 thread* kernelContext_40)
{
    uint co_3 = restirBase_0(pixel_9, kernelContext_40->params_0[int(6)] & 1U);
    uint so_2 = restirScratch_0(pixel_9);
    float wsum_5 = *(kernelContext_40->restir_0+so_2);
    float m_1 = *(kernelContext_40->restir_0+(so_2 + 1U)) + 1.0f;
    float _S418 = *(kernelContext_40->restir_0+(so_2 + 2U));
    float3 _S419 = float3(*(kernelContext_40->restir_0+(so_2 + 3U)), *(kernelContext_40->restir_0+(so_2 + 4U)), *(kernelContext_40->restir_0+(so_2 + 5U)));
    float3 _S420 = float3(*(kernelContext_40->restir_0+(so_2 + 6U)), *(kernelContext_40->restir_0+(so_2 + 7U)), *(kernelContext_40->restir_0+(so_2 + 8U)));
    float3 _S421 = float3(*(kernelContext_40->restir_0+(so_2 + 9U)), *(kernelContext_40->restir_0+(so_2 + 10U)), *(kernelContext_40->restir_0+(so_2 + 11U)));
    float3 _S422 = float3(*(kernelContext_40->restir_0+(so_2 + 12U)), *(kernelContext_40->restir_0+(so_2 + 13U)), *(kernelContext_40->restir_0+(so_2 + 14U)));
    float _S423 = *(kernelContext_40->restir_0+(so_2 + 15U));

#line 1607
    float _S424 = *(kernelContext_40->restir_0+(so_2 + 16U));

#line 1607
    float _S425 = *(kernelContext_40->restir_0+(so_2 + 17U));
    float3 d0_0 = float3(*(kernelContext_40->restir_0+(so_2 + 18U)), *(kernelContext_40->restir_0+(so_2 + 19U)), *(kernelContext_40->restir_0+(so_2 + 20U)));
    float qPrev_1 = *(kernelContext_40->restir_0+(so_2 + 21U));

#line 1609
    bool own_0;
    if((as_type<uint>((*(kernelContext_40->restir_0+(so_2 + 22U))))) != 0U)
    {

#line 1610
        own_0 = qPrev_1 > 0.0f;

#line 1610
    }
    else
    {

#line 1610
        own_0 = false;

#line 1610
    }
    float3 giTotal_0 = pathTotal_0 - d0_0;

#line 1611
    float pSel_2;

#line 1611
    float wsum_6;

#line 1611
    float W_1;

#line 1611
    float3 cSel_2;

#line 1611
    float3 xSel_2;

#line 1611
    float3 nSel_2;

#line 1611
    float3 lSel_2;

#line 1611
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
            (&r_8)->state_0 = pcg_0(pixel_9 ^ (pcg_0(kernelContext_40->params_0[int(6)] * 2246822507U + 4660U + kernelContext_40->params_0[int(43)] * 1759714724U)));
            float _S426 = Rng_next_0(&r_8);

#line 1623
            if((_S426 * wsum_7) < wOwn_0)
            {


                float3 _S427 = float3(*(kernelContext_40->restir_0+(co_3 + 16U)), *(kernelContext_40->restir_0+(co_3 + 17U)), *(kernelContext_40->restir_0+(co_3 + 18U)));
                float3 _S428 = float3(*(kernelContext_40->restir_0+(co_3 + 19U)), *(kernelContext_40->restir_0+(co_3 + 20U)), *(kernelContext_40->restir_0+(co_3 + 21U)));
                if(_S423 > 9.99999997475242708e-07f)
                {

#line 1629
                    pSel_2 = giTotal_0.x / _S423;

#line 1629
                }
                else
                {

#line 1629
                    pSel_2 = 0.0f;

#line 1629
                }

#line 1629
                if(_S424 > 9.99999997475242708e-07f)
                {

#line 1629
                    wsum_6 = giTotal_0.y / _S424;

#line 1629
                }
                else
                {

#line 1629
                    wsum_6 = 0.0f;

#line 1629
                }

#line 1629
                if(_S425 > 9.99999997475242708e-07f)
                {

#line 1629
                    W_1 = giTotal_0.z / _S425;

#line 1629
                }
                else
                {

#line 1629
                    W_1 = 0.0f;

#line 1629
                }

#line 1629
                float3 _S429 = float3(pSel_2, wsum_6, W_1);

#line 1629
                pSel_2 = pOwn_0;

#line 1629
                cSel_2 = cOwn_0;

#line 1629
                xSel_2 = _S427;

#line 1629
                nSel_2 = _S428;

#line 1629
                lSel_2 = _S429;

#line 1623
            }
            else
            {

#line 1623
                pSel_2 = _S418;

#line 1623
                cSel_2 = _S419;

#line 1623
                xSel_2 = _S420;

#line 1623
                nSel_2 = _S421;

#line 1623
                lSel_2 = _S422;

#line 1623
            }

#line 1623
            wsum_6 = wsum_7;

#line 1617
        }
        else
        {

#line 1617
            pSel_2 = _S418;

#line 1617
            cSel_2 = _S419;

#line 1617
            xSel_2 = _S420;

#line 1617
            nSel_2 = _S421;

#line 1617
            lSel_2 = _S422;

#line 1617
            wsum_6 = wsum_5;

#line 1617
        }

#line 1617
        result_0 = d0_0;

#line 1613
    }
    else
    {

#line 1634
        float3 result_1 = d0_0 + giTotal_0;

#line 1634
        pSel_2 = _S418;

#line 1634
        cSel_2 = _S419;

#line 1634
        xSel_2 = _S420;

#line 1634
        nSel_2 = _S421;

#line 1634
        lSel_2 = _S422;

#line 1634
        wsum_6 = wsum_5;

#line 1634
        result_0 = result_1;

#line 1613
    }

#line 1635
    bool _S430 = pSel_2 > 0.0f;

#line 1635
    if(_S430)
    {

#line 1635
        W_1 = wsum_6 / (m_1 * pSel_2);

#line 1635
    }
    else
    {

#line 1635
        W_1 = 0.0f;

#line 1635
    }
    float3 result_2 = result_0 + cSel_2 * float3(W_1) ;

#line 1636
    uint k_8 = 0U;
    for(;;)
    {

#line 1637
        if(k_8 < 3U)
        {
        }
        else
        {

#line 1637
            break;
        }
        *(kernelContext_40->restir_0+(co_3 + 16U + k_8)) = xSel_2[k_8];
        *(kernelContext_40->restir_0+(co_3 + 19U + k_8)) = nSel_2[k_8];
        *(kernelContext_40->restir_0+(co_3 + 22U + k_8)) = lSel_2[k_8];

#line 1637
        k_8 = k_8 + 1U;

#line 1637
    }

#line 1643
    *(kernelContext_40->restir_0+(co_3 + 25U)) = W_1;
    *(kernelContext_40->restir_0+(co_3 + 26U)) = m_1;
    float device* _S431 = kernelContext_40->restir_0+(co_3 + 27U);

#line 1645
    if(_S430)
    {

#line 1645
        k_8 = 1U;

#line 1645
    }
    else
    {

#line 1645
        k_8 = 0U;

#line 1645
    }

#line 1645
    *_S431 = (as_type<float>((k_8)));
    return result_2;
}


void finishPath_0(const PathState_0 thread* st_2, uint pixel_10, KernelContext_0 thread* kernelContext_41)
{

#line 1650
    Parts_0 _S432 = st_2->parts_0;

#line 1650
    float _S433 = st_2->visLit_0;

#line 1650
    float _S434 = st_2->visTotal_0;

#line 1650
    float3 _S435 = (&st_2->parts_0)->total_0;

#line 1650
    float3 radiance_0;

#line 1656
    if(st_2->gi_0)
    {


        if((st_2->chan_0) >= int(0))
        {

#line 1661
            *(kernelContext_41->restir_0+(restirScratch_0(pixel_10) + 22U)) = (as_type<float>((0U)));

#line 1660
        }

#line 1660
        float3 _S436 = giFinish_0(_S435, pixel_10, kernelContext_41);

#line 1660
        radiance_0 = _S436;

#line 1656
    }
    else
    {

#line 1656
        radiance_0 = _S435;

#line 1656
    }

#line 1656
    bool _S437;

#line 1664
    if(any(isnan(radiance_0)))
    {

#line 1664
        _S437 = true;

#line 1664
    }
    else
    {

#line 1664
        _S437 = any(isinf(radiance_0));

#line 1664
    }

#line 1664
    Parts_0 parts_1;

#line 1664
    float visLit_1;

#line 1664
    float visTotal_1;

#line 1664
    if(_S437)
    {
        float3 _S438 = float3(0.0f) ;

#line 1666
        radiance_0 = _S438;

#line 1666
        (&parts_1)->total_0 = _S438;

#line 1666
        (&parts_1)->directDiffuse_0 = _S438;

#line 1666
        (&parts_1)->indirectDiffuse_0 = _S438;

#line 1666
        (&parts_1)->specular_0 = _S438;

#line 1666
        (&parts_1)->transmission_0 = _S438;

#line 1666
        (&parts_1)->emission_0 = _S438;

#line 1666
        visLit_1 = 0.0f;

#line 1666
        visTotal_1 = 0.0f;

#line 1664
    }
    else
    {

#line 1664
        parts_1 = _S432;

#line 1664
        visLit_1 = _S433;

#line 1664
        visTotal_1 = _S434;

#line 1664
    }

#line 1672
    uint o_9 = 3U * pixel_10;
    float device* _S439 = kernelContext_41->accum_0+o_9;

#line 1673
    *_S439 = *_S439 + radiance_0.x;
    uint _S440 = o_9 + 1U;

#line 1674
    float device* _S441 = kernelContext_41->accum_0+_S440;

#line 1674
    *_S441 = *_S441 + radiance_0.y;
    uint _S442 = o_9 + 2U;

#line 1675
    float device* _S443 = kernelContext_41->accum_0+_S442;

#line 1675
    *_S443 = *_S443 + radiance_0.z;
    if(kernelContext_41->params_0[int(32)] != 0U)
    {
        float l_3 = lum_0(radiance_0);
        float device* _S444 = kernelContext_41->pixelStats_0+o_9;

#line 1679
        *_S444 = *_S444 + 1.0f;
        float device* _S445 = kernelContext_41->pixelStats_0+_S440;

#line 1680
        *_S445 = *_S445 + l_3;
        float device* _S446 = kernelContext_41->pixelStats_0+_S442;

#line 1681
        *_S446 = *_S446 + l_3 * l_3;

#line 1676
    }

#line 1684
    if(kernelContext_41->params_0[int(28)] != 0U)
    {
        uint lo_3 = 65U * pixel_10;
        array<float3, int(5)> _S447 = { { parts_1.directDiffuse_0, parts_1.indirectDiffuse_0, parts_1.specular_0, parts_1.transmission_0, parts_1.emission_0 } };

#line 1687
        uint k_9 = 0U;
        for(;;)
        {

#line 1688
            if(k_9 < 5U)
            {
            }
            else
            {

#line 1688
                break;
            }
            uint _S448 = lo_3 + 3U * k_9;

#line 1690
            float device* _S449 = kernelContext_41->lighting_0+_S448;

#line 1690
            *_S449 = *_S449 + _S447[k_9].x;
            float device* _S450 = kernelContext_41->lighting_0+(_S448 + 1U);

#line 1691
            *_S450 = *_S450 + _S447[k_9].y;
            float device* _S451 = kernelContext_41->lighting_0+(_S448 + 2U);

#line 1692
            *_S451 = *_S451 + _S447[k_9].z;

#line 1688
            k_9 = k_9 + 1U;

#line 1688
        }

#line 1694
        float device* _S452 = kernelContext_41->lighting_0+(lo_3 + 15U);

#line 1694
        *_S452 = *_S452 + visLit_1;
        float device* _S453 = kernelContext_41->lighting_0+(lo_3 + 16U);

#line 1695
        *_S453 = *_S453 + visTotal_1;

#line 1684
    }

#line 1697
    return;
}


#line 9 "shaders/pathtrace.slang"
[[kernel]] void pathtrace(uint3 tid_0 [[thread_position_in_grid]], uint device* params_1 [[buffer(6)]], float device* pixelStats_1 [[buffer(18)]], metal::raytracing::acceleration_structure<metal::raytracing::instancing> scene_1 [[buffer(0)]], float device* restir_2 [[buffer(19)]], float device* envPixels_1 [[buffer(10)]], uint device* instances_1 [[buffer(3)]], uint device* indices_1 [[buffer(2)]], float device* positions_1 [[buffer(1)]], float device* materials_1 [[buffer(4)]], float device* uvs_1 [[buffer(13)]], uint device* texInfo_1 [[buffer(15)]], float device* texels_1 [[buffer(14)]], float device* vnormals_1 [[buffer(16)]], uint device* lights_1 [[buffer(5)]], float device* emitters_1 [[buffer(8)]], float device* lighting_1 [[buffer(17)]], float device* emitCdf_1 [[buffer(9)]], float device* envMarginal_1 [[buffer(11)]], float device* envCond_1 [[buffer(12)]], float device* accum_1 [[buffer(7)]])
{

#line 9
    thread KernelContext_0 kernelContext_42;

#line 9
    (&kernelContext_42)->params_0 = params_1;

#line 9
    (&kernelContext_42)->pixelStats_0 = pixelStats_1;

#line 9
    (&kernelContext_42)->scene_0 = scene_1;

#line 9
    (&kernelContext_42)->restir_0 = restir_2;

#line 9
    (&kernelContext_42)->envPixels_0 = envPixels_1;

#line 9
    (&kernelContext_42)->instances_0 = instances_1;

#line 9
    (&kernelContext_42)->indices_0 = indices_1;

#line 9
    (&kernelContext_42)->positions_0 = positions_1;

#line 9
    (&kernelContext_42)->materials_0 = materials_1;

#line 9
    (&kernelContext_42)->uvs_0 = uvs_1;

#line 9
    (&kernelContext_42)->texInfo_0 = texInfo_1;

#line 9
    (&kernelContext_42)->texels_0 = texels_1;

#line 9
    (&kernelContext_42)->vnormals_0 = vnormals_1;

#line 9
    (&kernelContext_42)->lights_0 = lights_1;

#line 9
    (&kernelContext_42)->emitters_0 = emitters_1;

#line 9
    (&kernelContext_42)->lighting_0 = lighting_1;

#line 9
    (&kernelContext_42)->emitCdf_0 = emitCdf_1;

#line 9
    (&kernelContext_42)->envMarginal_0 = envMarginal_1;

#line 9
    (&kernelContext_42)->envCond_0 = envCond_1;

#line 9
    (&kernelContext_42)->accum_0 = accum_1;

    uint _S454 = tid_0.x;

#line 11
    bool _S455;

#line 11
    if(_S454 >= params_1[int(0)])
    {

#line 11
        _S455 = true;

#line 11
    }
    else
    {

#line 11
        _S455 = (tid_0.y) >= ((&kernelContext_42)->params_0)[int(1)];

#line 11
    }

#line 11
    if(_S455)
    {

#line 12
        return;
    }

#line 13
    uint _S456 = tid_0.y;

#line 13
    uint _S457 = _S456 * (&kernelContext_42)->params_0[int(0)] + _S454;

#line 13
    uint k_10 = 0U;
    for(;;)
    {

#line 14
        if(k_10 < ((&kernelContext_42)->params_0)[int(35)])
        {
        }
        else
        {

#line 14
            break;
        }
        if((&kernelContext_42)->params_0[int(32)] != 0U)
        {

#line 16
            bool _S458 = pixelActive_0(_S457, &kernelContext_42);

#line 16
            _S455 = !_S458;

#line 16
        }
        else
        {

#line 16
            _S455 = false;

#line 16
        }

#line 16
        if(_S455)
        {

#line 17
            return;
        }

#line 17
        PathState_0 _S459 = generatePathFor_0(_S454, _S456, (&kernelContext_42)->params_0[int(6)] + k_10, &kernelContext_42);
        thread PathState_0 st_3 = _S459;

#line 18
        uint depth_4 = 0U;
        for(;;)
        {

#line 19
            if(depth_4 < ((&kernelContext_42)->params_0)[int(7)])
            {
            }
            else
            {

#line 19
                break;
            }

#line 19
            Hit_0 _S460 = traceClosest_0((&st_3)->org_0, (&st_3)->dir_0, &kernelContext_42);

#line 19
            thread Hit_0 _S461 = _S460;

#line 19
            bool _S462 = shadePath_0(&st_3, &_S461, depth_4, _S457, &kernelContext_42);

            if(!_S462)
            {

#line 22
                break;
            }

#line 19
            depth_4 = depth_4 + 1U;

#line 19
        }

#line 19
        thread PathState_0 _S463 = st_3;

#line 19
        finishPath_0(&_S463, _S457, &kernelContext_42);

#line 14
        k_10 = k_10 + 1U;

#line 14
    }

#line 26
    return;
}

