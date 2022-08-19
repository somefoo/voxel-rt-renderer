#pragma once
#include "image.hpp"
#include <string>

class image_loader{
  public:
  static image load_file(std::string path);
};
