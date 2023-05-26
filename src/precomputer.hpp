#pragma once

#include <clw_image.hpp>
#include <clw_precompiled_function.hpp>

class precomputer{
  public:
  precomputer(clw::context& context):
    m_cl_find_transition(context, "signed_distance_field", "find_transition"),
    m_cl_grow(context, "signed_distance_field", "grow"),
    m_cl_clean_edges(context, "signed_distance_field", "clean_edges")
  {}

  void compute_signed_distance_field(clw::image<short>& raw, clw::image<short>& signed_distance_field){
    auto s = raw.get_dimensions();
    auto b = raw.get_dimensions();

    //This is slow, but works for now
    constexpr const int iteration_count = 128;
    m_cl_find_transition.execute({640,640,640}, {4,4,4}, raw, signed_distance_field, iteration_count);
    signed_distance_field.pull();
    auto host_copy = signed_distance_field.host_copy(true /*push*/);

    for(int i = 0; i < iteration_count; ++i){
      m_cl_grow.execute({640,640,640}, {4,4,4},signed_distance_field, host_copy, iteration_count, i);
      m_cl_grow.execute({640,640,640}, {4,4,4},host_copy, signed_distance_field, iteration_count, i);
    }

    m_cl_clean_edges.execute({640,640,640}, {4,4,4},host_copy, signed_distance_field, iteration_count);

  }

  void reload(){
    //try{
    //  m_cl_find_transition.reload();
    //}catch(std::runtime_error e){
    //}
  }

  private:
    clw::function m_cl_find_transition;
    clw::function m_cl_grow;
    clw::function m_cl_clean_edges;
};
