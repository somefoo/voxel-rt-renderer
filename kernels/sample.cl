short read_3d(__read_only image3d_t raw, float3 position){
  const sampler_t sampler = CLK_FILTER_NEAREST | CLK_ADDRESS_CLAMP_TO_EDGE;
  float4 position4d_float = {position, 0.0f};           
  int4 position4d_int = {position.x, position.y, position.z, 0};
  //short value = read_imagei(raw, sampler, position4d_float).x; // CAUSES ISSUES
  short value = read_imagei(raw, sampler, position4d_int).x; // NO ISSUES
  return value;
}

float3 gradient(__read_only image3d_t raw, float3 position){
  float dx = 0.0f;
  float dy = 0.0f;
  float dz = 0.0f;
  const float3 x = {1.0f, 0.0f, 0.0f};
  const float3 y = {0.0f, 1.0f, 0.0f};
  const float3 z = {0.0f, 0.0f, 1.0f};

  const int r = 1;
  for(int zp = -r; zp <= r; zp++){
    for(int yp = -r; yp <= r; yp++){
      dx += read_3d(raw, position + zp*z + yp*y + x);
      dx -= read_3d(raw, position + zp*z + yp*y - x);
    }
  }

  for(int zp = -r; zp <= r; zp++){
    for(int xp = -r; xp <= r; xp++){
      dy += read_3d(raw, position + zp*z + xp*x + y);
      dy -= read_3d(raw, position + zp*z + xp*x - y);
    }
  }

  for(int yp = -r; yp <= r; yp++){
    for(int xp = -r; xp <= r; xp++){
      dz += read_3d(raw, position + yp*y + xp*x + z);
      dz -= read_3d(raw, position + yp*y + xp*x - z);
    }
  }
  
//  dx += read_3d(raw, position + x + y);
//  dx += read_3d(raw, position + x);
//  dx += read_3d(raw, position + x - y);

//  dx -= read_3d(raw, position - x + y);
//  dx -= read_3d(raw, position - x);
//  dx -= read_3d(raw, position - x - y);


//  dy += read_3d(raw, position + y + z);
//  dy += read_3d(raw, position + y );
//  dy += read_3d(raw, position + y - z);

//  dy -= read_3d(raw, position - y + z);
//  dy -= read_3d(raw, position - y);
//  dy -= read_3d(raw, position - y - z);


//  dz += read_3d(raw, position + z + y);
//  dz += read_3d(raw, position + z);
//  dz += read_3d(raw, position + z - y);

//  dz -= read_3d(raw, position - z + y);
//  dz -= read_3d(raw, position - z);
//  dz -= read_3d(raw, position - z - y);

  float3 grad = {dx, dy, dz};
  return grad;
}

float3 normal(__read_only image3d_t raw, float3 position){
  return normalize(gradient(raw,position));
}


#define RND_ACCURACY 4096
#define RND_ACCURACY_SUB RND_ACCURACY/2

//A modified hashing function inspired by:
//  http://www.burtleburtle.net/bob/hash/integer.html
uint hash(uint seed)
{
    seed = (seed ^ 61) ^ (seed >> 16);
    seed <<= 3;
    seed ^= (seed >> 4);
    seed *= 0xDEADBEEF;// :D
    seed ^= (seed >> 15);
    return seed;
}


//Return a sample of a point on the hemisphere towards normal
float3 get_hemisphere_direction(float3 normal, int seed){
  unsigned int useed = (unsigned int) seed + (get_global_id(0)+1)*(get_global_id(1)+1);
  int random_access_x = hash(useed * 0x182205bd);
  int random_access_y = hash(useed * 0xe8d052f3);
  int random_access_z = hash(useed * 0xf1981dcf);
  const float3 direction = {(random_access_x % RND_ACCURACY) - RND_ACCURACY_SUB, (random_access_y % RND_ACCURACY) - RND_ACCURACY_SUB, (random_access_z % RND_ACCURACY) - RND_ACCURACY_SUB};
  const float decider = dot(direction, normal);
  const float3 correct_direction = direction * decider;

  return normalize(correct_direction);
}

//Returns a sample of apoint on the hemisphere towards the normal
//The lower the roughness, the more samples will point towards the normal
//this is used to fake reflectiveness
float3 get_hemisphere_direction_reflective(float3 normal, int seed, float roughness){
  unsigned int useed = (unsigned int) seed + (get_global_id(0)+1)*(get_global_id(1)+1);
  int random_access_x = hash(useed * 0x182205bd);
  int random_access_y = hash(useed * 0xe8d052f3);
  int random_access_z = hash(useed * 0xf1981dcf);
  const float3 direction = {(random_access_x % RND_ACCURACY) - RND_ACCURACY_SUB, (random_access_y % RND_ACCURACY) - RND_ACCURACY_SUB, (random_access_z % RND_ACCURACY) - RND_ACCURACY_SUB};
  const float decider = dot(direction, normal);
  const float3 correct_direction = normalize(direction * decider);

  return normalize(normal*(1.0f - roughness) + correct_direction*(roughness));
}
