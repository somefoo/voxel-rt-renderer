#include <iostream>

#include <SDL2/SDL.h>
#include <imgui.h>
#include "imgui_config/imgui_impl_sdl.h"
#include "imgui_config/imgui_impl_opengl2.h"
#include <stdio.h>
#include <SDL.h>
#include <SDL_opengl.h>

#include "voxel_block.hpp"
#include <filesystem>

#include "renderer.hpp"
#include "state.hpp"

// Main code
int main(int argc, char** args)
{
    
    if(argc != 3){
      std::cerr << "Invalid arguments, please provide <nrrd> <image> args.\n";
      exit(1);
    }

    std::filesystem::path nrrd_file(args[1]);
    std::filesystem::path image_file(args[2]);

    if(!nrrd_file.has_filename() || !image_file.has_filename()){
      std::cerr << "Invalid arguments, ensure they are paths to files.\n";
      exit(1);
    }

    // Setup SDL
    // (Some versions of SDL before <2.0.10 appears to have performance/stalling issues on a minority of Windows systems,
    // depending on whether SDL_INIT_GAMECONTROLLER is enabled or disabled.. updating to latest version of SDL is recommended!)
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_GAMECONTROLLER) != 0)
    {
        printf("Error: %s\n", SDL_GetError());
        return -1;
    }

    // Setup window
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    SDL_WindowFlags window_flags = (SDL_WindowFlags)(SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    SDL_Window* window = SDL_CreateWindow("Voxel-RT-Viewer", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 720, window_flags);
    SDL_GLContext gl_context = SDL_GL_CreateContext(window);
    SDL_GL_MakeCurrent(window, gl_context);
    SDL_GL_SetSwapInterval(1); // Enable vsync

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    //ImGui::StyleColorsClassic();

    // Setup Platform/Renderer bindings
    ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    ImGui_ImplOpenGL2_Init();

    // Load Fonts
    // - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use ImGui::PushFont()/PopFont() to select them.
    // - AddFontFromFileTTF() will return the ImFont* so you can store it if you need to select the font among multiple.
    // - If the file cannot be loaded, the function will return NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    // - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling ImFontAtlas::Build()/GetTexDataAsXXXX(), which ImGui_ImplXXXX_NewFrame below will call.
    // - Read 'docs/FONTS.md' for more instructions and details.
    // - Remember that in C/C++ if you want to include a backslash \ in a string literal you need to write a double backslash \\ !
    //io.Fonts->AddFontDefault();
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Roboto-Medium.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/Cousine-Regular.ttf", 15.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/DroidSans.ttf", 16.0f);
    //io.Fonts->AddFontFromFileTTF("../../misc/fonts/ProggyTiny.ttf", 10.0f);
    //ImFont* font = io.Fonts->AddFontFromFileTTF("c:\\Windows\\Fonts\\ArialUni.ttf", 18.0f, NULL, io.Fonts->GetGlyphRangesJapanese());
    //IM_ASSERT(font != NULL);

    // Our state
    bool show_demo_window = false;
    bool show_another_window = false;
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);


///////////////////////////////////////////////////////////
    clw::context context;
    renderer scene_renderer(context, 1280,720);
    state scene(context, nrrd_file, image_file);
    ///////////////////////////////////////////////////////////
    
    bool moved_camera = false;

    static constexpr const auto global_up = std::array<float, 3>{0.0f, 1.0f, 0.0f};
    auto add = [](auto a, auto b){return std::array<float,3>{a[0] + b[0], a[1] + b[1], a[2] + b[2]};};
    auto sub = [](auto a, auto b){return std::array<float,3>{a[0] - b[0], a[1] - b[1], a[2] - b[2]};};
    auto mul = [](auto a, auto b){return std::array<float,3>{a[0] * b[0], a[1] * b[1], a[2] * b[2]};};
    auto adds = [](auto a, auto b){return std::array<float,3>{a[0] + b, a[1] + b, a[2] + b};};
    auto subs = [](auto a, auto b){return std::array<float,3>{a[0] - b, a[1] - b, a[2] - b};};
    auto muls = [](auto a, auto b){return std::array<float,3>{a[0] * b, a[1] * b, a[2] * b};};
    auto length = [](auto a){return std::sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2]);};
    auto normalize = [length](auto a){
      float len = length(a);   
      return std::array<float,3>{a[0]/len , a[1]/len, a[2]/len};
    };  
    auto cross = [](auto a, auto b){
      const float a0 = a[1]*b[2] - a[2]*b[1];
      const float a1 = a[2]*b[0] - a[0]*b[2];
      const float a2 = a[0]*b[1] - a[1]*b[0];
      return std::array<float, 3>{a0, a1, a2};
    };

    auto set_camera_orbit_position = [&](float theta, float phi){
      auto offset = std::array<float,3>{0.0f, 0.0f, 0.0f};
      const auto& current_target = scene.get_camera().get_target();
      const auto& current_position = scene.get_camera().get_position();
      const auto dir = normalize(sub(current_position, current_target));
      const float r = length(sub(current_position, current_target));

      offset[0] = current_target[0] + sin(theta)*cos(phi) * r;
      offset[2] = current_target[2] + sin(theta)*sin(phi) * r;
      offset[1] = current_target[1] + cos(theta)*r;
      scene.get_camera().set_position(offset);   
      moved_camera = true;
    };

    auto offset_camera_origin = [&](float horizontal, float vertical) {
      const auto& current_target = scene.get_camera().get_target();
      const auto& current_position = scene.get_camera().get_position();
      const auto dir = normalize(sub(current_position, current_target));

      const auto direction = normalize(sub(current_target, current_position));
      const auto tangent   = normalize(cross(direction, global_up));
      const auto up        = normalize(cross(direction, tangent));

      const auto new_position = add(add(current_position, muls(up, vertical)),muls(tangent, horizontal));
      const auto new_target = add(add(current_target, muls(up, vertical)),muls(tangent, horizontal));

      scene.get_camera().set_position(new_position);
      scene.get_camera().set_target(new_target);
      moved_camera = true;
    };


    auto offset_camera_target = [&](float depth) {
      const auto& current_target = scene.get_camera().get_target();
      const auto& current_position = scene.get_camera().get_position();
      const auto dir = normalize(sub(current_position, current_target));

      const auto direction = normalize(sub(current_target, current_position));
      const auto tangent   = normalize(cross(direction, global_up));
      const auto up        = normalize(cross(direction, tangent));

      const auto new_target = add(current_target, muls(direction, depth));

      scene.get_camera().set_target(new_target);
      moved_camera = true;
    };



    bool left_mouse_pressed = false;
    bool middle_mouse_pressed = false;
    bool right_mouse_pressed = false;
    float theta = 2.0f;
    float phi = 2.0f;
    set_camera_orbit_position(theta,phi);

    // Main loop
    bool done = false;
    while (!done)
    {
        // Poll and handle events (inputs, window resize, etc.)
        // You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
        // - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
        // - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
        // Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            ImGui_ImplSDL2_ProcessEvent(&event);
            if (event.type == SDL_QUIT)
                done = true;
            if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(window))
                done = true;
            if (event.type == SDL_MOUSEWHEEL){
              const auto& current_position = scene.get_camera().get_position(); 
              const auto& current_target = scene.get_camera().get_target(); 
              const auto dir = normalize(sub(current_position, current_target));
              if(event.wheel.y < 0){
                const auto new_position = add(current_position, muls(dir,4));
                if(length(sub(current_target, new_position)) > 10)
                scene.get_camera().set_position(new_position);
              }else{
                const auto new_position = sub(current_position, muls(dir,4));
                if(length(sub(current_target, new_position)) > 10)
                scene.get_camera().set_position(new_position);
              }
              moved_camera = true;
            }
            if (event.type == SDL_MOUSEBUTTONDOWN && event.button.button == SDL_BUTTON_LEFT){
              left_mouse_pressed = true; 
            }
            if (event.type == SDL_MOUSEBUTTONUP && event.button.button == SDL_BUTTON_LEFT){
              left_mouse_pressed = false; 
            }

            if (event.type == SDL_MOUSEBUTTONDOWN && event.button.button == SDL_BUTTON_RIGHT){
              right_mouse_pressed = true; 
            }
            if (event.type == SDL_MOUSEBUTTONUP && event.button.button == SDL_BUTTON_RIGHT){
              right_mouse_pressed = false; 
            }

            if (event.type == SDL_MOUSEBUTTONDOWN && event.button.button == SDL_BUTTON_MIDDLE){
              middle_mouse_pressed = true; 
            }
            if (event.type == SDL_MOUSEBUTTONUP && event.button.button == SDL_BUTTON_MIDDLE){
              middle_mouse_pressed = false; 
            }
            if(event.type == SDL_MOUSEMOTION && left_mouse_pressed){
              theta -= (float)event.motion.yrel / 1000.0f;
              theta = std::clamp(theta,0.00001f, 3.14159f);
              phi += (float)event.motion.xrel / 1000.0f;
              set_camera_orbit_position(theta, phi);
            }

            if(event.type == SDL_MOUSEMOTION && right_mouse_pressed){
              float direction = -(float)event.motion.yrel / 10.0f;
              offset_camera_target(direction);
            }

            if(event.type == SDL_MOUSEMOTION && middle_mouse_pressed){
              offset_camera_origin(-(float)event.motion.xrel / 5.0f, -(float)event.motion.yrel / 5.0f);
            }
        }

        // Start the Dear ImGui frame
        ImGui_ImplOpenGL2_NewFrame();
        ImGui_ImplSDL2_NewFrame(window);
        ImGui::NewFrame();

        // 2. Show a simple window that we create ourselves. We use a Begin/End pair to created a named window.
        {
            static float f = 0.0f;
            static int counter = 0;

            ImGui::Begin("Dev-Tools");                          // Create a window called "Hello, world!" and append into it.
            if (ImGui::Button("Reload Shader")){                           // Buttons return true when clicked (most widgets return true when edited/activated)
              std::cout << "Reloading shader...\n"; 
              scene_renderer.reload();
              moved_camera = true;
            }
            if (ImGui::Button("Reload Scene")){
              std::cout << "Reloading scene...\n";
              auto& ct = scene.get_camera().get_target();
              auto& cp = scene.get_camera().get_position();
              std::array<float,3> position{cp[0], cp[1],cp[2]};
              std::array<float,3> target{ct[0], ct[1],ct[2]};
              scene = state(context, nrrd_file, image_file);
              scene.get_camera().set_position(position);
              scene.get_camera().set_target(target);
              moved_camera = true;
            }

            ImGui::Text("Frame time %.2f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
            auto& cp = scene.get_camera().get_position();
            auto& ct = scene.get_camera().get_target();
            ImGui::Text("Camera Position: (%.2f, %.2f, %.2f)", cp[0],cp[1],cp[2]);
            ImGui::Text("Camera Target  : (%.2f, %.2f, %.2f)", ct[0],ct[1],ct[2]);
            ImGui::End();
        }

				glViewport(0, 0, (int)io.DisplaySize.x, (int)io.DisplaySize.y);
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);

        const float rx = ((static_cast <float> (rand()) / static_cast <float> (RAND_MAX)) - 0.5f)/1000;
        const float ry = ((static_cast <float> (rand()) / static_cast <float> (RAND_MAX)) - 0.5f)/1000;
        const float rz = ((static_cast <float> (rand()) / static_cast <float> (RAND_MAX)) - 0.5f)/1000;

        auto cp = scene.get_camera().get_position();
        auto ct = scene.get_camera().get_target();

        //cp[0] += rx;
        //ct[0] += rx;
        //cp[1] += ry;
        //ct[1] += ry;
        //cp[2] += rz;
        //ct[2] += rz;

				scene_renderer.render(scene, moved_camera);
        moved_camera = false;

        // Rendering
        ImGui::Render();

        //glUseProgram(0); // You may want this if using this code in an OpenGL 3+ context where shaders may be bound
        ImGui_ImplOpenGL2_RenderDrawData(ImGui::GetDrawData());
        SDL_GL_SwapWindow(window);
    }

    // Cleanup
    ImGui_ImplOpenGL2_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();

    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
