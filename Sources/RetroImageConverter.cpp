#include <windows.h>
#include <commdlg.h>
#include <string>
#include <SDL3/SDL_main.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL3_image/SDL_image.h>
#include <imgui-master/imgui.h>
#include <imgui-master/backends/imgui_impl_sdl3.h>
#include <imgui-master/backends/imgui_impl_sdlrenderer3.h>

#include "Sources/SinclairQL.h"

std::string OpenWindowsFileDialog();
std::string SaveWindowsFileDialog();

static std::string filePath;
static SDL_Surface* pSurface = nullptr;
static bool bValidSurfaceLoaded = false;

int main(int argc, char* argv[])
{
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD))
    {
        SDL_Log("Erreur SDL_Init: %s", SDL_GetError());
        return -1;
    }

    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    float fBaseWidthRenderer = 512.0f;
    float fBaseHeightRenderer = 512.0f;
    if (!SDL_CreateWindowAndRenderer("Retro Image Converter", (int)(fBaseWidthRenderer), (int)(fBaseHeightRenderer), SDL_WINDOW_RESIZABLE, &window, &renderer))
    {
        SDL_Log("Erreur Window/Renderer: %s", SDL_GetError());
        return -1;
    }

    SDL_SetRenderVSync(renderer, 1);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    ImGui::StyleColorsDark();

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
        ImGui::Begin("RetroImageConverter");
        if (ImGui::Button("Load PNG 32 bits"))
        {
            filePath = OpenWindowsFileDialog();

            if (!filePath.empty())
            {
                pSurface = IMG_Load(filePath.c_str());
                if (pSurface != nullptr)
                {
                    // For now we only support SDL_PIXELFORMAT_ABGR8888
                    if (pSurface->format == SDL_PIXELFORMAT_ABGR8888)
                    {
                        bValidSurfaceLoaded = true;
                    }
                    else
                    {
                        SDL_DestroySurface(pSurface);
                        pSurface = nullptr;
                        MessageBoxA(NULL, "Only support SDL_PIXELFORMAT_ABGR8888 for now. Save your image as PNG in 32 bits format.", "Fatal error", MB_ICONERROR | MB_OK);
                    }
                }
                else
                {
                    MessageBoxA(NULL, "Failed to load the image with SDL", "Fatal error", MB_ICONERROR | MB_OK);
                }
            }

            // ConvertToSinclairQL8(pSurface, "Bubbles16x16x5", true, true);
        }

        if (bValidSurfaceLoaded)
        {
            ImGui::Text("Image %s loaded.", filePath.c_str());
            int w = pSurface->pitch / 4;
            int h = pSurface->h;
            ImGui::Text("Witdh : %d", w);
            ImGui::Text("Height : %d", h);

            static bool bGenerateMask = true;
			static bool bGenerateShifting = true;
			ImGui::Checkbox("Generate mask", &bGenerateMask);
			ImGui::Checkbox("Generate shifting", &bGenerateShifting);

            if (ImGui::Button("Convert for Sinclair QL - 8 colors mode"))
            {
                std::string filePathDest = SaveWindowsFileDialog();
                if (!filePathDest.empty())
                {
                    int result = ConvertToSinclairQL8(pSurface, filePathDest.c_str(), bGenerateMask, bGenerateShifting);
                    if (result != CONVERT_ERROR_NO_ERROR)
                    {
                        switch (result)
						{
                            case CONVERT_ERROR_WIDTH_NOT_MULTIPLE_OF_4:
                                MessageBoxA(NULL, "The width of the image must be a multiple of 4.", "Fatal error", MB_ICONERROR | MB_OK);
								break;
                            case CONVERT_ERROR_CANNOT_OPEN_OUPUT_FILE:
                                MessageBoxA(NULL, "Cannot open output file.", "Fatal error", MB_ICONERROR | MB_OK);
                                break;
                            default:
                                MessageBoxA(NULL, "Unknown error.", "Fatal error", MB_ICONERROR | MB_OK);
                                break;
                        }
                    }
                    else
                    {
                        MessageBoxA(NULL, "Conversion successful.", "Done", MB_OK);
                    }
                }
            }
		}

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

// Fonction pour ouvrir la boîte de dialogue Windows
// Généré par IA
std::string SaveWindowsFileDialog()
{
    OPENFILENAMEA ofn;
    CHAR szFile[260] = { 0 };

    ZeroMemory(&ofn, sizeof(OPENFILENAME));
    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = NULL; // À remplacer par le HWND de ta fenêtre si disponible
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = sizeof(szFile);
    ofn.lpstrFilter = "Binary files (*.bin)\0*.bin\0All files (*.*)\0*.*\0";
    ofn.nFilterIndex = 1;

    // Ajoute automatiquement cette extension si l'utilisateur n'en tape pas
    ofn.lpstrDefExt = "txt";

    // OFN_OVERWRITEPROMPT est crucial ici : il demande confirmation avant d'écraser un fichier
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT | OFN_NOCHANGEDIR;

    // Appel spécifique pour la sauvegarde
    if (GetSaveFileNameA(&ofn) == TRUE)
    {
        return std::string(ofn.lpstrFile);
    }

    return ""; // Annulation
}
// Fonction pour ouvrir la boîte de dialogue Windows
// Généré par IA
std::string OpenWindowsFileDialog()
{
    OPENFILENAMEA ofn;       // Structure de configuration de la boîte de dialogue
    CHAR szFile[260] = { 0 };  // Buffer pour stocker le nom du fichier

    // Initialisation de la structure avec des zéros
    ZeroMemory(&ofn, sizeof(OPENFILENAME));
    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = NULL; // Idéalement, passer le HWND de ta fenêtre principale ici
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = sizeof(szFile);
    ofn.lpstrFilter = "Image files\0*.png\0All files\0*.*\0"; // Filtres optionnels
    ofn.nFilterIndex = 1;
    ofn.lpstrFileTitle = NULL;
    ofn.nMaxFileTitle = 0;
    ofn.lpstrInitialDir = NULL; // Répertoire par défaut (NULL = répertoire courant)
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_NOCHANGEDIR;

    // Affiche la boîte de dialogue
    if (GetOpenFileNameA(&ofn) == TRUE)
    {
        return std::string(ofn.lpstrFile); // Retourne le chemin complet
    }

    return ""; // Retourne une chaîne vide si l'utilisateur annule
}
