#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

typedef unsigned char Uint8;
typedef unsigned int Uint32;
typedef struct SDL_version { Uint8 major, minor, patch; } SDL_version;

typedef void (*PFN_SDL_GetVersion)(SDL_version *ver);
typedef const char *(*PFN_SDL_GetCurrentVideoDriver)(void);
typedef int (*PFN_SDL_GetNumVideoDrivers)(void);
typedef const char *(*PFN_SDL_GetVideoDriver)(int index);
typedef const char *(*PFN_SDL_GetCurrentAudioDriver)(void);
typedef int (*PFN_SDL_GetNumAudioDrivers)(void);
typedef const char *(*PFN_SDL_GetAudioDriver)(int index);
typedef int (*PFN_SDL_Init)(Uint32 flags);
typedef void (*PFN_SDL_Quit)(void);
typedef const char *(*PFN_SDL_GetError)(void);

static void *req(void *h, const char *name) {
    void *p = dlsym(h, name);
    if (!p) {
        fprintf(stderr, "M1.1 FAIL missing_symbol=%s dlerror=%s\n", name, dlerror());
        exit(20);
    }
    return p;
}

int main(void) {
    const char *candidates[] = {
        "/usr/lib/libSDL2-2.0.so.0",
        "/usr/lib/libSDL2-2.0.so.0.8.0",
        "libSDL2-2.0.so.0",
        NULL
    };
    void *h = NULL;
    int i;

    printf("RG35XX MIYOO M1.1 SDL2 ABI PROBE\n");
    printf("READ_ONLY=YES\n");

    for (i = 0; candidates[i]; ++i) {
        h = dlopen(candidates[i], RTLD_NOW | RTLD_LOCAL);
        if (h) {
            printf("SDL2_DLOPEN=PASS path=%s\n", candidates[i]);
            break;
        }
        printf("SDL2_DLOPEN_TRY=FAIL path=%s error=%s\n", candidates[i], dlerror());
    }
    if (!h) {
        printf("SDL2_DLOPEN=FAIL\n");
        return 10;
    }

    PFN_SDL_GetVersion SDL_GetVersion = (PFN_SDL_GetVersion)req(h, "SDL_GetVersion");
    PFN_SDL_GetNumVideoDrivers SDL_GetNumVideoDrivers = (PFN_SDL_GetNumVideoDrivers)req(h, "SDL_GetNumVideoDrivers");
    PFN_SDL_GetVideoDriver SDL_GetVideoDriver = (PFN_SDL_GetVideoDriver)req(h, "SDL_GetVideoDriver");
    PFN_SDL_GetNumAudioDrivers SDL_GetNumAudioDrivers = (PFN_SDL_GetNumAudioDrivers)req(h, "SDL_GetNumAudioDrivers");
    PFN_SDL_GetAudioDriver SDL_GetAudioDriver = (PFN_SDL_GetAudioDriver)req(h, "SDL_GetAudioDriver");
    PFN_SDL_Init SDL_Init = (PFN_SDL_Init)req(h, "SDL_Init");
    PFN_SDL_Quit SDL_Quit = (PFN_SDL_Quit)req(h, "SDL_Quit");
    PFN_SDL_GetError SDL_GetError = (PFN_SDL_GetError)req(h, "SDL_GetError");
    PFN_SDL_GetCurrentVideoDriver SDL_GetCurrentVideoDriver = (PFN_SDL_GetCurrentVideoDriver)dlsym(h, "SDL_GetCurrentVideoDriver");
    PFN_SDL_GetCurrentAudioDriver SDL_GetCurrentAudioDriver = (PFN_SDL_GetCurrentAudioDriver)dlsym(h, "SDL_GetCurrentAudioDriver");

    SDL_version v = {0,0,0};
    SDL_GetVersion(&v);
    printf("SDL_VERSION=%u.%u.%u\n", (unsigned)v.major, (unsigned)v.minor, (unsigned)v.patch);

    int nv = SDL_GetNumVideoDrivers();
    printf("VIDEO_DRIVER_COUNT=%d\n", nv);
    for (i = 0; i < nv; ++i) {
        const char *s = SDL_GetVideoDriver(i);
        printf("VIDEO_DRIVER_%d=%s\n", i, s ? s : "(null)");
    }

    int na = SDL_GetNumAudioDrivers();
    printf("AUDIO_DRIVER_COUNT=%d\n", na);
    for (i = 0; i < na; ++i) {
        const char *s = SDL_GetAudioDriver(i);
        printf("AUDIO_DRIVER_%d=%s\n", i, s ? s : "(null)");
    }

    if (SDL_Init(0) != 0) {
        printf("SDL_INIT_0=FAIL error=%s\n", SDL_GetError());
        dlclose(h);
        return 30;
    }
    printf("SDL_INIT_0=PASS\n");
    if (SDL_GetCurrentVideoDriver) {
        const char *s = SDL_GetCurrentVideoDriver();
        printf("CURRENT_VIDEO_DRIVER=%s\n", s ? s : "(none)");
    }
    if (SDL_GetCurrentAudioDriver) {
        const char *s = SDL_GetCurrentAudioDriver();
        printf("CURRENT_AUDIO_DRIVER=%s\n", s ? s : "(none)");
    }

    SDL_Quit();
    dlclose(h);
    printf("M1_1_RESULT=PASS\n");
    return 0;
}
