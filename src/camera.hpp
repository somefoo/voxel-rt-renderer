#pragma once
#include <array>
#include <clw_vector.hpp>

class camera{
  public:
  camera(clw::context& context): m_position(context, 3, true), m_target(context, 3, false){
    m_position[0] = 0.0f;
    m_position[1] = 0.0f;
    m_position[2] = 500.0f;
    m_target[0] = 0.0;
    m_target[1] = 0.0;
    m_target[2] = 0.0;
    m_position.push();
    m_target.push();
  }

  void set_position(const std::array<float, 3>& position){
    m_position[0] = position[0];
    m_position[1] = position[1];
    m_position[2] = position[2];
    m_position.push();
  }

  void set_target(const std::array<float, 3>& target){
    m_target[0] = target[0];
    m_target[1] = target[1];
    m_target[2] = target[2];
    m_target.push();
  }
  
  auto& get_position() const{
    return m_position; 
  }

  auto& get_target() const{
    return m_target; 
  }
  
  private:
    static constexpr const std::array<float, 3> up{0.0f, 1.0f, 0.0f};
    clw::vector<const float> m_position;
    clw::vector<const float> m_target;
};
