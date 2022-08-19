#pragma once
#include <GL/gl.h>
#include "clw_image.hpp"

class frame{
  public:
  frame(clw::context& context)
  {
    glGenTextures(1, m_texture); 
    glBindTexture(GL_TEXTURE_2D, m_texture[0]);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  }

  ~frame(){
    glDeleteTextures(1, m_texture);
  }

  void draw(const clw::image<unsigned char, 4>& buffer_object){
    const auto size = buffer_object.get_dimensions();

    //Push to OGL context
    glBindTexture(GL_TEXTURE_2D, m_texture[0]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size[0], size[1], 0, GL_RGBA, GL_UNSIGNED_BYTE, &buffer_object[0]);
 
    //Draw to frame
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, m_texture[0]);
    glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex2f(-1, -1);
    glTexCoord2f(0, 1); glVertex2f(-1, 1);
    glTexCoord2f(1, 1); glVertex2f(1, 1);
    glTexCoord2f(1, 0); glVertex2f(1, -1);
    glEnd();
    glDisable(GL_TEXTURE_2D);

  
  }

  private:
  GLuint m_texture[1];
};
