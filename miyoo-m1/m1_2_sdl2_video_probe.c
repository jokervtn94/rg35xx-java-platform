#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

typedef unsigned int Uint32;
typedef void SDL_Window;
typedef void SDL_Renderer;

typedef int (*PFN_SDL_Init)(Uint32 flags);
typedef void (*PFN_SDL_Quit)(void);
typedef const char *(*PFN_SDL_GetError)(void);
typedef const char *(*PFN_SDL_GetCurrentVideoDriver)(void);
typedef SDL_Window *(*PFN_SDL_CreateWindow)(const char *, int, int, int, int, Uint32);
typedef void (*PFN_SDL_DestroyWindow)(SDL_Window *);
typedef SDL_Renderer *(*PFN_SDL_CreateRenderer)(SDL_Window *, int, Uint32);
typedef void (*PFN_SDL_DestroyRenderer)(SDL_Renderer *);
typedef int (*PFN_SDL_SetRenderDrawColor)(SDL_Renderer *, unsigned char, unsigned char, unsigned char, unsigned char);
typedef int (*PFN_SDL_RenderClear)(SDL_Renderer *);
typedef void (*PFN_SDL_RenderPresent)(SDL_Renderer *);
typedef void (*PFN_SDL_Delay)(Uint32 ms);

#define SDL_INIT_VIDEO 0x00000020u
#define SDL_WINDOW_SHOWN 0x00000004u
#define SDL_RENDERER_SOFTWARE 0x00000001u
#define SDL_WINDOWPOS_UNDEFINED_MASK 0x1FFF0000u
#define SDL_WINDOWPOS_UNDEFINED ((int)SDL_WINDOWPOS_UNDEFINED_MASK)

static void *req(void *h, const char *name) {
    void *p = dlsym(h, name);
    if (!p) {
        fprintf(stderr, "M1.2 FAIL missing_symbol=%s dlerror=%s\n", name, dlerror());
        exit(20);
    }
    return p;
}

int main(void) {
    void *h = dlopen("/usr/lib/libSDL2-2.0.so.0", RTLD_NOW | RTLD_LOCAL);
    if (!h) {
        fprintf(stderr, "SDL2_DLOPEN=FAIL error=%s\n", dlerror());
        return 10;
    }

    PFN_SDL_Init SDL_Init = (PFN_SDL_Init)req(h, "SDL_Init");
    PFN_SDL_Quit SDL_Quit = (PFN_SDL_Quit)req(h, "SDL_Quit");
    PFN_SDL_GetError SDL_GetError = (PFN_SDL_GetError)req(h, "SDL_GetError");
    PFN_SDL_GetCurrentVideoDriver SDL_GetCurrentVideoDriver = (PFN_SDL_GetCurrentVideoDriver)req(h, "SDL_GetCurrentVideoDriver");
    PFN_SDL_CreateWindow SDL_CreateWindow = (PFN_SDL_CreateWindow)req(h, "SDL_CreateWindow");
    PFN_SDL_DestroyWindow SDL_DestroyWindow = (PFN_SDL_DestroyWindow)req(h, "SDL_DestroyWindow");
    PFN_SDL_CreateRenderer SDL_CreateRenderer = (PFN_SDL_CreateRenderer)req(h, "SDL_CreateRenderer");
    PFN_SDL_DestroyRenderer SDL_DestroyRenderer = (PFN_SDL_DestroyRenderer)req(h, "SDL_DestroyRenderer");
    PFN_SDL_SetRenderDrawColor SDL_SetRenderDrawColor = (PFN_SDL_SetRenderDrawColor)req(h, "SDL_SetRenderDrawColor");
    PFN_SDL_RenderClear SDL_RenderClear = (PFN_SDL_RenderClear)req(h, "SDL_RenderClear");
    PFN_SDL_RenderPresent SDL_RenderPresent = (PFN_SDL_RenderPresent)req(h, "SDL_RenderPresent");
    PFN_SDL_Delay SDL_Delay = (PFN_SDL_Delay)req(h, "SDL_Delay");

    printf("RG35XX MIYOO M1.2 SDL2 VIDEO PROBE\n");
    printf("PRIMARY_VARIABLE=SDL2_VIDEO_ONLY\n");

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        printf("SDL_INIT_VIDEO=FAIL error=%s\n", SDL_GetError());
        dlclose(h);
        return 30;
    }
    printf("SDL_INIT_VIDEO=PASS\n");

    const char *driver = SDL_GetCurrentVideoDriver();
    printf("CURRENT_VIDEO_DRIVER=%s\n", driver ? driver : "(none)");
    if (!driver) {
        SDL_Quit();
        dlclose(h);
        return 31;
    }
    if (driver[0]=='d' && driver[1]=='u' && driver[2]=='m' && driver[3]=='m' && driver[4]=='y' && driver[5]=='\0') {
        printf("REAL_DISPLAY_GATE=FAIL_DUMMY_DRIVER\n");
        SDL_Quit();
        dlclose(h);
        return 32;
    }

    SDL_Window *win = SDL_CreateWindow("RG35XX Miyoo M1.2", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_SHOWN);
    if (!win) {
        printf("SDL_CREATE_WINDOW=FAIL error=%s\n", SDL_GetError());
        SDL_Quit();
        dlclose(h);
        return 40;
    }
    printf("SDL_CREATE_WINDOW=PASS size=640x480\n");

    SDL_Renderer *ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
    if (!ren) {
        printf("SDL_CREATE_RENDERER=FAIL error=%s\n", SDL_GetError());
        SDL_DestroyWindow(win);
        SDL_Quit();
        dlclose(h);
        return 50;
    }
    printf("SDL_CREATE_RENDERER=PASS mode=software\n");

    const unsigned char stages[4][3] = {
        {255, 0, 0},
        {0, 255, 0},
        {0, 0, 255},
        {255, 255, 255}
    };
    const char *names[4] = {"RED", "GREEN", "BLUE", "WHITE"};
    int i;
    for (i = 0; i < 4; ++i) {
        if (SDL_SetRenderDrawColor(ren, stages[i][0], stages[i][1], stages[i][2], 255) != 0) {
            printf("RENDER_STAGE_%d=FAIL_SET_COLOR error=%s\n", i + 1, SDL_GetError());
            SDL_DestroyRenderer(ren);
            SDL_DestroyWindow(win);
            SDL_Quit();
            dlclose(h);
            return 60 + i;
        }
        if (SDL_RenderClear(ren) != 0) {
            printf("RENDER_STAGE_%d=FAIL_CLEAR error=%s\n", i + 1, SDL_GetError());
            SDL_DestroyRenderer(ren);
            SDL_DestroyWindow(win);
            SDL_Quit();
            dlclose(h);
            return 70 + i;
        }
        SDL_RenderPresent(ren);
        printf("RENDER_STAGE_%d=PASS color=%s\n", i + 1, names[i]);
        fflush(stdout);
        SDL_Delay(1000);
    }

    printf("VISIBLE_PATTERN_EXPECTED=RED_GREEN_BLUE_WHITE_1S_EACH\n");
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    dlclose(h);
    printf("CLEAN_SHUTDOWN=PASS\n");
    printf("M1_2_RESULT=PASS\n");
    return 0;
}
