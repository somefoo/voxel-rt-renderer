#clw_include_once "marching.cl"
#clw_include_once "environment_map.cl"
#clw_include_once "shader.cl"

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

void debug_draw(__write_only image2d_t current,
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

  //Draw little slice-preview in bottom left corner
  if(position.x < get_image_width(raw) && position.y < get_image_height(raw)){
    float3 cam_pos = {camera_position[0], camera_position[1], camera_position[2]};
    float3 cam_tar = {camera_target[0], camera_target[1], camera_target[2]};
    float4 position_4d = {position.x, position.y, clamp(length(cam_pos - cam_tar) / 2, 0.0f, (float)get_image_depth(raw) - 1), 0};
    int4 slice_color = read_imagei(raw, sampler, position_4d);
    if(slice_color.x >= -200){
    float s = 3000.0f;
    float4 slice_colorf = {slice_color.x/s, slice_color.x/s, slice_color.x/s, 1};
    write_imagef(current, position, slice_colorf);
    }
  }

  //Draw little slice-preview for the SDF
  if(position.x > get_image_width(raw) && position.x < 2*get_image_width(raw) && position.y < get_image_height(raw)){
    float3 cam_pos = {camera_position[0], camera_position[1], camera_position[2]};
    float3 cam_tar = {camera_target[0], camera_target[1], camera_target[2]};
    float4 position_4d = {position.x - get_image_width(raw), position.y, clamp(length(cam_pos - cam_tar)/2, 0.0f, (float)get_image_depth(raw) - 1), 0};
    int4 slice_color = read_imagei(signed_distance_field, sampler, position_4d);
    if(slice_color.x > 0){
    float s = 128.0f;
    float4 slice_colorf = {slice_color.x/s, slice_color.x/s, slice_color.x/s, 1};
    write_imagef(current, position, slice_colorf);
    }else if(slice_color.x == 0){
      write_imagef(current, position, (float4){1.0f, 0.0f, 0.0f,1.0f});
    }else{
      float s = 128.0f;
      float4 slice_colorf = {0, -slice_color.x/s, -slice_color.x/s, 1};
      write_imagef(current, position, slice_colorf);
    }
  }
}
