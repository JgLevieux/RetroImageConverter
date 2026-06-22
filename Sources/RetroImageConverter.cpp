#include <SDL3/SDL_main.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL3_image/SDL_image.h>
#include <imgui-master/imgui.h>
#include <imgui-master/backends/imgui_impl_sdl3.h>
#include <imgui-master/backends/imgui_impl_sdlrenderer3.h>

int main(int argc, char* argv[])
{
    // 1. Initialisation SDL 3
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD))
    {
        SDL_Log("Erreur SDL_Init: %s", SDL_GetError());
        return -1;
    }

    // Création de la fenêtre et du renderer en une étape (Spécifique SDL3)
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    float fBaseWidthRenderer = 1920.0f;
    float fBaseHeightRenderer = 1080.0f;
    if (!SDL_CreateWindowAndRenderer("Retro Image Converter", (int)(fBaseWidthRenderer), (int)(fBaseHeightRenderer), SDL_WINDOW_RESIZABLE, &window, &renderer))
    {
        SDL_Log("Erreur Window/Renderer: %s", SDL_GetError());
        return -1;
    }

    SDL_SetRenderVSync(renderer, 1);

    // 2. Initialisation ImGui
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    ImGui::StyleColorsDark();

    // Backends spécifiques à la SDL 3
    ImGui_ImplSDL3_InitForSDLRenderer(window, renderer);
    ImGui_ImplSDLRenderer3_Init(renderer);

    bool running = true;
    while (running)
    {
        // Début de frame ImGui
        ImGui_ImplSDLRenderer3_NewFrame();
        ImGui_ImplSDL3_NewFrame();
        ImGui::NewFrame();

        // Interface
        ImGui::Begin("Debug");

        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            ImGui_ImplSDL3_ProcessEvent(&event);

            if (event.type == SDL_EVENT_QUIT)
                running = false;
        }
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
        ImGui::End();
        ImGui::Render();
        ImGui_ImplSDLRenderer3_RenderDrawData(ImGui::GetDrawData(), renderer);
        SDL_RenderPresent(renderer);

    }

    // Nettoyage
    ImGui_ImplSDLRenderer3_Shutdown();
    ImGui_ImplSDL3_Shutdown();
    ImGui::DestroyContext();
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}

