float4 sample_environment_map(struct ray current, __read_only image2d_t environment_map){
  const sampler_t smp = CLK_FILTER_LINEAR | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_NORMALIZED_COORDS_TRUE;
  const float aspect = get_image_width(environment_map)/get_image_height(environment_map);
  const float2 inverse_pi_factor = {0.1591549431f, 0.318309886f};
  const float2 offset = {0.5f, 0.5f};
  float2 uv_coordinate = {atan2(current.direction.x,current.direction.z), asin(-current.direction.y)};
  uv_coordinate *= inverse_pi_factor;
  uv_coordinate += offset;
  const float4 read_colour = read_imagef(environment_map, smp, uv_coordinate);
  return read_colour;
}


uint4 sample_environment_map_ui(struct ray current, __read_only image2d_t environment_map){
  const sampler_t smp = CLK_FILTER_LINEAR | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_NORMALIZED_COORDS_TRUE;
  const float aspect = get_image_width(environment_map)/get_image_height(environment_map);
  const float2 inverse_pi_factor = {0.1591549431f, 0.318309886f};
  const float2 offset = {0.5f, 0.5f};
  float2 uv_coordinate = {atan2(current.direction.x,current.direction.z), asin(-current.direction.y)};
  uv_coordinate *= inverse_pi_factor;
  uv_coordinate += offset;
  //const float4 read_colour = read_imagef(environment_map, smp, uv_coordinate);
  const uint4 read_colour = read_imageui(environment_map, smp, uv_coordinate);
  return read_colour;
}
