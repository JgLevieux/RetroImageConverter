#pragma once
#include <SDL3/SDL.h>
#include <SDL3/SDL3_image/SDL_image.h>

#define CONVERT_ERROR_NO_ERROR 0
#define CONVERT_ERROR_WIDTH_NOT_MULTIPLE_OF_4 -1
#define CONVERT_ERROR_CANNOT_OPEN_OUPUT_FILE -2

int ConvertToSinclairQL8(SDL_Surface* pSurface, const char* pName, bool bGenerateMask, bool bGenerateShifting);

