#pragma once
#include <clw_image.hpp>
#include <clw_vector.hpp>
#include <clw_context.hpp>
#include <filesystem>
#include "io/nrrd_loader.hpp"
#include "precomputer.hpp"

#include <vector>
class voxel_block{
  public:
  voxel_block(clw::context& context, volume_block&& block):
    m_raw_image(context, std::move(block.m_voxels), {block.m_voxel_count_x, block.m_voxel_count_y, block.m_voxel_count_z}, true),
//    m_lighting_cache_image(context, {block.m_voxel_count_x, block.m_voxel_count_y, block.m_voxel_count_z}, false),
    m_signed_distance_field_image(context, {block.m_voxel_count_x, block.m_voxel_count_y, block.m_voxel_count_z}, true),
    m_position(context, {0.0f, 0.0f, 0.0f}, true),
    m_rotation(context, {0.0f, 0.0f, 0.0f}, true),
    m_scale(context,    {block.m_voxel_size_x, block.m_voxel_size_y, block.m_voxel_size_z}, true),
    m_precomputer(context)
    {
      m_precomputer.compute_signed_distance_field(m_raw_image, m_signed_distance_field_image);
    }

  voxel_block(clw::context& context, std::size_t width, std::size_t height, std::size_t depth):
    m_raw_image(context, {width, height, depth}, false),
 //   m_lighting_cache_image(context, {width, height, depth}, false),
    m_signed_distance_field_image(context, {width, height, depth}, false),
    m_position(context, {0.0f, 0.0f, 0.0f}, true),
    m_rotation(context, {0.0f, 0.0f, 0.0f}, true),
    m_scale(context,    {1.0f, 1.0f, 1.0f}, true),
    m_precomputer(context)
    {
      m_precomputer.compute_signed_distance_field(m_raw_image, m_signed_distance_field_image);
    }

  auto& get_raw() const{
    return m_raw_image;
  }

//  auto& get_lighting_cache(){
//    return m_signed_distance_field_image;
//  } 

  auto& get_signed_distance_field(){
    return m_signed_distance_field_image;
  }

  auto& get_signed_distance_field() const{
    return m_signed_distance_field_image;
  }

  auto& get_position(){
    return m_position;
  }

  auto& get_rotation(){
    return m_rotation;
  }

  auto& get_scale() const{
    return m_scale;
  }

  private:
  const static constexpr std::size_t RAW_CHANNEL_COUNT = 1;
  clw::image<short,RAW_CHANNEL_COUNT> m_raw_image;
  //clw::image<float,4> m_lighting_cache_image;
  clw::image<short,1> m_signed_distance_field_image;
  clw::vector<float> m_position;
  clw::vector<float> m_rotation;
  clw::vector<float> m_scale;
  precomputer m_precomputer;
};

