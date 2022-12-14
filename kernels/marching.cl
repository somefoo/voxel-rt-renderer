#clw_include_once "sample.cl"

struct ray{
  float3 origin; //Origin
  float3 direction; //Direction
};

#clw_include_once "intersect.cl"

enum event_type{
  None,
  Hit,
  Exit_volume
};

struct event{
  enum event_type type;
  short value;
  short steps;
};

struct event test_event(__read_only image3d_t raw, struct ray current){
  struct event e = {None, 0, 0};
  if(outside_volume(raw, current)){
    e.type = Exit_volume;
    return e;
  }

  short value = read_3d(raw, current.origin);
  

  if(value > -700){
    e.type = Hit;
  }

  e.value = value;
  return e;
}

struct event test_event_sdf(__read_only image3d_t raw, __read_only image3d_t signed_distance_field, struct ray current){
  short value_sdf = read_3d(signed_distance_field, current.origin);

  struct event e = {None, 0, 0};
  if(value_sdf == 0){
    e = test_event(raw, current);
    if(e.type == Hit){
      return e;  
    }
  }

  e.value = value_sdf;
  return e;
}

struct ray march_step_size(struct ray current, float step_size){
  step_size = max(1.0f, fabs(step_size) * 1.0f);
  const struct ray ret = {current.origin + current.direction*step_size, current.direction};
  return ret;
}

/*
struct ray march(struct ray current, __read_only image3d_t signed_distance_field){
  const sampler_t sampler = CLK_FILTER_NEAREST | CLK_ADDRESS_CLAMP;
  const float4 pf = {current.origin, 0.0f};
  const int4 position = {pf.x, pf.y, pf.z, 0};
  const float step_size = max(1.0f,(float) read_imagei(signed_distance_field, sampler, position).x * 1.0f);
  //const float step_size = 1.0f;
  const struct ray ret = {current.origin + current.direction*step_size, current.direction};
  return ret;
}
*/

struct ray next_event(__read_only image3d_t raw, __read_only image3d_t signed_distance_field, struct ray current, struct event *event_type, int random_seed){
  struct event current_event = {None, 0, 0};


  if(outside_volume(raw, current)){
    struct intersection val = intersect_box(raw, current);
    if(!val.intersected){
      *event_type = current_event;
      return current;
    }
    float random_offset = (float)(random_seed % 4096)/4096.0f;
    current.origin = current.origin + val.distance*current.direction + current.direction*random_offset*1.0f;
    //current.origin = current.origin + val.distance*current.direction;
  }else{
    //int my_random = random_seed + get_global_id(0) + get_global_id(1);
    //float random_multiplier = 1.0f + (float)((my_random) % 1024)/1024.0f/1000.0f;
    //current.direction = normalize(current.direction)*random_multiplier;


  }


  short mode_decider = read_3d(signed_distance_field, current.origin);
  if(mode_decider < 0){
    //Transmission-Mode
    float step_size = 1.0f;
    for(int t = 0; t < 80; ++t){
      current = march_step_size(current, step_size);
      current_event = test_event_sdf(raw, signed_distance_field, current);

      //March until we leave the object
      if(current_event.type == Hit){
        step_size = 1.0f;
        continue;
      }

      //Walk one step back, so we are on the surface
      current.origin = current.origin - current.direction;
      current_event = test_event_sdf(raw, signed_distance_field, current);

      current_event.steps = t;
      *event_type = current_event;
      return current;
    }





  }else{
    //current = march(current, signed_distance_field); 
    float step_size = 1.0f;
    for(int t = 0; t < 80; ++t){
      current = march_step_size(current, step_size);
      current_event = test_event_sdf(raw, signed_distance_field, current);
      if(current_event.type == None){
        step_size = current_event.value;
        continue;
      }
      current_event.steps = t;
      *event_type = current_event;
      return current;
    }
  }

  *event_type = current_event;
  return current;
}

struct ray generate_ray(__constant float* position, __constant float* target, int2 local_id, int2 size){
  const float3 global_up = {0.0f, 1.0f, 0.0f};
  float3 c_pos = {position[0], position[1], position[2]};
  float3 c_tar = {target[0], target[1], target[2]};

  float3 direction = normalize(c_tar - c_pos);
  float3 tangent =   normalize(cross(direction, global_up));
  float3 up =        -normalize(cross(direction, tangent)); 

  float3 view_plane_centre = direction;
  const float aspect_ratio = (float) size.x / (float) size.y;
  const float x_offset = (float)(local_id.x - size.x/2) / (float) size.x * aspect_ratio;
  const float y_offset = (float)(local_id.y - size.y/2) / (float) size.y;

  const float3 view_point_on_plane = normalize(view_plane_centre + x_offset * tangent + y_offset * up);

  struct ray r;
  r.origin = c_pos;
  r.direction = view_point_on_plane;
  return r;
}

struct ray generate_ray_depth(__constant float* position, __constant float* target, int2 local_id, int2 size, float strength, int random_seed){

  const int unique_id = get_global_id(0) + get_global_id(1)*881;
  const float seed_x = hash((random_seed + unique_id)) % 4096;
  const float seed_y = hash(random_seed + unique_id + 31) % 4096;
  float x_blur = ((seed_x / 4096.0f) - 0.5f)*strength;
  float y_blur = ((seed_y / 4096.0f) - 0.5f)*strength;


  const float3 global_up = {0.0f, 1.0f, 0.0f};
  float3 c_pos = {position[0] , position[1] , position[2] };
  //float3 c_pos = {position[0] + x_blur, position[1] + y_blur, position[2] + z_blur};
  float3 c_tar = {target[0], target[1], target[2]};

  float3 direction = normalize(c_tar - c_pos);
  float3 tangent =   normalize(cross(direction, global_up));
  float3 up =        -normalize(cross(direction, tangent)); 

  //Move camera a little
  c_pos = c_pos + tangent * x_blur + up * y_blur;
  direction = normalize(c_tar - c_pos);
  tangent =   normalize(cross(direction, global_up));
  up =        -normalize(cross(direction, tangent)); 



  float3 view_plane_centre = direction;
  const float aspect_ratio = (float) size.x / (float) size.y;
  const float x_offset = (float)(local_id.x - size.x/2) / (float) size.x * aspect_ratio;
  const float y_offset = (float)(local_id.y - size.y/2) / (float) size.y;

  const float3 view_point_on_plane = normalize(view_plane_centre + x_offset * tangent + y_offset * up);

  struct ray r;
  r.origin = c_pos;
  r.direction = view_point_on_plane;
  return r;
}
