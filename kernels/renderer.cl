#clw_include_once "marching.cl"
#clw_include_once "environment_map.cl"
#clw_include_once "shader.cl"
#clw_include_once "debug.cl"

#define RED (uint4)(255,0,0,0)
#define GREEN (uint4)(0,255,0,0)
#define BLUE (uint4)(0,0,255,0)
#define BLACK (uint4)(0,0,0,0)
#define WHITE (uint4)(255,255,255,0)
#define GRAY (uint4)(80,80,80,0)

#define REDF (float4)  (1.0f, 0,    0,    0)
#define GREENF (float4)(0,    1.0f, 0,    0)
#define BLUEF (float4) (0,    0,    1.0f, 0)
#define BLACKF (float4)(0,    0,    0,    0)
#define WHITEF (float4)(1.0f, 1.0f, 1.0f, 0)
#define GRAYF (float4) (0.3f, 0.3f, 0.3f, 0)
#define ALPHAF (float4) (0,0,0,1.0f)



__kernel void render(__write_only image2d_t current,
                                  __read_only image2d_t last,
                                  __read_only image3d_t raw,
                                  __read_only image3d_t signed_distance_field,
                                  __constant float* raw_scale,
                                  __read_only image2d_t environment_map,
                                  __constant float* camera_position,
                                  __constant float* camera_target,
                                  int random_seed){


  int2 position = {get_global_id(0), get_global_id(1)};
  int2 frame_size = {get_image_width(current), get_image_height(current)};
  if(position.x >= frame_size.x || position.y >= frame_size.y) return;

  const sampler_t sampler = CLK_FILTER_NEAREST | CLK_ADDRESS_CLAMP;
  float4 frame_color = read_imagef(last, sampler, position);

  struct ray r = generate_ray_depth(camera_position, camera_target, position, frame_size, 10.0f, random_seed);
  struct event e = {None, 0, 0};

  int bounce_counter = 0;
  #define PATH_LENGTH 64
  struct material_evaluation me[PATH_LENGTH];

  for(; bounce_counter < PATH_LENGTH; ++bounce_counter){
    r = next_event(raw, signed_distance_field, r, &e, random_seed);
    me[bounce_counter] = shader_evaluate(raw, environment_map, r, e, random_seed);
    r = me[bounce_counter].reflected;
    if(e.type != Hit) break;
  }

  #if 1
  //Hide background
  if(bounce_counter == 0){
    write_imagef(current, position, frame_color + ALPHAF);
    //debug_draw(current, last, raw, signed_distance_field, raw_scale, environment_map, camera_position, camera_target, random_seed);
    return;
  }
  #endif

  //Hit nothing
  if(bounce_counter == PATH_LENGTH){
    write_imagef(current, position, frame_color + ALPHAF);
    return;
  } 

  //Valid path
  float4 color = me[0].albedo;
  for(int i = 1; i <= bounce_counter; ++i){
    color *= me[i].albedo;
  }

  write_imagef(current, position, color + frame_color + ALPHAF);
}

__kernel void update_display_frame(__read_only image2d_t frame, __write_only image2d_t display_frame, int iterations){
  int2 position = {get_global_id(0), get_global_id(1)};
  int2 frame_size = {get_image_width(frame), get_image_height(frame)};
  if(position.x >= frame_size.x || position.y >= frame_size.y) return;
  const sampler_t sampler = CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP;
  float4 raw = read_imagef(frame, sampler, position);

  //Gamma correction
  const float inv_gamma = 1.0f/1.77777777f; //Use 1.77 as approx for gamma, as less 1s in binary rep.
  const float brightness = 2.0f;
  raw *= brightness/raw.w;
  raw.x = pow(raw.x, inv_gamma);
  raw.y = pow(raw.y, inv_gamma);
  raw.z = pow(raw.z, inv_gamma);

  raw *= 255.0f;
  uint4 out = {raw.x, raw.y, raw.z, 255};
  write_imageui(display_frame, position, out);
}

__kernel void clear_frame(__write_only image2d_t frame){
  int2 position = {get_global_id(0), get_global_id(1)};
  int2 frame_size = {get_image_width(frame), get_image_height(frame)};
  if(position.x >= frame_size.x || position.y >= frame_size.y) return;
  write_imagef(frame, position, BLACKF);
}
