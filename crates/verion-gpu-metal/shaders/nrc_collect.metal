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


#line 72 "shaders/include/pt_core.slang"
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
    uint _S1 = pcg_0(this_0->state_0);

#line 84
    this_0->state_0 = _S1;
    return float(_S1 >> 8U) * 5.9604644775390625e-08f;
}


#line 58
struct KernelContext_0
{
    uint device* params_0;
    float device* nrcSamples_0;
    metal::raytracing::acceleration_structure<metal::raytracing::instancing> scene_0;
    uint device* instances_0;
    uint device* indices_0;
    float device* positions_0;
    float device* vnormals_0;
    float device* materials_0;
    float device* uvs_0;
    uint device* texInfo_0;
    float device* texels_0;
    uint device* lights_0;
    float device* emitCdf_0;
    float device* emitters_0;
    float device* envMarginal_0;
    float device* envCond_0;
    float device* envPixels_0;
    float device* restir_0;
};


#line 89
float pf_0(uint i_0, KernelContext_0 thread* kernelContext_0)
{

#line 89
    return (as_type<float>((kernelContext_0->params_0[i_0])));
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
PathState_0 generatePathFor_0(uint px_0, uint py_0, uint sample_0, KernelContext_0 thread* kernelContext_1)
{
    uint w_1 = kernelContext_1->params_0[int(0)];
    uint h_0 = kernelContext_1->params_0[int(1)];

    thread Rng_0 rng_1;
    (&rng_1)->state_0 = pcg_0((py_0 * w_1 + px_0) ^ (pcg_0(sample_0 * 2654435769U + 2135587861U + kernelContext_1->params_0[int(43)] * 1759714724U)));

#line 660
    float _S2 = pf_0(2U, kernelContext_1);

    float _S3 = float(w_1);

#line 662
    float _S4 = float(h_0);

#line 662
    float aspect_0 = _S3 / _S4;
    float _S5 = float(px_0);

#line 663
    float _S6 = Rng_next_0(&rng_1);

#line 663
    float _S7 = 2.0f * (_S5 + _S6) / _S3 - 1.0f;

#line 663
    float _S8 = pf_0(39U, kernelContext_1);

#line 663
    float u_0 = (_S7 + _S8) * aspect_0 * _S2;
    float _S9 = float(py_0);

#line 664
    float _S10 = Rng_next_0(&rng_1);

#line 664
    float _S11 = 1.0f - 2.0f * (_S9 + _S10) / _S4;

#line 664
    float _S12 = pf_0(40U, kernelContext_1);
    float3 _S13 = float3(u_0, (_S11 + _S12) * _S2, -1.0f);

#line 665
    float _S14 = pf_0(4U, kernelContext_1);

#line 665
    float3 focal_0 = _S13 * float3(_S14) ;

#line 665
    float _S15 = pf_0(3U, kernelContext_1);
    float _S16 = Rng_next_0(&rng_1);

#line 666
    float lensR_0 = _S15 * sqrt(_S16);
    float _S17 = Rng_next_0(&rng_1);

#line 667
    float lensA_0 = 6.2831854820251465f * _S17;
    float _S18 = lensR_0 * cos(lensA_0);

#line 668
    float _S19 = lensR_0 * sin(lensA_0);
    float3 _S20 = normalize(focal_0 - float3(_S18, _S19, 0.0f));
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
        uint _S21 = 4U * r_0;

#line 673
        uint _S22 = 8U + _S21;

#line 673
        uint _S23 = 9U + _S21;

#line 673
        uint _S24 = 10U + _S21;

#line 673
        (&s_1)->org_0[r_0] = (as_type<float>((kernelContext_1->params_0[_S22]))) * _S18 + (as_type<float>((kernelContext_1->params_0[_S23]))) * _S19 + (as_type<float>((kernelContext_1->params_0[_S24]))) * 0.0f + (as_type<float>((kernelContext_1->params_0[11U + _S21])));
        (&s_1)->dir_0[r_0] = (as_type<float>((kernelContext_1->params_0[_S22]))) * _S20.x + (as_type<float>((kernelContext_1->params_0[_S23]))) * _S20.y + (as_type<float>((kernelContext_1->params_0[_S24]))) * _S20.z;

#line 671
        r_0 = r_0 + 1U;

#line 671
    }

#line 676
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
    float3 _S25 = float3(0.0f) ;

#line 689
    (&(&s_1)->parts_0)->total_0 = _S25;

#line 689
    (&(&s_1)->parts_0)->directDiffuse_0 = _S25;

#line 689
    (&(&s_1)->parts_0)->indirectDiffuse_0 = _S25;

#line 689
    (&(&s_1)->parts_0)->specular_0 = _S25;

#line 689
    (&(&s_1)->parts_0)->transmission_0 = _S25;

#line 689
    (&(&s_1)->parts_0)->emission_0 = _S25;
    return s_1;
}


#line 645
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


#line 693 "shaders/include/pt_core.slang"
Hit_0 traceClosest_0(float3 org_1, float3 dir_1, KernelContext_0 thread* kernelContext_2)
{
    thread RayDesc_0 ray_0;
    (&ray_0)->Origin_0 = org_1;
    (&ray_0)->Direction_0 = dir_1;
    (&ray_0)->TMin_0 = 0.0f;
    (&ray_0)->TMax_0 = 1.00000001504746622e+30f;
    thread raytracing::intersection_query<raytracing::triangle_data, raytracing::instancing> q_0;
    (&q_0)->reset({ (ray_0.Origin_0), (ray_0.Direction_0), (ray_0.TMin_0), (ray_0.TMax_0) }, (kernelContext_2->scene_0), (255U), _slang_ray_flags_to_intersection_params((1U)));
    for(;;)
    {

#line 702
        bool _S26 = ((&q_0)->next());

#line 702
        if(_S26)
        {
        }
        else
        {

#line 702
            break;
        }

#line 702
    }
    thread Hit_0 h_1;
    uint _S27 = (_slang_committed_intersection_type_to_uint((&q_0)->get_committed_intersection_type()));

#line 704
    bool _S28 = _S27 == 1U;

#line 704
    (&h_1)->hit_0 = _S28;

#line 704
    uint _S29;
    if(_S28)
    {

#line 705
        uint _S30 = ((&q_0)->get_committed_instance_id());

#line 705
        _S29 = _S30;

#line 705
    }
    else
    {

#line 705
        _S29 = 0U;

#line 705
    }

#line 705
    (&h_1)->inst_0 = _S29;
    if((&h_1)->hit_0)
    {

#line 706
        uint _S31 = ((&q_0)->get_committed_primitive_id());

#line 706
        _S29 = _S31;

#line 706
    }
    else
    {

#line 706
        _S29 = 0U;

#line 706
    }

#line 706
    (&h_1)->prim_0 = _S29;

#line 706
    float _S32;
    if((&h_1)->hit_0)
    {

#line 707
        float _S33 = ((&q_0)->get_committed_distance());

#line 707
        _S32 = _S33;

#line 707
    }
    else
    {

#line 707
        _S32 = 0.0f;

#line 707
    }

#line 707
    (&h_1)->t_0 = _S32;
    return h_1;
}


#line 97
float3 vertexPos_0(uint v_1, KernelContext_0 thread* kernelContext_3)
{

#line 97
    uint _S34 = 3U * v_1;

#line 97
    return float3(kernelContext_3->positions_0[_S34], kernelContext_3->positions_0[_S34 + 1U], kernelContext_3->positions_0[_S34 + 2U]);
}


#line 99
float3 transformPoint_0(uint base_0, float3 p_0, KernelContext_0 thread* kernelContext_4)
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
        uint o_0 = base_0 + 4U * row_0;
        r_1[row_0] = (as_type<float>((kernelContext_4->instances_0[o_0]))) * p_0.x + (as_type<float>((kernelContext_4->instances_0[o_0 + 1U]))) * p_0.y + (as_type<float>((kernelContext_4->instances_0[o_0 + 2U]))) * p_0.z + (as_type<float>((kernelContext_4->instances_0[o_0 + 3U])));

#line 102
        row_0 = row_0 + 1U;

#line 102
    }

#line 107
    return r_1;
}


#line 122
float3 vertexNormal_0(uint v_2, KernelContext_0 thread* kernelContext_5)
{

#line 122
    uint _S35 = 3U * v_2;

#line 122
    return float3(kernelContext_5->vnormals_0[_S35], kernelContext_5->vnormals_0[_S35 + 1U], kernelContext_5->vnormals_0[_S35 + 2U]);
}


#line 112
float3 transformNormal_0(uint base_1, float3 n_0, KernelContext_0 thread* kernelContext_6)
{
    float3 r0_0 = float3((as_type<float>((kernelContext_6->instances_0[base_1]))), (as_type<float>((kernelContext_6->instances_0[base_1 + 1U]))), (as_type<float>((kernelContext_6->instances_0[base_1 + 2U]))));
    float3 r1_0 = float3((as_type<float>((kernelContext_6->instances_0[base_1 + 4U]))), (as_type<float>((kernelContext_6->instances_0[base_1 + 5U]))), (as_type<float>((kernelContext_6->instances_0[base_1 + 6U]))));
    float3 r2_0 = float3((as_type<float>((kernelContext_6->instances_0[base_1 + 8U]))), (as_type<float>((kernelContext_6->instances_0[base_1 + 9U]))), (as_type<float>((kernelContext_6->instances_0[base_1 + 10U]))));
    float3 c0_0 = cross(r1_0, r2_0);

#line 117
    float s_2;
    if((dot(r0_0, c0_0)) < 0.0f)
    {

#line 118
        s_2 = -1.0f;

#line 118
    }
    else
    {

#line 118
        s_2 = 1.0f;

#line 118
    }
    return float3(s_2)  * float3(dot(c0_0, n_0), dot(cross(r2_0, r0_0), n_0), dot(cross(r0_0, r1_0), n_0));
}


#line 318
float3 texelAt_0(uint base_2, uint w_2, uint h_2, int x_1, int y_0, KernelContext_0 thread* kernelContext_7)
{
    int _S36 = int(w_2);

#line 320
    int _S37 = x_1 % _S36;

#line 320
    int _S38 = (_S37 + _S36) % _S36;

#line 320
    uint xi_0 = uint(_S38);
    int _S39 = int(h_2);

#line 321
    int _S40 = y_0 % _S39;

#line 321
    int _S41 = (_S40 + _S39) % _S39;
    uint o_1 = 3U * (base_2 + uint(_S41) * w_2 + xi_0);
    return float3(kernelContext_7->texels_0[o_1], kernelContext_7->texels_0[o_1 + 1U], kernelContext_7->texels_0[o_1 + 2U]);
}

float3 bilinear_0(uint base_3, uint w_3, uint h_3, float2 uv_0, KernelContext_0 thread* kernelContext_8)
{
    float fx_0 = uv_0.x * float(w_3) - 0.5f;
    float fy_0 = uv_0.y * float(h_3) - 0.5f;
    int x0_0 = int(floor(fx_0));
    int y0_0 = int(floor(fy_0));
    float tx_0 = fx_0 - float(x0_0);
    float ty_0 = fy_0 - float(y0_0);

#line 333
    float3 _S42 = texelAt_0(base_3, w_3, h_3, x0_0, y0_0, kernelContext_8);
    int _S43 = x0_0 + int(1);

#line 334
    float3 _S44 = texelAt_0(base_3, w_3, h_3, _S43, y0_0, kernelContext_8);

#line 334
    float3 _S45 = float3(tx_0) ;

#line 334
    float3 a_0 = mix(_S42, _S44, _S45);
    int _S46 = y0_0 + int(1);

#line 335
    float3 _S47 = texelAt_0(base_3, w_3, h_3, x0_0, _S46, kernelContext_8);

#line 335
    float3 _S48 = texelAt_0(base_3, w_3, h_3, _S43, _S46, kernelContext_8);
    return mix(a_0, mix(_S47, _S48, _S45), float3(ty_0) );
}


float3 sampleTexture_0(uint tex_0, float2 uv_1, float footprint_0, KernelContext_0 thread* kernelContext_9)
{
    uint ti_0 = tex_0 * 4U;
    uint base_4 = kernelContext_9->texInfo_0[ti_0];
    uint w_4 = kernelContext_9->texInfo_0[ti_0 + 1U];
    uint h_4 = kernelContext_9->texInfo_0[ti_0 + 2U];
    uint levels_0 = kernelContext_9->texInfo_0[ti_0 + 3U];
    float lod_0 = clamp(log2(max(footprint_0 * float(max(w_4, h_4)), 9.99999993922529029e-09f)), 0.0f, float(levels_0 - 1U));
    uint l0_0 = uint(floor(lod_0));
    float t_1 = lod_0 - float(l0_0);

#line 349
    uint lw_0 = w_4;

#line 349
    uint lh_0 = h_4;

#line 349
    uint k_0 = 0U;

#line 349
    uint off_0 = base_4;



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
        uint _S49 = max(lw_0 / 2U, 1U);
        uint _S50 = max(lh_0 / 2U, 1U);

#line 353
        uint _S51 = k_0 + 1U;

#line 353
        lw_0 = _S49;

#line 353
        lh_0 = _S50;

#line 353
        k_0 = _S51;

#line 353
        off_0 = off_1;

#line 353
    }

#line 353
    float3 _S52 = bilinear_0(off_0, lw_0, lh_0, uv_1, kernelContext_9);

#line 353
    bool _S53;

#line 360
    if((l0_0 + 1U) >= levels_0)
    {

#line 360
        _S53 = true;

#line 360
    }
    else
    {

#line 360
        _S53 = t_1 <= 0.0f;

#line 360
    }

#line 360
    if(_S53)
    {

#line 361
        return _S52;
    }

#line 361
    float3 _S54 = bilinear_0(off_0 + lw_0 * lh_0, max(lw_0 / 2U, 1U), max(lh_0 / 2U, 1U), uv_1, kernelContext_9);


    return mix(_S52, _S54, float3(t_1) );
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
    float _S55 = eta_0 * cost_0;

#line 159
    float rs_0 = (cosi_0 - _S55) / (cosi_0 + _S55);
    float _S56 = eta_0 * cosi_0;

#line 160
    float rp_0 = (_S56 - cost_0) / (_S56 + cost_0);
    return 0.5f * (rs_0 * rs_0 + rp_0 * rp_0);
}


#line 16 "shaders/nrc_collect.slang"
struct NrcVertex_0
{
    float3 p_1;
    float3 n_1;
    float3 albedo_0;
    uint inst_1;
    bool eligible_0;
};

NrcVertex_0 nrcVertex_0(const Hit_0 thread* hq_0, float3 org_2, float3 dir_2, KernelContext_0 thread* kernelContext_10)
{

#line 25
    uint _S57 = hq_0->inst_0;

    uint inst_2 = hq_0->inst_0 * 16U;
    uint tri_0 = kernelContext_10->instances_0[inst_2 + 1U] + 3U * hq_0->prim_0;
    uint vo_0 = kernelContext_10->instances_0[inst_2];
    uint _S58 = inst_2 + 4U;

#line 30
    float3 _S59 = vertexPos_0(kernelContext_10->indices_0[tri_0] + vo_0, kernelContext_10);

#line 30
    float3 _S60 = transformPoint_0(_S58, _S59, kernelContext_10);
    uint _S61 = tri_0 + 1U;

#line 31
    float3 _S62 = vertexPos_0(kernelContext_10->indices_0[_S61] + vo_0, kernelContext_10);

#line 31
    float3 _S63 = transformPoint_0(_S58, _S62, kernelContext_10);
    uint _S64 = tri_0 + 2U;

#line 32
    float3 _S65 = vertexPos_0(kernelContext_10->indices_0[_S64] + vo_0, kernelContext_10);

#line 32
    float3 _S66 = transformPoint_0(_S58, _S65, kernelContext_10);
    float3 _S67 = _S63 - _S60;

#line 33
    float3 _S68 = _S66 - _S60;

#line 33
    float3 nOut_0 = normalize(cross(_S67, _S68));
    float3 wo_0 = - dir_2;
    bool outside_0 = (dot(nOut_0, wo_0)) > 0.0f;

#line 35
    float3 ng_0;
    if(outside_0)
    {

#line 36
        ng_0 = nOut_0;

#line 36
    }
    else
    {

#line 36
        ng_0 = - nOut_0;

#line 36
    }
    float3 hit_1 = org_2 + dir_2 * float3(hq_0->t_0) ;


    float3 e3_0 = hit_1 - _S60;
    float d11_0 = dot(_S67, _S67);
    float d12_0 = dot(_S67, _S68);
    float d22_0 = dot(_S68, _S68);
    float _S69 = max(d11_0 * d22_0 - d12_0 * d12_0, 9.99999968265522539e-21f);
    float _S70 = dot(e3_0, _S67);

#line 45
    float _S71 = dot(e3_0, _S68);

#line 45
    float b1_0 = (d22_0 * _S70 - d12_0 * _S71) / _S69;
    float b2_0 = (d11_0 * _S71 - d12_0 * _S70) / _S69;
    float _S72 = 1.0f - b1_0 - b2_0;

#line 47
    float3 _S73 = vertexNormal_0(kernelContext_10->indices_0[tri_0] + vo_0, kernelContext_10);

#line 47
    float3 _S74 = float3(_S72)  * _S73;

#line 47
    float3 _S75 = vertexNormal_0(kernelContext_10->indices_0[_S61] + vo_0, kernelContext_10);

#line 47
    float3 _S76 = _S74 + float3(b1_0)  * _S75;

#line 47
    float3 _S77 = vertexNormal_0(kernelContext_10->indices_0[_S64] + vo_0, kernelContext_10);

#line 47
    float3 nsObj_0 = _S76 + float3(b2_0)  * _S77;

#line 47
    float3 ns_0;

    if((dot(nsObj_0, nsObj_0)) > 9.999999960041972e-13f)
    {

#line 49
        float3 _S78 = transformNormal_0(_S58, nsObj_0, kernelContext_10);

        float3 ns_1 = normalize(_S78);
        if((dot(ns_1, nOut_0)) < 0.0f)
        {

#line 52
            ns_0 = - ns_1;

#line 52
        }
        else
        {

#line 52
            ns_0 = ns_1;

#line 52
        }

#line 49
    }
    else
    {

#line 49
        ns_0 = nOut_0;

#line 49
    }

#line 49
    float3 n_2;

#line 55
    if(outside_0)
    {

#line 55
        n_2 = ns_0;

#line 55
    }
    else
    {

#line 55
        n_2 = - ns_0;

#line 55
    }
    uint mi_0 = kernelContext_10->instances_0[inst_2 + 2U] * 24U;
    float3 albedo_1 = float3(kernelContext_10->materials_0[mi_0], kernelContext_10->materials_0[mi_0 + 1U], kernelContext_10->materials_0[mi_0 + 2U]);
    uint texBase_0 = uint(kernelContext_10->materials_0[mi_0 + 10U]);
    uint texMR_0 = uint(kernelContext_10->materials_0[mi_0 + 11U]);
    float metallic_0 = kernelContext_10->materials_0[mi_0 + 6U];

#line 60
    float3 albedo_2;

#line 60
    float metallic_1;
    if((texBase_0 + texMR_0) > 0U)
    {
        float2 uv0_0 = float2(kernelContext_10->uvs_0[2U * (kernelContext_10->indices_0[tri_0] + vo_0)], kernelContext_10->uvs_0[2U * (kernelContext_10->indices_0[tri_0] + vo_0) + 1U]);


        float2 uv_2 = uv0_0 + float2(b1_0)  * (float2(kernelContext_10->uvs_0[2U * (kernelContext_10->indices_0[_S61] + vo_0)], kernelContext_10->uvs_0[2U * (kernelContext_10->indices_0[_S61] + vo_0) + 1U]) - uv0_0) + float2(b2_0)  * (float2(kernelContext_10->uvs_0[2U * (kernelContext_10->indices_0[_S64] + vo_0)], kernelContext_10->uvs_0[2U * (kernelContext_10->indices_0[_S64] + vo_0) + 1U]) - uv0_0);

        if(texBase_0 > 0U)
        {

#line 68
            float3 _S79 = sampleTexture_0(texBase_0 - 1U, uv_2, 0.0f, kernelContext_10);

#line 68
            albedo_2 = albedo_1 * _S79;

#line 68
        }
        else
        {

#line 68
            albedo_2 = albedo_1;

#line 68
        }

        if(texMR_0 > 0U)
        {

#line 70
            float3 _S80 = sampleTexture_0(texMR_0 - 1U, uv_2, 0.0f, kernelContext_10);

#line 70
            metallic_1 = metallic_0 * _S80.z;

#line 70
        }
        else
        {

#line 70
            metallic_1 = metallic_0;

#line 70
        }

#line 61
    }
    else
    {

#line 61
        metallic_1 = metallic_0;

#line 61
        albedo_2 = albedo_1;

#line 61
    }

#line 73
    float _S81 = max(kernelContext_10->materials_0[mi_0 + 18U], max(kernelContext_10->materials_0[mi_0 + 19U], kernelContext_10->materials_0[mi_0 + 20U]));
    thread NrcVertex_0 v_3;
    (&v_3)->p_1 = hit_1 + ng_0 * float3(9.9999997473787516e-05f) ;
    (&v_3)->n_1 = n_2;
    (&v_3)->inst_1 = _S57;

#line 77
    bool _S82;
    if(metallic_1 == 0.0f)
    {

#line 78
        _S82 = kernelContext_10->materials_0[mi_0 + 8U] == 0.0f;

#line 78
    }
    else
    {

#line 78
        _S82 = false;

#line 78
    }

#line 78
    if(_S82)
    {

#line 78
        _S82 = kernelContext_10->materials_0[mi_0 + 15U] == 0.0f;

#line 78
    }
    else
    {

#line 78
        _S82 = false;

#line 78
    }

#line 78
    if(_S82)
    {

#line 78
        _S82 = _S81 == 0.0f;

#line 78
    }
    else
    {

#line 78
        _S82 = false;

#line 78
    }

#line 78
    (&v_3)->eligible_0 = _S82;



    (&v_3)->albedo_0 = albedo_2 * float3((1.0f - fresnelDielectric_0(max(dot(wo_0, n_2), 0.05000000074505806f), kernelContext_10->materials_0[mi_0 + 9U]))) ;
    return v_3;
}


#line 164 "shaders/include/pt_core.slang"
void basis_0(float3 n_3, float3 thread* t_2, float3 thread* b_0)
{

#line 164
    float3 a_1;

    if((abs(n_3.x)) > 0.89999997615814209f)
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
    float3 _S83 = normalize(cross(n_3, a_1));

#line 167
    *b_0 = _S83;
    *t_2 = cross(_S83, n_3);
    return;
}


#line 124
float3 cosineLocal_0(float u1_0, float u2_0)
{
    float r_2 = sqrt(u1_0);
    float phi_0 = 6.2831854820251465f * u2_0;
    return float3(r_2 * cos(phi_0), r_2 * sin(phi_0), sqrt(max(0.0f, 1.0f - u1_0)));
}


#line 183 "shaders/nrc_collect.slang"
float3 cosineDir_0(float3 n_4, Rng_0 thread* rng_2)
{
    thread float3 t_3;

#line 185
    thread float3 b_1;
    basis_0(n_4, &t_3, &b_1);
    float _S84 = Rng_next_0(rng_2);

#line 187
    float _S85 = Rng_next_0(rng_2);

#line 187
    float3 l_0 = cosineLocal_0(_S84, _S85);
    return normalize(float3(l_0.x)  * t_3 + float3(l_0.y)  * b_1 + float3(l_0.z)  * n_4);
}


#line 203 "shaders/include/pt_core.slang"
uint recvMask_0(uint inst_3, KernelContext_0 thread* kernelContext_11)
{

#line 203
    return kernelContext_11->lights_0[kernelContext_11->params_0[int(5)] * 16U + 5888U + 2U * inst_3];
}



float iesFactor_0(uint po_0, float3 d_0, KernelContext_0 thread* kernelContext_12)
{



    float th_0 = degrees_0(acos(clamp(- dot(d_0, float3((as_type<float>((kernelContext_12->lights_0[po_0 + 6U]))), (as_type<float>((kernelContext_12->lights_0[po_0 + 7U]))), (as_type<float>((kernelContext_12->lights_0[po_0 + 8U]))))), -1.0f, 1.0f)));
    float ph_0 = degrees_0(atan2(dot(d_0, float3((as_type<float>((kernelContext_12->lights_0[po_0 + 3U]))), (as_type<float>((kernelContext_12->lights_0[po_0 + 4U]))), (as_type<float>((kernelContext_12->lights_0[po_0 + 5U]))))), dot(d_0, float3((as_type<float>((kernelContext_12->lights_0[po_0]))), (as_type<float>((kernelContext_12->lights_0[po_0 + 1U]))), (as_type<float>((kernelContext_12->lights_0[po_0 + 2U])))))));

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

    uint _S86 = min(uint(th_0), 179U);
    uint _S87 = min(uint(ph_1), 359U);
    float ft_0 = th_0 - float(_S86);

    uint t_4 = po_0 + 9U;
    uint _S88 = t_4 + _S87 * 181U + _S86;
    uint _S89 = t_4 + (_S87 + 1U) * 181U + _S86;
    return mix(mix((as_type<float>((kernelContext_12->lights_0[_S88]))), (as_type<float>((kernelContext_12->lights_0[_S88 + 1U]))), ft_0), mix((as_type<float>((kernelContext_12->lights_0[_S89]))), (as_type<float>((kernelContext_12->lights_0[_S89 + 1U]))), ft_0), ph_1 - float(_S87));
}


#line 570
float opacityAt_0(uint instIdx_0, uint prim_1, float2 bary_0, KernelContext_0 thread* kernelContext_13)
{
    uint _S90 = instIdx_0 * 16U;

#line 572
    uint mi_1 = kernelContext_13->instances_0[_S90 + 2U] * 24U;
    float op_0 = kernelContext_13->materials_0[mi_1 + 22U];
    uint tex_1 = uint(kernelContext_13->materials_0[mi_1 + 23U]);

#line 574
    bool _S91;
    if(tex_1 > 0U)
    {

#line 575
        _S91 = op_0 > 0.0f;

#line 575
    }
    else
    {

#line 575
        _S91 = false;

#line 575
    }

#line 575
    float op_1;

#line 575
    if(_S91)
    {
        uint tri_1 = kernelContext_13->instances_0[_S90 + 1U] + 3U * prim_1;
        uint vo_1 = kernelContext_13->instances_0[_S90];
        float2 uv0_1 = float2(kernelContext_13->uvs_0[2U * (kernelContext_13->indices_0[tri_1] + vo_1)], kernelContext_13->uvs_0[2U * (kernelContext_13->indices_0[tri_1] + vo_1) + 1U]);
        uint _S92 = tri_1 + 1U;
        uint _S93 = tri_1 + 2U;

#line 581
        float3 _S94 = sampleTexture_0(tex_1 - 1U, uv0_1 + float2(bary_0.x)  * (float2(kernelContext_13->uvs_0[2U * (kernelContext_13->indices_0[_S92] + vo_1)], kernelContext_13->uvs_0[2U * (kernelContext_13->indices_0[_S92] + vo_1) + 1U]) - uv0_1) + float2(bary_0.y)  * (float2(kernelContext_13->uvs_0[2U * (kernelContext_13->indices_0[_S93] + vo_1)], kernelContext_13->uvs_0[2U * (kernelContext_13->indices_0[_S93] + vo_1) + 1U]) - uv0_1), 0.0f, kernelContext_13);

#line 581
        op_1 = op_0 * _S94.x;

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



bool occluded_0(float3 o_2, float3 d_1, float tmax_0, KernelContext_0 thread* kernelContext_14)
{

#line 589
    uint layer_0 = 0U;

#line 589
    float3 _S95 = o_2;

#line 589
    float _S96 = tmax_0;

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
        thread RayDesc_0 ray_1;
        (&ray_1)->Origin_0 = _S95;
        (&ray_1)->Direction_0 = d_1;
        (&ray_1)->TMin_0 = 0.0f;
        (&ray_1)->TMax_0 = _S96;
        thread raytracing::intersection_query<raytracing::triangle_data, raytracing::instancing> q_1;
        (&q_1)->reset({ (ray_1.Origin_0), (ray_1.Direction_0), (ray_1.TMin_0), (ray_1.TMax_0) }, (kernelContext_14->scene_0), (255U), _slang_ray_flags_to_intersection_params((5U)));
        for(;;)
        {

#line 600
            bool _S97 = ((&q_1)->next());

#line 600
            if(_S97)
            {
            }
            else
            {

#line 600
                break;
            }

#line 600
        }
        uint _S98 = (_slang_committed_intersection_type_to_uint((&q_1)->get_committed_intersection_type()));

#line 601
        if(_S98 != 1U)
        {

#line 602
            return false;
        }

#line 603
        uint _S99 = ((&q_1)->get_committed_instance_id());

#line 603
        uint _S100 = ((&q_1)->get_committed_primitive_id());

#line 603
        float2 _S101 = ((&q_1)->get_committed_triangle_barycentric_coord());

#line 603
        float _S102 = opacityAt_0(_S99, _S100, _S101, kernelContext_14);
        if(_S102 >= 1.0f)
        {

#line 605
            return true;
        }
        uint h_5 = (((((((as_type<uint>((_S95.x))) * 73856093U) ^ ((as_type<uint>((_S95.y))) * 19349663U)) ^ ((as_type<uint>((_S95.z))) * 83492791U)) ^ ((as_type<uint>((d_1.x))) * 2654435761U)) ^ ((as_type<uint>((d_1.y))) * 40503U)) ^ ((as_type<uint>((d_1.z))) * 2246822519U)) ^ (layer_0 * 3266489917U);

        uint h_6 = (h_5 ^ (h_5 >> 16U)) * 2146121005U;

        uint h_7 = (h_6 ^ (h_6 >> 15U)) * 2221713035U;

        if((float((h_7 ^ (h_7 >> 16U)) >> 8U) * 5.9604644775390625e-08f) < _S102)
        {

#line 614
            return true;
        }

#line 615
        float _S103 = ((&q_1)->get_committed_distance());

#line 615
        float adv_0 = _S103 + 9.9999997473787516e-05f;
        float3 _S104 = _S95 + d_1 * float3(adv_0) ;
        float _S105 = _S96 - adv_0;
        if(_S105 <= 0.0f)
        {

#line 619
            return false;
        }

#line 591
        layer_0 = layer_0 + 1U;

#line 591
        _S95 = _S104;

#line 591
        _S96 = _S105;

#line 591
    }

#line 621
    return true;
}


#line 250
float3 envTexel_0(uint i_1, uint j_0, KernelContext_0 thread* kernelContext_15)
{
    uint o_3 = 3U * (j_0 * kernelContext_15->params_0[int(24)] + i_1);
    return float3(kernelContext_15->envPixels_0[o_3], kernelContext_15->envPixels_0[o_3 + 1U], kernelContext_15->envPixels_0[o_3 + 2U]);
}


#line 190
float lum_0(float3 c_0)
{

#line 190
    return dot(c_0, float3(0.2125999927520752f, 0.71520000696182251f, 0.072200000286102295f));
}


#line 283
float3 envSample_0(float u1_1, float u2_1, float u3_0, float u4_0, float thread* pdf_0, float3 thread* le_0, KernelContext_0 thread* kernelContext_16)
{

#line 283
    uint lo_0;

    uint w_5 = kernelContext_16->params_0[int(24)];
    uint h_8 = kernelContext_16->params_0[int(25)];

    uint _S106 = h_8 - 1U;

#line 288
    uint lo_1 = 0U;

#line 288
    uint hi_0 = _S106;
    for(;;)
    {

#line 289
        if(lo_1 < hi_0)
        {
        }
        else
        {

#line 289
            break;
        }
        uint mid_0 = (lo_1 + hi_0) / 2U;
        if(kernelContext_16->envMarginal_0[mid_0] >= u1_1)
        {

#line 292
            lo_0 = lo_1;

#line 292
            hi_0 = mid_0;

#line 292
        }
        else
        {

#line 292
            lo_0 = mid_0 + 1U;

#line 292
        }

#line 292
        lo_1 = lo_0;

#line 289
    }

#line 299
    uint _S107 = w_5 - 1U;

#line 299
    lo_0 = 0U;

#line 299
    hi_0 = _S107;
    for(;;)
    {

#line 300
        if(lo_0 < hi_0)
        {
        }
        else
        {

#line 300
            break;
        }
        uint mid_1 = (lo_0 + hi_0) / 2U;
        if(kernelContext_16->envCond_0[lo_1 * w_5 + mid_1] >= u2_1)
        {

#line 303
            hi_0 = mid_1;

#line 303
        }
        else
        {

#line 303
            lo_0 = mid_1 + 1U;

#line 303
        }

#line 300
    }

#line 309
    float phi_1 = ((float(lo_0) + u3_0) / float(w_5) - 0.5f) * 2.0f * 3.1415927410125732f;
    float theta_0 = (float(lo_1) + u4_0) / float(h_8) * 3.1415927410125732f;
    float st_0 = sin(theta_0);

#line 311
    float3 _S108 = envTexel_0(lo_0, lo_1, kernelContext_16);
    *le_0 = _S108;
    float _S109 = lum_0(_S108);

#line 313
    float _S110 = pf_0(26U, kernelContext_16);

#line 313
    *pdf_0 = _S109 * _S110;
    return float3(st_0 * sin(phi_1), cos(theta_0), - st_0 * cos(phi_1));
}


#line 88 "shaders/nrc_collect.slang"
float3 nrcDirect_0(const NrcVertex_0 thread* v_4, Rng_0 thread* rng_3, KernelContext_0 thread* kernelContext_17)
{

#line 88
    bool chooseEnv_0;

#line 88
    bool _S111;

#line 88
    float3 _S112 = v_4->p_1;

#line 88
    float3 _S113 = v_4->n_1;



    float3 _S114 = float3(0.0f) ;
    uint _S115 = kernelContext_17->params_0[int(5)];
    uint emitterCount_0 = kernelContext_17->params_0[int(23)];
    bool hasEnv_0 = kernelContext_17->params_0[int(24)] > 0U;

#line 95
    float pEnv_0;
    if(hasEnv_0)
    {

#line 96
        if(emitterCount_0 > 0U)
        {

#line 96
            pEnv_0 = 0.5f;

#line 96
        }
        else
        {

#line 96
            pEnv_0 = 1.0f;

#line 96
        }

#line 96
    }
    else
    {

#line 96
        pEnv_0 = 0.0f;

#line 96
    }

#line 96
    uint li_0 = 0U;

#line 96
    float3 sum_0 = _S114;
    for(;;)
    {

#line 97
        if(li_0 < _S115)
        {
        }
        else
        {

#line 97
            break;
        }
        uint o_4 = li_0 * 16U;
        if(kernelContext_17->lights_0[o_4] == 3U)
        {

#line 100
            chooseEnv_0 = true;

#line 100
        }
        else
        {

#line 100
            uint _S116 = kernelContext_17->lights_0[o_4 + 14U];

#line 100
            uint _S117 = recvMask_0(v_4->inst_1, kernelContext_17);

#line 100
            chooseEnv_0 = (_S116 & _S117) == 0U;

#line 100
        }

#line 100
        if(chooseEnv_0)
        {

#line 101
            li_0 = li_0 + 1U;

#line 97
            continue;
        }



        float3 col_0 = float3((as_type<float>((kernelContext_17->lights_0[o_4 + 1U]))), (as_type<float>((kernelContext_17->lights_0[o_4 + 2U]))), (as_type<float>((kernelContext_17->lights_0[o_4 + 3U])))) * float3((as_type<float>((kernelContext_17->lights_0[o_4 + 4U])))) ;
        float3 vec_0 = float3((as_type<float>((kernelContext_17->lights_0[o_4 + 5U]))), (as_type<float>((kernelContext_17->lights_0[o_4 + 6U]))), (as_type<float>((kernelContext_17->lights_0[o_4 + 7U]))));

#line 103
        float dist_0;

#line 103
        float3 wi_0;

#line 103
        float3 li_1;



        if(kernelContext_17->lights_0[o_4] == 1U)
        {

#line 107
            wi_0 = - normalize(vec_0);

#line 107
            dist_0 = 1.00000001504746622e+30f;

#line 107
            li_1 = col_0;

#line 107
        }
        else
        {

#line 115
            float3 toL_0 = vec_0 - _S112;
            float d2_0 = dot(toL_0, toL_0);
            float dist_1 = sqrt(d2_0);
            float3 wi_1 = toL_0 / float3(dist_1) ;
            float3 li_2 = col_0 / float3(d2_0) ;
            uint _S118 = o_4 + 15U;

#line 120
            if(kernelContext_17->lights_0[_S118] != 0U)
            {

#line 120
                float _S119 = iesFactor_0(kernelContext_17->lights_0[_S118] - 1U, - wi_1, kernelContext_17);

#line 120
                wi_0 = li_2 * float3(_S119) ;

#line 120
            }
            else
            {

#line 120
                wi_0 = li_2;

#line 120
            }

            if(kernelContext_17->lights_0[o_4] == 2U)
            {

                float att_0 = saturate(dot(float3((as_type<float>((kernelContext_17->lights_0[o_4 + 8U]))), (as_type<float>((kernelContext_17->lights_0[o_4 + 9U]))), (as_type<float>((kernelContext_17->lights_0[o_4 + 10U])))), - wi_1) * (as_type<float>((kernelContext_17->lights_0[o_4 + 11U]))) + (as_type<float>((kernelContext_17->lights_0[o_4 + 12U]))));

#line 125
                li_1 = wi_0 * float3((att_0 * att_0)) ;

#line 122
            }
            else
            {

#line 122
                li_1 = wi_0;

#line 122
            }

#line 122
            wi_0 = wi_1;

#line 122
            dist_0 = dist_1;

#line 107
        }

#line 129
        float c_1 = dot(_S113, wi_0);
        if(c_1 > 0.0f)
        {

#line 130
            bool _S120 = occluded_0(_S112, wi_0, dist_0 - 0.0010000000474974513f, kernelContext_17);

#line 130
            _S111 = !_S120;

#line 130
        }
        else
        {

#line 130
            _S111 = false;

#line 130
        }

#line 130
        float3 sum_1;

#line 130
        if(_S111)
        {

#line 130
            sum_1 = sum_0 + li_1 * float3(c_1)  / float3(3.1415927410125732f) ;

#line 130
        }
        else
        {

#line 130
            sum_1 = sum_0;

#line 130
        }

#line 130
        sum_0 = sum_1;

#line 97
        li_0 = li_0 + 1U;

#line 97
    }

#line 133
    if(hasEnv_0)
    {

#line 133
        float _S121 = Rng_next_0(rng_3);

#line 133
        chooseEnv_0 = _S121 < pEnv_0;

#line 133
    }
    else
    {

#line 133
        chooseEnv_0 = false;

#line 133
    }
    if(emitterCount_0 > 0U)
    {

#line 134
        _S111 = !chooseEnv_0;

#line 134
    }
    else
    {

#line 134
        _S111 = false;

#line 134
    }

#line 134
    if(_S111)
    {
        float _S122 = Rng_next_0(rng_3);
        float ua_0 = Rng_next_0(rng_3);
        float ub_0 = Rng_next_0(rng_3);

        uint _S123 = emitterCount_0 - 1U;

#line 140
        uint lo_2 = 0U;

#line 140
        uint hi_1 = _S123;
        for(;;)
        {

#line 141
            if(lo_2 < hi_1)
            {
            }
            else
            {

#line 141
                break;
            }
            uint mid_2 = (lo_2 + hi_1) / 2U;
            if(kernelContext_17->emitCdf_0[mid_2] >= _S122)
            {

#line 144
                hi_1 = mid_2;

#line 144
            }
            else
            {

#line 144
                lo_2 = mid_2 + 1U;

#line 144
            }

#line 141
        }

#line 149
        uint e_0 = lo_2 * 16U;
        float3 a_2 = float3(kernelContext_17->emitters_0[e_0], kernelContext_17->emitters_0[e_0 + 1U], kernelContext_17->emitters_0[e_0 + 2U]);
        float3 b_2 = float3(kernelContext_17->emitters_0[e_0 + 3U], kernelContext_17->emitters_0[e_0 + 4U], kernelContext_17->emitters_0[e_0 + 5U]);
        float3 c_2 = float3(kernelContext_17->emitters_0[e_0 + 6U], kernelContext_17->emitters_0[e_0 + 7U], kernelContext_17->emitters_0[e_0 + 8U]);
        float su_0 = sqrt(ua_0);

        float3 toL_1 = a_2 * float3((1.0f - su_0))  + b_2 * float3((su_0 * (1.0f - ub_0)))  + c_2 * float3((su_0 * ub_0))  - _S112;
        float d2_1 = dot(toL_1, toL_1);
        float dist_2 = sqrt(d2_1);
        float3 wi_2 = toL_1 / float3(dist_2) ;
        float cosl_0 = abs(dot(normalize(cross(b_2 - a_2, c_2 - a_2)), wi_2));
        float cosi_1 = dot(_S113, wi_2);
        if(cosi_1 > 0.0f)
        {

#line 161
            _S111 = cosl_0 > 9.9999997473787516e-06f;

#line 161
        }
        else
        {

#line 161
            _S111 = false;

#line 161
        }

#line 161
        if(_S111)
        {

#line 161
            uint _S124 = (as_type<uint>((kernelContext_17->emitters_0[e_0 + 14U])));

#line 161
            uint _S125 = recvMask_0(v_4->inst_1, kernelContext_17);

#line 161
            _S111 = (_S124 & _S125) != 0U;

#line 161
        }
        else
        {

#line 161
            _S111 = false;

#line 161
        }

#line 161
        if(_S111)
        {

#line 161
            bool _S126 = occluded_0(_S112, wi_2, dist_2 * 0.99900001287460327f, kernelContext_17);

#line 161
            _S111 = !_S126;

#line 161
        }
        else
        {

#line 161
            _S111 = false;

#line 161
        }

#line 161
        if(_S111)
        {

#line 161
            sum_0 = sum_0 + float3(kernelContext_17->emitters_0[e_0 + 9U], kernelContext_17->emitters_0[e_0 + 10U], kernelContext_17->emitters_0[e_0 + 11U]) / float3(((1.0f - pEnv_0) * kernelContext_17->emitters_0[e_0 + 13U] * d2_1 / (kernelContext_17->emitters_0[e_0 + 12U] * cosl_0)))  * float3(cosi_1)  / float3(3.1415927410125732f) ;

#line 161
        }

#line 134
    }

#line 167
    if(chooseEnv_0)
    {
        float e1_0 = Rng_next_0(rng_3);
        float e2_0 = Rng_next_0(rng_3);
        float e3_1 = Rng_next_0(rng_3);
        float e4_0 = Rng_next_0(rng_3);
        thread float pdfE_0;
        thread float3 leE_0;

#line 174
        float3 _S127 = envSample_0(e1_0, e2_0, e3_1, e4_0, &pdfE_0, &leE_0, kernelContext_17);

        float cosi_2 = dot(_S113, _S127);
        if(pdfE_0 > 0.0f)
        {

#line 177
            chooseEnv_0 = cosi_2 > 0.0f;

#line 177
        }
        else
        {

#line 177
            chooseEnv_0 = false;

#line 177
        }

#line 177
        if(chooseEnv_0)
        {

#line 177
            bool _S128 = occluded_0(_S112, _S127, 1.00000001504746622e+30f, kernelContext_17);

#line 177
            chooseEnv_0 = !_S128;

#line 177
        }
        else
        {

#line 177
            chooseEnv_0 = false;

#line 177
        }

#line 177
        if(chooseEnv_0)
        {

#line 177
            sum_0 = sum_0 + leE_0 / float3((pEnv_0 * pdfE_0))  * float3(cosi_2)  / float3(3.1415927410125732f) ;

#line 177
        }

#line 167
    }

#line 180
    return sum_0;
}


#line 94 "shaders/include/pt_core.slang"
float4 nrcBounds_0(KernelContext_0 thread* kernelContext_18)
{

#line 94
    float _S129 = pf_0(45U, kernelContext_18);

#line 94
    float _S130 = pf_0(46U, kernelContext_18);

#line 94
    float _S131 = pf_0(47U, kernelContext_18);

#line 94
    float _S132 = pf_0(48U, kernelContext_18);

#line 94
    return float4(_S129, _S130, _S131, _S132);
}


#line 53 "shaders/include/nrc_net.slang"
float3 nrcUnit_0(float3 p_2, KernelContext_0 thread* kernelContext_19)
{

#line 53
    float4 _S133 = nrcBounds_0(kernelContext_19);

#line 53
    return saturate((p_2 - _S133.xyz) * float3(_S133.w) );
}


#line 29
float nrcLevelRes_0(uint l_1)
{

#line 29
    return floor(16.0f * pow(1.5f, float(l_1)));
}


#line 24
uint nrcHash_0(uint3 c_3, uint level_0)
{
    return ((((c_3.x) ^ (c_3.y * 2654435761U)) ^ (c_3.z * 805459861U)) ^ (level_0 * 2654435761U)) & 32767U;
}


#line 41
void nrcCorner_0(float3 u_1, uint level_1, uint k_1, uint thread* slot_0, float thread* w_6)
{

    float3 s_3 = u_1 * float3(nrcLevelRes_0(level_1)) ;
    float3 f_0 = floor(s_3);
    float3 t_5 = s_3 - f_0;
    uint _S134 = k_1 & 1U;

#line 47
    uint _S135 = (k_1 >> 1U) & 1U;

#line 47
    uint _S136 = (k_1 >> 2U) & 1U;
    uint3 c_4 = uint3(f_0) + uint3(_S134, _S135, _S136);

#line 48
    float _S137;
    if(_S134 != 0U)
    {

#line 49
        _S137 = t_5.x;

#line 49
    }
    else
    {

#line 49
        _S137 = 1.0f - t_5.x;

#line 49
    }

#line 49
    float _S138;

#line 49
    if(_S135 != 0U)
    {

#line 49
        _S138 = t_5.y;

#line 49
    }
    else
    {

#line 49
        _S138 = 1.0f - t_5.y;

#line 49
    }

#line 49
    float _S139 = _S137 * _S138;

#line 49
    if(_S136 != 0U)
    {

#line 49
        _S137 = t_5.z;

#line 49
    }
    else
    {

#line 49
        _S137 = 1.0f - t_5.z;

#line 49
    }

#line 49
    *w_6 = _S139 * _S137;
    *slot_0 = (level_1 * 32768U + nrcHash_0(c_4, level_1)) * 2U;
    return;
}


float nrcSoftplus_0(float x_2)
{

#line 55
    float _S140;

#line 55
    if(x_2 > 20.0f)
    {

#line 55
        _S140 = x_2;

#line 55
    }
    else
    {

#line 55
        _S140 = log(1.0f + exp(x_2));

#line 55
    }

#line 55
    return _S140;
}


#line 31
struct NrcAct_0
{
    array<float, int(19)> x_3;
    array<float, int(32)> a1_0;
    array<float, int(32)> a2_0;
    array<float, int(3)> pre3_0;
    float3 y_1;
};


#line 57
NrcAct_0 nrcForward_0(float3 p_3, float3 n_5, KernelContext_0 thread* kernelContext_20)
{

#line 57
    uint k_2;

#line 57
    float f0_0;

    thread NrcAct_0 a_3;

#line 59
    float3 _S141 = nrcUnit_0(p_3, kernelContext_20);

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
        k_2 = 0U;

#line 61
        f0_0 = 0.0f;

#line 61
        float f1_0 = 0.0f;


        for(;;)
        {

#line 64
            if(k_2 < 8U)
            {
            }
            else
            {

#line 64
                break;
            }
            thread uint slot_1;
            thread float w_7;
            nrcCorner_0(_S141, l_2, k_2, &slot_1, &w_7);
            float f0_1 = f0_0 + w_7 * *(kernelContext_20->restir_0+slot_1);
            float f1_1 = f1_0 + w_7 * *(kernelContext_20->restir_0+(slot_1 + 1U));

#line 64
            k_2 = k_2 + 1U;

#line 64
            f0_0 = f0_1;

#line 64
            f1_0 = f1_1;

#line 64
        }

#line 72
        uint _S142 = 2U * l_2;

#line 72
        (&a_3)->x_3[_S142] = f0_0;
        (&a_3)->x_3[_S142 + 1U] = f1_0;

#line 61
        l_2 = l_2 + 1U;

#line 61
    }

#line 61
    k_2 = 0U;

#line 75
    for(;;)
    {

#line 75
        if(k_2 < 3U)
        {
        }
        else
        {

#line 75
            break;
        }

#line 76
        (&a_3)->x_3[16U + k_2] = n_5[k_2];

#line 75
        k_2 = k_2 + 1U;

#line 75
    }

#line 75
    uint j_1 = 0U;

    for(;;)
    {

#line 77
        if(j_1 < 32U)
        {
        }
        else
        {

#line 77
            break;
        }
        float device* _S143 = kernelContext_20->restir_0+(524896U + j_1);

#line 79
        k_2 = 0U;

#line 79
        f0_0 = *_S143;
        for(;;)
        {

#line 80
            if(k_2 < 19U)
            {
            }
            else
            {

#line 80
                break;
            }

#line 81
            float s_4 = f0_0 + *(kernelContext_20->restir_0+(524288U + j_1 * 19U + k_2)) * (&a_3)->x_3[k_2];

#line 80
            k_2 = k_2 + 1U;

#line 80
            f0_0 = s_4;

#line 80
        }

        (&a_3)->a1_0[j_1] = max(f0_0, 0.0f);

#line 77
        j_1 = j_1 + 1U;

#line 77
    }

#line 77
    j_1 = 0U;

#line 84
    for(;;)
    {

#line 84
        if(j_1 < 32U)
        {
        }
        else
        {

#line 84
            break;
        }
        float device* _S144 = kernelContext_20->restir_0+(525952U + j_1);

#line 86
        k_2 = 0U;

#line 86
        f0_0 = *_S144;
        for(;;)
        {

#line 87
            if(k_2 < 32U)
            {
            }
            else
            {

#line 87
                break;
            }

#line 88
            float s_5 = f0_0 + *(kernelContext_20->restir_0+(524928U + j_1 * 32U + k_2)) * (&a_3)->a1_0[k_2];

#line 87
            k_2 = k_2 + 1U;

#line 87
            f0_0 = s_5;

#line 87
        }

        (&a_3)->a2_0[j_1] = max(f0_0, 0.0f);

#line 84
        j_1 = j_1 + 1U;

#line 84
    }

#line 84
    uint o_5 = 0U;

#line 91
    for(;;)
    {

#line 91
        if(o_5 < 3U)
        {
        }
        else
        {

#line 91
            break;
        }
        float device* _S145 = kernelContext_20->restir_0+(526080U + o_5);

#line 93
        k_2 = 0U;

#line 93
        f0_0 = *_S145;
        for(;;)
        {

#line 94
            if(k_2 < 32U)
            {
            }
            else
            {

#line 94
                break;
            }

#line 95
            float s_6 = f0_0 + *(kernelContext_20->restir_0+(525984U + o_5 * 32U + k_2)) * (&a_3)->a2_0[k_2];

#line 94
            k_2 = k_2 + 1U;

#line 94
            f0_0 = s_6;

#line 94
        }

        (&a_3)->pre3_0[o_5] = f0_0;
        (&a_3)->y_1[o_5] = nrcSoftplus_0(f0_0);

#line 91
        o_5 = o_5 + 1U;

#line 91
    }

#line 99
    return a_3;
}

float3 nrcQuery_0(float3 p_4, float3 n_6, KernelContext_0 thread* kernelContext_21)
{

#line 102
    NrcAct_0 _S146 = nrcForward_0(p_4, n_6, kernelContext_21);

#line 102
    return _S146.y_1;
}


#line 193 "shaders/nrc_collect.slang"
[[kernel]] void nrc_collect(uint3 tid_0 [[thread_position_in_grid]], uint device* params_1 [[buffer(6)]], float device* nrcSamples_1 [[buffer(20)]], metal::raytracing::acceleration_structure<metal::raytracing::instancing> scene_1 [[buffer(0)]], uint device* instances_1 [[buffer(3)]], uint device* indices_1 [[buffer(2)]], float device* positions_1 [[buffer(1)]], float device* vnormals_1 [[buffer(16)]], float device* materials_1 [[buffer(4)]], float device* uvs_1 [[buffer(13)]], uint device* texInfo_1 [[buffer(15)]], float device* texels_1 [[buffer(14)]], uint device* lights_1 [[buffer(5)]], float device* emitCdf_1 [[buffer(9)]], float device* emitters_1 [[buffer(8)]], float device* envMarginal_1 [[buffer(11)]], float device* envCond_1 [[buffer(12)]], float device* envPixels_1 [[buffer(10)]], float device* restir_2 [[buffer(19)]])
{

#line 193
    thread KernelContext_0 kernelContext_22;

#line 193
    (&kernelContext_22)->params_0 = params_1;

#line 193
    (&kernelContext_22)->nrcSamples_0 = nrcSamples_1;

#line 193
    (&kernelContext_22)->scene_0 = scene_1;

#line 193
    (&kernelContext_22)->instances_0 = instances_1;

#line 193
    (&kernelContext_22)->indices_0 = indices_1;

#line 193
    (&kernelContext_22)->positions_0 = positions_1;

#line 193
    (&kernelContext_22)->vnormals_0 = vnormals_1;

#line 193
    (&kernelContext_22)->materials_0 = materials_1;

#line 193
    (&kernelContext_22)->uvs_0 = uvs_1;

#line 193
    (&kernelContext_22)->texInfo_0 = texInfo_1;

#line 193
    (&kernelContext_22)->texels_0 = texels_1;

#line 193
    (&kernelContext_22)->lights_0 = lights_1;

#line 193
    (&kernelContext_22)->emitCdf_0 = emitCdf_1;

#line 193
    (&kernelContext_22)->emitters_0 = emitters_1;

#line 193
    (&kernelContext_22)->envMarginal_0 = envMarginal_1;

#line 193
    (&kernelContext_22)->envCond_0 = envCond_1;

#line 193
    (&kernelContext_22)->envPixels_0 = envPixels_1;

#line 193
    (&kernelContext_22)->restir_0 = restir_2;

    uint t_6 = tid_0.x;
    if(t_6 >= params_1[int(31)])
    {

#line 197
        return;
    }

#line 198
    uint o_6 = t_6 * 12U;
    uint _S147 = o_6 + 9U;

#line 199
    *((&kernelContext_22)->nrcSamples_0+_S147) = 0.0f;
    thread Rng_0 rng_4;
    (&rng_4)->state_0 = pcg_0(t_6 ^ (pcg_0((&kernelContext_22)->params_0[int(6)] * 2654435769U + (&kernelContext_22)->params_0[int(43)] * 1759714724U + 625341585U)));
    float _S148 = Rng_next_0(&rng_4);

#line 202
    uint _S149 = min(uint(_S148 * float((&kernelContext_22)->params_0[int(0)])), (&kernelContext_22)->params_0[int(0)] - 1U);
    float _S150 = Rng_next_0(&rng_4);

#line 203
    PathState_0 _S151 = generatePathFor_0(_S149, min(uint(_S150 * float((&kernelContext_22)->params_0[int(1)])), (&kernelContext_22)->params_0[int(1)] - 1U), (&kernelContext_22)->params_0[int(6)] * (&kernelContext_22)->params_0[int(31)] + t_6, &kernelContext_22);

#line 203
    Hit_0 _S152 = traceClosest_0(_S151.org_0, _S151.dir_0, &kernelContext_22);


    if(!_S152.hit_0)
    {

#line 207
        return;
    }

#line 207
    thread Hit_0 _S153 = _S152;

#line 207
    NrcVertex_0 _S154 = nrcVertex_0(&_S153, _S151.org_0, _S151.dir_0, &kernelContext_22);

    if(!_S154.eligible_0)
    {

#line 210
        return;
    }

#line 211
    float3 d1_0 = cosineDir_0(_S154.n_1, &rng_4);

#line 211
    Hit_0 _S155 = traceClosest_0(_S154.p_1, d1_0, &kernelContext_22);

    if(!_S155.hit_0)
    {

#line 214
        return;
    }

#line 214
    thread Hit_0 _S156 = _S155;

#line 214
    NrcVertex_0 _S157 = nrcVertex_0(&_S156, _S154.p_1, d1_0, &kernelContext_22);

    if(!_S157.eligible_0)
    {

#line 217
        return;
    }


    float3 _S158 = float3(0.0f) ;
    float3 _S159 = float3(1.0f) ;

#line 222
    float3 an_0 = _S157.n_1;

#line 222
    float3 at_0 = _S157.p_1;

#line 222
    uint j_2 = 0U;

#line 222
    float3 thr_1 = _S159;

#line 222
    float3 target_0 = _S158;


    for(;;)
    {

#line 225
        if(j_2 < 4U)
        {
        }
        else
        {

#line 225
            break;
        }
        float3 d_2 = cosineDir_0(an_0, &rng_4);

#line 227
        Hit_0 _S160 = traceClosest_0(at_0, d_2, &kernelContext_22);

        if(!_S160.hit_0)
        {

#line 229
            float _S161 = pf_0(20U, &kernelContext_22);

#line 229
            float _S162 = pf_0(21U, &kernelContext_22);

#line 229
            float _S163 = pf_0(22U, &kernelContext_22);

#line 229
            target_0 = target_0 + thr_1 * float3(_S161, _S162, _S163);


            break;
        }

#line 232
        thread Hit_0 _S164 = _S160;

#line 232
        NrcVertex_0 _S165 = nrcVertex_0(&_S164, at_0, d_2, &kernelContext_22);


        if(!_S165.eligible_0)
        {

#line 236
            return;
        }

#line 237
        float3 _S166 = thr_1 * _S165.albedo_0;

#line 237
        thread NrcVertex_0 _S167 = _S165;

#line 237
        float3 _S168 = nrcDirect_0(&_S167, &rng_4, &kernelContext_22);

#line 237
        float3 target_1 = target_0 + _S166 * _S168;



        uint _S169 = j_2 + 1U;

#line 241
        if(_S169 == 4U)
        {

#line 241
            float3 _S170 = nrcQuery_0(_S165.p_1, _S165.n_1, &kernelContext_22);

#line 241
            target_0 = target_1 + _S166 * _S170;

#line 241
        }
        else
        {

#line 241
            target_0 = target_1;

#line 241
        }

#line 225
        an_0 = _S165.n_1;

#line 225
        at_0 = _S165.p_1;

#line 225
        j_2 = _S169;

#line 225
        thr_1 = _S166;

#line 225
    }

#line 225
    uint k_3 = 0U;

#line 244
    for(;;)
    {

#line 244
        if(k_3 < 3U)
        {
        }
        else
        {

#line 244
            break;
        }
        *((&kernelContext_22)->nrcSamples_0+(o_6 + k_3)) = _S157.p_1[k_3];
        *((&kernelContext_22)->nrcSamples_0+(o_6 + 3U + k_3)) = _S157.n_1[k_3];
        *((&kernelContext_22)->nrcSamples_0+(o_6 + 6U + k_3)) = target_0[k_3];

#line 244
        k_3 = k_3 + 1U;

#line 244
    }

#line 250
    *((&kernelContext_22)->nrcSamples_0+_S147) = 1.0f;
    return;
}

