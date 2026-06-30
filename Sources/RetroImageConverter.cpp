#include <windows.h>
#include <commdlg.h>
#include <string>
#include <iostream>
#include <SDL3/SDL_main.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL3_image/SDL_image.h>
#include <imgui-master/imgui.h>
#include <imgui-master/backends/imgui_impl_sdl3.h>
#include <imgui-master/backends/imgui_impl_sdlrenderer3.h>

#include "Sources/SinclairQL.h"

std::string OpenWindowsFileDialog();
std::string SaveWindowsFileDialog();

static SDL_Surface* pSurface = nullptr;
static bool bValidSurfaceLoaded = false;
static char filePathLoad[2048] = "";
static char filePathSave[2048] = "";

void SDLCALL MyFileDialogCallback(void* userdata, const char* const* filelist, int filter)
{
    if (filelist == nullptr)
    {
        std::cerr << "SDL dialog error: " << SDL_GetError() << std::endl;
        return;
    }

    if (filelist[0] == nullptr) // closed without selection
    {
        return;
    }

    SDL_strlcpy((char*)userdata, filelist[0], 2048);
}

static const SDL_DialogFileFilter filtersLoad[] =
{
        { "Images", "png" },
        { "Tous les fichiers", "*" }
};
int numFiltersLoad = sizeof(filtersLoad) / sizeof(filtersLoad[0]);

static const SDL_DialogFileFilter filtersSave[] =
{
        { "Binary", "bin" },
        { "Tous les fichiers", "*" }
};
int numFiltersSave = sizeof(filtersSave) / sizeof(filtersSave[0]);

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
            bValidSurfaceLoaded = false;
            filePathLoad[0] = 0;
            SDL_ShowOpenFileDialog(MyFileDialogCallback, filePathLoad, window, filtersLoad, numFiltersLoad, nullptr, false);
        }

        if (!bValidSurfaceLoaded && filePathLoad[0] != 0)
        {
            pSurface = IMG_Load(filePathLoad);
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

        if (bValidSurfaceLoaded)
        {
            ImGui::Text("Image %s loaded.", filePathLoad);
            int w = pSurface->pitch / 4;
            int h = pSurface->h;
            ImGui::Text("Witdh : %d", w);
            ImGui::Text("Height : %d", h);

            static bool bGenerateMask = false;
			static bool bGenerateShifting = false;
			ImGui::Checkbox("Generate mask", &bGenerateMask);
			ImGui::Checkbox("Generate shifting", &bGenerateShifting);

            if (ImGui::Button("Convert for Sinclair QL - 8 colors mode"))
            {
                filePathSave[0] = 0;
                SDL_ShowSaveFileDialog(MyFileDialogCallback, filePathSave, window, filtersSave, numFiltersSave, nullptr);
            }
            
            if (filePathSave[0] != 0)
            {
                int result = ConvertToSinclairQL8(pSurface, filePathSave, bGenerateMask, bGenerateShifting);
                if (result != CONVERT_ERROR_NO_ERROR)
                {
                    switch (result)
                    {
                    case CONVERT_ERROR_WIDTH_NOT_MULTIPLE_OF_4:
                        SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Fatal error", "The width of the image must be a multiple of 4.", window);
                        break;
                    case CONVERT_ERROR_CANNOT_OPEN_OUPUT_FILE:
                        SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Fatal error", "Cannot open output file.", window);
                        break;
                    default:
                        SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Fatal error", "Unknown error.", window);
                        break;
                    }
                }
                else
                {
                    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, "Done", "Conversion successful.", window);
                }
            }
            filePathSave[0] = 0;
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
