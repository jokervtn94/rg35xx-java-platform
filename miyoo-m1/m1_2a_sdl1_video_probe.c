#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

typedef unsigned char Uint8;
typedef unsigned short Uint16;
typedef unsigned int Uint32;
typedef struct SDL_PixelFormat SDL_PixelFormat;
typedef struct SDL_Rect { short x, y; unsigned short w, h; } SDL_Rect;
typedef struct SDL_Surface {
    Uint32 flags;
    SDL_PixelFormat *format;
    int w, h;
    Uint16 pitch;
    void *pixels;
    int offset;
    void *hwdata;
    SDL_Rect clip_rect;
    Uint32 unused1;
    Uint32 locked;
    void *map;
    unsigned int format_version;
    int refcount;
} SDL_Surface;

typedef int (*PFN_SDL_Init)(Uint32);
typedef void (*PFN_SDL_Quit)(void);
typedef const char *(*PFN_SDL_GetError)(void);
typedef char *(*PFN_SDL_VideoDriverName)(char *, int);
typedef SDL_Surface *(*PFN_SDL_SetVideoMode)(int,int,int,Uint32);
typedef Uint32 (*PFN_SDL_MapRGB)(SDL_PixelFormat *,Uint8,Uint8,Uint8);
typedef int (*PFN_SDL_FillRect)(SDL_Surface *,SDL_Rect *,Uint32);
typedef int (*PFN_SDL_Flip)(SDL_Surface *);
typedef void (*PFN_SDL_Delay)(Uint32);

#define SDL_INIT_VIDEO 0x00000020u
#define SDL_SWSURFACE  0x00000000u
#define SDL_FULLSCREEN 0x80000000u

static void *need(void *h, const char *name) {
    void *p = dlsym(h, name);
    if (!p) {
        fprintf(stderr, "M1.2A FAIL missing_symbol=%s error=%s\n", name, dlerror());
        exit(20);
    }
    return p;
}

int main(void) {
    const char *libs[] = {
        "/usr/lib/libSDL-1.2.so.0",
        "/usr/lib/libSDL-1.2.so.0.11.4",
        "libSDL-1.2.so.0",
        NULL
    };
    void *h = NULL;
    int i;

    printf("RG35XX MIYOO M1.2A SDL1 VIDEO PROBE\n");
    printf("PRIMARY_VARIABLE=SDL1_VIDEO_ONLY\n");

    for (i = 0; libs[i]; ++i) {
        h = dlopen(libs[i], RTLD_NOW | RTLD_LOCAL);
        if (h) {
            printf("SDL1_DLOPEN=PASS path=%s\n", libs[i]);
            break;
        }
        printf("SDL1_DLOPEN_TRY=FAIL path=%s error=%s\n", libs[i], dlerror());
    }
    if (!h) return 10;

    PFN_SDL_Init SDL_Init = (PFN_SDL_Init)need(h, "SDL_Init");
    PFN_SDL_Quit SDL_Quit = (PFN_SDL_Quit)need(h, "SDL_Quit");
    PFN_SDL_GetError SDL_GetError = (PFN_SDL_GetError)need(h, "SDL_GetError");
    PFN_SDL_VideoDriverName SDL_VideoDriverName = (PFN_SDL_VideoDriverName)need(h, "SDL_VideoDriverName");
    PFN_SDL_SetVideoMode SDL_SetVideoMode = (PFN_SDL_SetVideoMode)need(h, "SDL_SetVideoMode");
    PFN_SDL_MapRGB SDL_MapRGB = (PFN_SDL_MapRGB)need(h, "SDL_MapRGB");
    PFN_SDL_FillRect SDL_FillRect = (PFN_SDL_FillRect)need(h, "SDL_FillRect");
    PFN_SDL_Flip SDL_Flip = (PFN_SDL_Flip)need(h, "SDL_Flip");
    PFN_SDL_Delay SDL_Delay = (PFN_SDL_Delay)need(h, "SDL_Delay");

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        printf("SDL1_INIT_VIDEO=FAIL error=%s\n", SDL_GetError());
        dlclose(h);
        return 30;
    }
    printf("SDL1_INIT_VIDEO=PASS\n");

    char driver[64] = {0};
    if (SDL_VideoDriverName(driver, (int)sizeof(driver)))
        printf("SDL1_VIDEO_DRIVER=%s\n", driver);
    else
        printf("SDL1_VIDEO_DRIVER=(unknown)\n");

    SDL_Surface *screen = SDL_SetVideoMode(640, 480, 32, SDL_SWSURFACE | SDL_FULLSCREEN);
    if (!screen) {
        printf("SDL1_SET_VIDEO_MODE=FAIL error=%s\n", SDL_GetError());
        SDL_Quit();
        dlclose(h);
        return 40;
    }
    printf("SDL1_SET_VIDEO_MODE=PASS w=%d h=%d pitch=%u\n", screen->w, screen->h, (unsigned)screen->pitch);

    const Uint8 colors[4][3] = {
        {255,0,0}, {0,255,0}, {0,0,255}, {255,255,255}
    };
    const char *names[4] = {"RED","GREEN","BLUE","WHITE"};

    for (i = 0; i < 4; ++i) {
        Uint32 px = SDL_MapRGB(screen->format, colors[i][0], colors[i][1], colors[i][2]);
        if (SDL_FillRect(screen, NULL, px) != 0) {
            printf("SDL1_FILL_%s=FAIL error=%s\n", names[i], SDL_GetError());
            SDL_Quit();
            dlclose(h);
            return 50 + i;
        }
        if (SDL_Flip(screen) != 0) {
            printf("SDL1_FLIP_%s=FAIL error=%s\n", names[i], SDL_GetError());
            SDL_Quit();
            dlclose(h);
            return 60 + i;
        }
        printf("SDL1_FRAME_%s=PASS\n", names[i]);
        fflush(stdout);
        SDL_Delay(1000);
    }

    SDL_Quit();
    dlclose(h);
    printf("M1_2A_RESULT=PASS\n");
    return 0;
}
