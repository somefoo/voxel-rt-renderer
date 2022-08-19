#clw_include_once "marching.cl"

__kernel void find_transition(__read_only image3d_t raw, __write_only image3d_t transition, int maximum_iteration_count){
  int4 position = {get_global_id(0), get_global_id(1), get_global_id(2), 0};
  int4 volume_size = get_image_dim(raw);
  if(position.x >= volume_size.x || position.y >= volume_size.y || position.z >= volume_size.z){
    return;
  }

/*
  if(position.x == volume_size.x - 1|| position.y == volume_size.y - 1 || position.z == volume_size.z - 1){
    write_imagei(transition, position, 1);
    return;
  }

  if(position.x * position.y * position.z == 0){
    write_imagei(transition, position, 1);
    return;
  }
*/

  

  struct ray r = {{position.x, position.y, position.z},{0,0,0}};
  struct event event_information = test_event(raw, r);
  short mask_value = 1 - (event_information.type == Hit) * 2; //-1 inside, 1 outside
  if(mask_value == 1){
    write_imagei(transition, position, maximum_iteration_count);
    return;
  }

  int border = 0;
  const int radius = 2;

  for(int z = - radius; z <= radius; ++z) 
    for(int y = - radius; y <= radius; ++y) 
      for(int x = - radius; x <= radius; ++x){
        if(z == 0 && y == 0 && x == 0) continue;
        struct ray r = {{position.x + x, position.y + y, position.z + z},{0,0,0}};
        border += test_event(raw, r).type != Hit;
      }
/*
  r.origin.x -= 1;
  border += test_event(raw, r).type != Hit;
  r.origin.x += 2;
  border += test_event(raw, r).type != Hit;
  r.origin.x -= 1;

  r.origin.y -= 1;
  border += test_event(raw, r).type != Hit;
  r.origin.y += 2;
  border += test_event(raw, r).type != Hit;
  r.origin.y -= 1;

  r.origin.z -= 1;
  border += test_event(raw, r).type != Hit;
  r.origin.z += 2;
  border += test_event(raw, r).type != Hit;
  r.origin.z -= 1;
  */

  if(border != 0) mask_value = 0;
  write_imagei(transition, position, mask_value * maximum_iteration_count);
}

__kernel void grow(__read_only image3d_t last, __write_only image3d_t current, int maximum_iteration_count, int step){
  int4 position = {get_global_id(0), get_global_id(1), get_global_id(2), 0};
  int4 volume_size = get_image_dim(current);
  if(position.x >= volume_size.x - 1 || position.y >= volume_size.y - 1 || position.z >= volume_size.z - 1){
    return;
  }else if(position.x * position.y * position.z == 0){
    return;
  }
  const sampler_t sampler = CLK_FILTER_NEAREST | CLK_ADDRESS_CLAMP;

  short last_colour = read_imagei(last, sampler, position).x;


  int coeff = last_colour < 0 ? -1 : 1;

  if(last_colour == coeff*(step + 1)){
      write_imagei(current, position, coeff * (step + 1)); 
      return;
    }
    if(last_colour != coeff * maximum_iteration_count) return;

    
    int4 x = {1.0f,0.0f,0.0f,0.0f};
    int4 y = {0.0f,1.0f,0.0f,0.0f};
    int4 z = {0.0f,0.0f,1.0f,0.0f};
    int4 p = position;
    int paint = 0;
    paint += read_imagei(last, sampler, position + x).x == coeff * step; 
    paint += read_imagei(last, sampler, position - x).x == coeff * step; 
    paint += read_imagei(last, sampler, position + y).x == coeff * step; 
    paint += read_imagei(last, sampler, position - y).x == coeff * step; 
    paint += read_imagei(last, sampler, position + z).x == coeff * step; 
    paint += read_imagei(last, sampler, position - z).x == coeff * step; 

    //Check corners, does it improve the results?
    paint += read_imagei(last, sampler, position + y + x + z).x == coeff * step;
    paint += read_imagei(last, sampler, position + y - x + z).x == coeff * step;
    paint += read_imagei(last, sampler, position + y + x - z).x == coeff * step;
    paint += read_imagei(last, sampler, position + y - x - z).x == coeff * step;
    paint += read_imagei(last, sampler, position - y + x + z).x == coeff * step;
    paint += read_imagei(last, sampler, position - y - x + z).x == coeff * step;
    paint += read_imagei(last, sampler, position - y + x - z).x == coeff * step;
    paint += read_imagei(last, sampler, position - y - x - z).x == coeff * step;

    if(paint){
      write_imagei(current, position, coeff * (step + 1)); 
    }
}


__kernel void clean_edges(__read_only image3d_t last, __write_only image3d_t current, int maximum_iteration_count){
  int4 position = {get_global_id(0), get_global_id(1), get_global_id(2), 0};
  int4 volume_size = get_image_dim(current);
  if(position.x >= volume_size.x || position.y >= volume_size.y || position.z >= volume_size.z){
    return;
  }

  if(position.x == volume_size.x - 1 || position.y == volume_size.y - 1|| position.z == volume_size.z - 1){
    write_imagei(current, position, 0); 
  }
  else if(position.x * position.y * position.z == 0){
    write_imagei(current, position, 0); 
  }
}
