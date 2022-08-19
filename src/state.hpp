#pragma once
#include <clw_image.hpp>
#include <clw_context.hpp>
#include <vector>

#include "voxel_block.hpp"
#include "environment.hpp"
#include "camera.hpp"
#include "io/nrrd_loader.hpp"
#include <filesystem>

class state{
  public:
  state(clw::context& context, std::filesystem::path data_set, std::filesystem::path background):
  m_block(context, nrrd_loader::load_file(data_set)),
  m_environment(context, image_loader::load_file(background)),
  m_camera(context)
  {};

  const auto& get_block() const{ 
    return m_block;
  }
  auto& get_block(){ 
    return m_block;
  }
  const auto& get_camera() const{
    return m_camera;
  }
  auto& get_camera(){
    return m_camera;
  }
  const auto& get_environment() const{
    return m_environment;
  }
  auto& get_environment(){
    return m_camera;
  }

  private:
  voxel_block m_block;
  camera m_camera;
  environment m_environment;
};
