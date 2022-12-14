#clw_include_once "marching.cl"
#clw_include_once "sample.cl"

struct material_evaluation{
  struct ray reflected;
  float4 albedo;
  float probability;
};

struct material_evaluation material_evaluate(struct ray r, float3 n, struct event e, int random_seed){
  struct ray r_reflected = {r.origin - 2*n, r.direction - (2 * dot(r.direction, n)*n)};
  struct material_evaluation me;
#define SHADER 2
#if SHADER == 0
  if(e.value > -1000){
    if(dot(r.direction, n) < 0){
      //Inside
      //r_reflected.direction = get_hemisphere_direction_reflective(r_reflected.direction, random_seed, 0.0f);

      r_reflected = r;
      r_reflected.direction = get_hemisphere_direction_reflective(r.direction, random_seed, 0.3f);
      me.albedo = (float4){0.95f, 0.95f, 0.95f, 0.0f};
    }else{
      r_reflected = r;
      r_reflected.direction = get_hemisphere_direction_reflective(r.direction, random_seed, 0.3f);
      me.albedo = (float4){0.95f, 0.95f, 0.95f, 0.0f};
      //Outside
    }
  }else{
    r_reflected.direction = get_hemisphere_direction_reflective(r_reflected.direction, random_seed, 0.1f);
    me.albedo = (float4){0.9f, 0.4f, 0.0f, 0.0f};
  }
#elif SHADER == 1
  r_reflected.direction = get_hemisphere_direction_reflective(r_reflected.direction, random_seed, 0.9f);
  me.albedo = (float4){0.9f, 0.4f, 0.0f, 0.0f};
#else
  r_reflected.direction = get_hemisphere_direction_reflective(r_reflected.direction, random_seed, 0.1f);
  me.albedo = (float4){0.9f, 0.4f, 0.0f, 0.0f};
#endif

  me.reflected = r_reflected;
  me.probability = 1.0f;
  return me;
}

struct material_evaluation shader_evaluate(__read_only image3d_t raw, __read_only image2d_t environment_map, struct ray r, struct event e, int random_seed){
  struct material_evaluation me;
  if(e.type == Hit){
    float3 n = normal(raw, r.origin);
    return material_evaluate(r, n, e, random_seed);
  }else{
    float4 light = sample_environment_map(r, environment_map);
    //me.albedo = light;//(float4){0.0f, 0.0f, 0.0f, 0.0f};
    light = clamp(light, 0, 1.0f);
    me.albedo = light;//(float4){0.0f, 0.0f, 0.0f, 0.0f};
    me.albedo.w = 0.0f;
    me.probability = 1.0f;
    me.reflected = r;
    return me;
  }
}

