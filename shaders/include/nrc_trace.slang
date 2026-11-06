// Helpers of the neural radiance cache's path kernels (nrc_collect, nrc_validate): a hit's shading data, the light a
// diffuse surface gets straight from the lights, and cosine-sampled directions. Include pt_core.slang first.

struct NrcVertex
{
    float3 p;        // the shading point, lifted off the surface
    float3 n;        // the shading normal on the side the ray came from
    float3 albedo;   // the diffuse lobe's albedo
    uint inst;
    bool eligible;   // only diffuse, so the cache covers it
};

NrcVertex nrcVertex(Hit hq, float3 org, float3 dir)
{
    uint inst = hq.inst * 16;
    uint tri = instances[inst + 1] + 3 * hq.prim;
    uint vo = instances[inst];
    float3 p0 = transformPoint(inst + 4, vertexPos(indices[tri] + vo));
    float3 p1 = transformPoint(inst + 4, vertexPos(indices[tri + 1] + vo));
    float3 p2 = transformPoint(inst + 4, vertexPos(indices[tri + 2] + vo));
    float3 nOut = normalize(cross(p1 - p0, p2 - p0));
    float3 wo = -dir;
    bool outside = dot(nOut, wo) > 0.0;
    float3 ng = outside ? nOut : -nOut;
    float3 hit = org + dir * hq.t;
    float3 e1 = p1 - p0;
    float3 e2 = p2 - p0;
    float3 e3 = hit - p0;
    float d11 = dot(e1, e1);
    float d12 = dot(e1, e2);
    float d22 = dot(e2, e2);
    float den = max(d11 * d22 - d12 * d12, 1.0e-20);
    float b1 = (d22 * dot(e3, e1) - d12 * dot(e3, e2)) / den;
    float b2 = (d11 * dot(e3, e2) - d12 * dot(e3, e1)) / den;
    float3 nsObj = (1.0 - b1 - b2) * vertexNormal(indices[tri] + vo) + b1 * vertexNormal(indices[tri + 1] + vo) + b2 * vertexNormal(indices[tri + 2] + vo);
    float3 ns = nOut;
    if (dot(nsObj, nsObj) > 1.0e-12)
    {
        ns = normalize(transformNormal(inst + 4, nsObj));
        if (dot(ns, nOut) < 0.0)
            ns = -ns;
    }
    float3 n = outside ? ns : -ns;
    uint mi = instances[inst + 2] * 24;
    float3 albedo = float3(materials[mi], materials[mi + 1], materials[mi + 2]);
    uint texBase = uint(materials[mi + 10]);
    uint texMR = uint(materials[mi + 11]);
    float metallic = materials[mi + 6];
    if (texBase + texMR > 0)
    {
        float2 uv0 = float2(uvs[2 * (indices[tri] + vo)], uvs[2 * (indices[tri] + vo) + 1]);
        float2 uv1 = float2(uvs[2 * (indices[tri + 1] + vo)], uvs[2 * (indices[tri + 1] + vo) + 1]);
        float2 uv2 = float2(uvs[2 * (indices[tri + 2] + vo)], uvs[2 * (indices[tri + 2] + vo) + 1]);
        float2 uv = uv0 + b1 * (uv1 - uv0) + b2 * (uv2 - uv0);
        // shortcut: the finest texture level (the renderer filters by the ray cone), so a cached albedo can differ a little from a rendered one.
        if (texBase > 0)
            albedo *= sampleTexture(texBase - 1, uv, 0.0);
        if (texMR > 0)
            metallic *= sampleTexture(texMR - 1, uv, 0.0).z;
    }
    float sheenMax = max(materials[mi + 18], max(materials[mi + 19], materials[mi + 20]));
    NrcVertex v;
    v.p = hit + ng * 1.0e-4;
    v.n = n;
    v.inst = hq.inst;
    v.eligible = metallic == 0.0 && materials[mi + 8] == 0.0 && materials[mi + 15] == 0.0 && sheenMax == 0.0;
    // The renderer scales the diffuse lobe by one minus the dielectric base's Fresnel reflectance.
    float ior = materials[mi + 9];
    float woN = max(dot(wo, n), 0.05);
    v.albedo = albedo * (1.0 - fresnelDielectric(woN, ior));
    return v;
}

// Light that reaches a diffuse surface straight from emitters, the environment map and delta lights, divided by pi
// (one sample each of the emitters or the environment, as the renderer's light sampling takes).
float3 nrcDirect(NrcVertex v, inout Rng rng)
{
    float3 p = v.p;
    float3 n = v.n;
    float3 sum = float3(0.0);
    uint lightCount = params[5];
    uint emitterCount = params[23];
    bool hasEnv = params[24] > 0;
    float pEnv = hasEnv ? (emitterCount > 0 ? 0.5 : 1.0) : 0.0;
    for (uint li = 0; li < lightCount; li++)
    {
        uint o = li * 16;
        if (lights[o] == 3 || (lights[o + 14] & recvMask(v.inst)) == 0)
            continue;
        float3 col = float3(asfloat(lights[o + 1]), asfloat(lights[o + 2]), asfloat(lights[o + 3])) * asfloat(lights[o + 4]);
        float3 vec = float3(asfloat(lights[o + 5]), asfloat(lights[o + 6]), asfloat(lights[o + 7]));
        float3 wi;
        float dist;
        float3 li_;
        if (lights[o] == 1)
        {
            wi = -normalize(vec);
            dist = 1.0e30;
            li_ = col;
        }
        else
        {
            float3 toL = vec - p;
            float d2 = dot(toL, toL);
            dist = sqrt(d2);
            wi = toL / dist;
            li_ = col / d2;
            if (lights[o + 15] != 0)
                li_ *= iesFactor(lights[o + 15] - 1, -wi);
            if (lights[o] == 2)
            {
                float3 axis = float3(asfloat(lights[o + 8]), asfloat(lights[o + 9]), asfloat(lights[o + 10]));
                float att = saturate(dot(axis, -wi) * asfloat(lights[o + 11]) + asfloat(lights[o + 12]));
                li_ *= att * att;
            }
        }
        float c = dot(n, wi);
        if (c > 0.0 && !occluded(p, wi, dist - 1.0e-3))
            sum += li_ * c / PI;
    }
    bool chooseEnv = hasEnv && rng.next() < pEnv;
    if (emitterCount > 0 && !chooseEnv)
    {
        float ue = rng.next();
        float ua = rng.next();
        float ub = rng.next();
        uint lo = 0;
        uint hi = emitterCount - 1;
        while (lo < hi)
        {
            uint mid = (lo + hi) / 2;
            if (emitCdf[mid] >= ue)
                hi = mid;
            else
                lo = mid + 1;
        }
        uint e = lo * 16;
        float3 a = float3(emitters[e], emitters[e + 1], emitters[e + 2]);
        float3 b = float3(emitters[e + 3], emitters[e + 4], emitters[e + 5]);
        float3 c = float3(emitters[e + 6], emitters[e + 7], emitters[e + 8]);
        float su = sqrt(ua);
        float3 xl = a * (1.0 - su) + b * (su * (1.0 - ub)) + c * (su * ub);
        float3 toL = xl - p;
        float d2 = dot(toL, toL);
        float dist = sqrt(d2);
        float3 wi = toL / dist;
        float cosl = abs(dot(normalize(cross(b - a, c - a)), wi));
        float cosi = dot(n, wi);
        if (cosi > 0.0 && cosl > 1.0e-5 && (asuint(emitters[e + 14]) & recvMask(v.inst)) != 0 && !occluded(p, wi, dist * (1.0 - 1.0e-3)))
        {
            float pl = (1.0 - pEnv) * emitters[e + 13] * d2 / (emitters[e + 12] * cosl);
            sum += float3(emitters[e + 9], emitters[e + 10], emitters[e + 11]) / pl * cosi / PI;
        }
    }
    if (chooseEnv)
    {
        float e1 = rng.next();
        float e2 = rng.next();
        float e3 = rng.next();
        float e4 = rng.next();
        float pdfE;
        float3 leE;
        float3 wi = envSample(e1, e2, e3, e4, pdfE, leE);
        float cosi = dot(n, wi);
        if (pdfE > 0.0 && cosi > 0.0 && !occluded(p, wi, 1.0e30))
            sum += leE / (pEnv * pdfE) * cosi / PI;
    }
    return sum;
}

float3 cosineDir(float3 n, inout Rng rng)
{
    float3 t, b;
    basis(n, t, b);
    float3 l = cosineLocal(rng.next(), rng.next());
    return normalize(l.x * t + l.y * b + l.z * n);
}

