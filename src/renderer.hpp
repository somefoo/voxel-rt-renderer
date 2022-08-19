#pragma once

#include "state.hpp"
#include "frame.hpp"
#include <clw_context.hpp>
#include <clw_function.hpp>

class renderer{
  public:
  renderer(clw::context& context, std::size_t width, std::size_t height):
    m_frame(context),
    m_display_buffer(context, {width, height, 1}, true),
    m_raw_buffer_ping(context, {width, height, 1}, true),
    m_raw_buffer_pong(context, {width, height, 1}, true),
    m_cl_renderer(context, "renderer.cl", "render"),
    m_cl_update_frame(context, "renderer.cl", "update_display_frame"),
    m_cl_clear_frame(context, "renderer.cl", "clear_frame")
  {}

  void render(const state& state_to_render, bool clear_first = false){

    auto& current_buffer = (m_frame_counter % 2 == 0) ? m_raw_buffer_ping : m_raw_buffer_pong;
    auto& last_buffer    = (m_frame_counter % 2 == 0) ? m_raw_buffer_pong : m_raw_buffer_ping;
    m_frame_counter+=1;

    if(clear_first){
      m_cl_clear_frame.execute({2048,1024}, {16,16,1}, last_buffer); 
    }

    //TODO This is an expensive copy!! 
    auto cp = state_to_render.get_camera().get_position();
    auto ct = state_to_render.get_camera().get_target();
    const float rx = ((static_cast <float> (rand()) / static_cast <float> (RAND_MAX)) - 0.5f)/0.2;
    const float ry = ((static_cast <float> (rand()) / static_cast <float> (RAND_MAX)) - 0.5f)/0.2;
    const float rz = ((static_cast <float> (rand()) / static_cast <float> (RAND_MAX)) - 0.5f)/0.2;

    /*
    if(!clear_first){
    cp[0] += rx;
    //ct[0] += rx;
    cp[1] += ry;
    //ct[1] += ry;
    cp[2] += rz;
    //ct[2] += rz;
    cp.push();
    ct.push();
    }
    */



    int random_seed = std::rand();
    m_cl_renderer.execute({2048,1024}, {16,16,1},
        current_buffer,
        last_buffer,
        state_to_render.get_block().get_raw(),
        state_to_render.get_block().get_signed_distance_field(),
        state_to_render.get_block().get_scale(),
        state_to_render.get_environment().get_environment_map(),
        cp,
        ct,
        //state_to_render.get_camera().get_position(),
        //state_to_render.get_camera().get_target(),
        random_seed
        );


    m_cl_update_frame.execute({2048,1024},{16,16,1}, current_buffer, m_display_buffer, 1);
    m_display_buffer.pull();
    m_frame.draw(m_display_buffer);
  }

  void reload(){
    try{
      m_cl_renderer.reload();
      m_cl_update_frame.reload();
      m_cl_clear_frame.reload();
    }catch(std::runtime_error e){
    }
  }

  private:
    frame m_frame;
    clw::image<unsigned char, 4> m_display_buffer;
    clw::image<float, 4> m_raw_buffer_ping;
    clw::image<float, 4> m_raw_buffer_pong;
    clw::function m_cl_renderer;
    clw::function m_cl_update_frame;
    clw::function m_cl_clear_frame;
    std::size_t m_frame_counter = 0;
};
