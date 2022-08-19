#define STB_IMAGE_IMPLEMENTATION
#include "image_loader.hpp"
#include "stb_image.hpp"
#include "image.hpp"
#include <vector>
#include <iostream>

image image_loader::load_file(std::string path) {
  int width, height, n;
  stbi_info(path.data(), &width, &height, &n);

  stbi_hdr_to_ldr_gamma(2.2f); 
  stbi_hdr_to_ldr_scale(1.0f);
  float *data = stbi_loadf(path.data(), &width, &height, &n, 4);
  n = 4; //Problem with stb?
  if(data == NULL){
    std::cerr << "Error, failed to load file: " + path << "\n";
    exit(1);
  
  }
  std::vector<float> image_data(data, data + width*height*n);

  stbi_image_free(data);
  return image(std::move(image_data), width, height, n);
}
