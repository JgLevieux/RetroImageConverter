#include <stdio.h>
#include "SinclairQL.h"

// G0 F0 G1 F1 G2 F2 G3 F3
// R0 B0 R1 B1 R2 B2 R3 B3

Uint16 SinclairQLWord_00[8] =
{
    0b0000000000000000, // Black
    0b0000000001000000, // Blue
    0b0000000010000000, // Red
    0b0000000011000000, // Magenta
    0b1000000000000000, // Green
    0b1000000001000000, // Cyan
    0b1000000010000000, // Yellow
    0b1000000011000000  // White
};
Uint16 SinclairQLWord_01[8] =
{
    0b0000000000000000, // Black
    0b0000000000010000, // Blue
    0b0000000000100000, // Red
    0b0000000000110000, // Magenta
    0b0010000000000000, // Green
    0b0010000000010000, // Cyan
    0b0010000000100000, // Yellow
    0b0010000000110000  // White
};

Uint16 SinclairQLWord_02[8] =
{
    0b0000000000000000, // Black
    0b0000000000000100, // Blue
    0b0000000000001000, // Red
    0b0000000000001100, // Magenta
    0b0000100000000000, // Green
    0b0000100000000100, // Cyan
    0b0000100000001000, // Yellow
    0b0000100000001100  // White
};

Uint16 SinclairQLWord_03[8] =
{
    0b0000000000000000, // Black
    0b0000000000000001, // Blue
    0b0000000000000010, // Red
    0b0000000000000011, // Magenta
    0b0000001000000000, // Green
    0b0000001000000001, // Cyan
    0b0000001000000010, // Yellow
    0b0000001000000011  // White
};

Uint8 SinclairQLPal8[8][3] =
{
    { 0, 0, 0 },       // Black     : 000
    { 0, 0, 255 },     // Blue      : 001
    { 255, 0, 0 },     // Red       : 010
    { 255, 0, 255 },   // Magenta   : 011
    { 0, 255, 0 },     // Green     : 100
    { 0, 255, 255 },   // Cyan      : 101
    { 255, 255, 0 },   // Yellow    : 110
    { 255, 255, 255 }  // White     ; 111
};

int GetSinclairQLColor8Index(Uint8 r, Uint8 g, Uint8 b)
{
	// find the color index in the SinclairQLPal8 array that is closest to the given RGB values
	int index = 0;
	int dist = 255 * 255 * 3;
    for (int i = 0; i < 8; i++)
    {
        int dr = r - SinclairQLPal8[i][0];
        int dg = g - SinclairQLPal8[i][1];
        int db = b - SinclairQLPal8[i][2];
        int d = dr * dr + dg * dg + db * db;
        if (d < dist)
        {
            dist = d;
            index = i;
	    }
    }
    return index;
}

bool ConvertToSinclairQL8(SDL_Surface* pSurface, const char *pName)
{
    Uint32* pPixels = (Uint32*)pSurface->pixels;
    int w = pSurface->pitch / 4;
    int h = pSurface->h;

    // Check if the width is a multiple of 4, since we need to process 4 pixels at a time
    int nNbWord = w / 4;
    if (nNbWord * 4 != w)
    {
        return false;
    }

    // Open file for output.
    FILE* pFile = nullptr;
    fopen_s(&pFile, "X://Sources//test.bin", "wb");
    if (!pFile)
        return false;

	// Create a new pixel array to shift the image
	Uint32* pPixelsForShifting = new Uint32[(w + 8) * h]; // We add 4 pixels on each side
	memset(pPixelsForShifting, 0, (w + 8) * h * sizeof(Uint32)); // Initialize the new pixel array to 0 (transparent)
    for (int i = 0; i < h; i++)
    {
        for (int j = 0; j < w; j++)
        {
			pPixelsForShifting[i * (w + 8) + j + 4] = pPixels[i * w + j];
        }
    }

    // We add one more word for shifting (4 pixels on QL mode 8 colors)
    nNbWord += 1;

    // Allocate memory for the output image
    Uint16* pOutputBitmap = new Uint16[nNbWord * h];
    Uint16* pOutputMask = new Uint16[nNbWord * h];

	for (int k = 4; k > 0 ; k--) // Sprite shifting (4 pixels per word)
    {
		for (int i = 0; i < h; i++) // Each line of the image
        {
			for (int j = 0; j < nNbWord; j++) // Each word of 4 pixels
            {
                Uint16 wQLColor8 = 0;
                Uint16 wQLMask8 = 0;
                Uint8 p0[4], p1[4], p2[4], p3[4];

                int nPixel = pPixelsForShifting[i * (w + 8) + j * 4 + 0 + k];
                SDL_GetRGBA(nPixel, SDL_GetPixelFormatDetails(pSurface->format), NULL, &p0[0], &p0[1], &p0[2], &p0[3]);
                if (p0[3] > 128) // If alpha is less than 128, consider it transparent
                {
                    wQLMask8 |= SinclairQLWord_00[7];
                    wQLColor8 |= SinclairQLWord_00[GetSinclairQLColor8Index(p0[0], p0[1], p0[2])];
                }

                nPixel = pPixelsForShifting[i * (w + 8) + j * 4 + 1 + k];
                SDL_GetRGBA(nPixel, SDL_GetPixelFormatDetails(pSurface->format), NULL, &p1[0], &p1[1], &p1[2], &p1[3]);
                if (p1[3] > 128)
                {
                    wQLMask8 |= SinclairQLWord_01[7];
                    wQLColor8 |= SinclairQLWord_01[GetSinclairQLColor8Index(p1[0], p1[1], p1[2])];
                }

                nPixel = pPixelsForShifting[i * (w + 8) + j * 4 + 2 + k];
                SDL_GetRGBA(nPixel, SDL_GetPixelFormatDetails(pSurface->format), NULL, &p2[0], &p2[1], &p2[2], &p2[3]);
                if (p2[3] > 128)
                {
                    wQLMask8 |= SinclairQLWord_02[7];
                    wQLColor8 |= SinclairQLWord_02[GetSinclairQLColor8Index(p2[0], p2[1], p2[2])];
                }

                nPixel = pPixelsForShifting[i * (w + 8) + j * 4 + 3 + k];
                SDL_GetRGBA(nPixel, SDL_GetPixelFormatDetails(pSurface->format), NULL, &p3[0], &p3[1], &p3[2], &p3[3]);
                if (p3[3] > 128)
                {
                    wQLMask8 |= SinclairQLWord_03[7];
                    wQLColor8 |= SinclairQLWord_03[GetSinclairQLColor8Index(p3[0], p3[1], p3[2])];
                }

                wQLColor8 = (wQLColor8 & 0xFF00) >> 8 | (wQLColor8 & 0x00FF) << 8; // Swap bytes for little-endian
                wQLMask8 = (wQLMask8 & 0xFF00) >> 8 | (wQLMask8 & 0x00FF) << 8; // Swap bytes for little-endian

                pOutputBitmap[i * nNbWord + j] = wQLColor8;
                pOutputMask[i * nNbWord + j] = wQLMask8;
            }
        }
        fwrite(pOutputBitmap, sizeof(Uint16), nNbWord * h, pFile);
        fwrite(pOutputMask, sizeof(Uint16), nNbWord * h, pFile);

        memset(pOutputBitmap, 0, nNbWord*2 * h);
        memset(pOutputMask, 0, nNbWord*2 * h);
    }

    fclose(pFile);

    return true;
}

