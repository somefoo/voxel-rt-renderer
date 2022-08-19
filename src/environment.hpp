#pragma once
#include <clw_image.hpp>
#include <clw_context.hpp>
#include "io/image_loader.hpp"

#include <vector>
class environment{
  public:
  
  environment(clw::context& context, image&& img):
    m_environment_map(context, std::move(img.m_pixels), {img.m_width, img.m_height, 1}, true)
    {
  
    }

  const auto& get_environment_map() const{
    return m_environment_map;
  }

  private:
  clw::image<float,4> m_environment_map;
};

