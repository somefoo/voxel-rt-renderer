inline bool outside_volume(__read_only image3d_t raw, struct ray current){
  const int3 size = {get_image_width(raw), get_image_height(raw), get_image_depth(raw)};
  const float3 position = current.origin;
  const bool exited_max = size.x < position.x | size.y < position.y | size.z < position.z;
  const bool exited_min = position.x < 0 | position.y < 0 | position.z < 0;
  return exited_max | exited_min;
}

struct intersection{
  bool intersected;
  float distance;
};

struct intersection intersect_box(__read_only image3d_t raw, struct ray current){
  const float3 aabb_max = {get_image_width(raw), get_image_height(raw), get_image_depth(raw)};
  const float3 aabb_min = {0.0f, 0.0f, 0.0f};
  float ia[9];
  ia[0] = (aabb_min.x - current.origin.x)/current.direction.x;
  ia[1] = (aabb_max.x - current.origin.x)/current.direction.x;

  ia[2] = (aabb_min.y - current.origin.y)/current.direction.y;
  ia[3] = (aabb_max.y - current.origin.y)/current.direction.y;


  ia[4] = (aabb_min.z - current.origin.z)/current.direction.z;
  ia[5] = (aabb_max.z - current.origin.z)/current.direction.z;

  ia[6] = fmax(fmax(fmin(ia[0], ia[1]),fmin(ia[2],ia[3])),fmin(ia[4],ia[5]));
  ia[7] = fmin(fmin(fmax(ia[0], ia[1]),fmax(ia[2],ia[3])),fmax(ia[4],ia[5]));

  struct intersection ret_intersection;
  if(ia[7] < 0 || ia[6] > ia[7]){
    ret_intersection.intersected = false;
  }else{
    ret_intersection.distance = ia[6];
    ret_intersection.intersected = true;
  }
  return ret_intersection;
}
