#include <jni.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct SDL_Surface {
    uint32_t flags;
    void *format;
    int w, h;
    uint16_t pitch;
    void *pixels;
} SDL_Surface;

typedef int (*pSDL_Init)(uint32_t);
typedef void (*pSDL_Quit)(void);
typedef SDL_Surface *(*pSDL_SetVideoMode)(int,int,int,uint32_t);
typedef int (*pSDL_Flip)(SDL_Surface *);
typedef uint32_t (*pSDL_MapRGB)(void *, uint8_t,uint8_t,uint8_t);
typedef char *(*pSDL_VideoDriverName)(char *, int);

static void *sdl;
static SDL_Surface *screen;
static pSDL_Init SDL_Init_p;
static pSDL_Quit SDL_Quit_p;
static pSDL_SetVideoMode SDL_SetVideoMode_p;
static pSDL_Flip SDL_Flip_p;
static pSDL_MapRGB SDL_MapRGB_p;
static pSDL_VideoDriverName SDL_VideoDriverName_p;

#define SDL_INIT_VIDEO 0x00000020u
#define SDL_SWSURFACE 0x00000000u
#define RG35XX_LCD_W 640
#define RG35XX_LCD_H 480

static int load_sdl(void) {
    const char *libs[] = {"/usr/lib/libSDL-1.2.so.0", "/usr/lib/libSDL-1.2.so.0.11.4", 0};
    int i;
    for (i = 0; libs[i] && !sdl; ++i) sdl = dlopen(libs[i], RTLD_NOW | RTLD_LOCAL);
    if (!sdl) return 1;
#define LOADSYM(x) do { x##_p=(p##x)dlsym(sdl,#x); if(!x##_p) return 2; } while(0)
    LOADSYM(SDL_Init);
    LOADSYM(SDL_Quit);
    LOADSYM(SDL_SetVideoMode);
    LOADSYM(SDL_Flip);
    LOADSYM(SDL_MapRGB);
    LOADSYM(SDL_VideoDriverName);
#undef LOADSYM
    return 0;
}

/* Device-proven nearest-neighbor aspect fit, moved to the RG35XX adapter. */
static void fit_geometry(int sw, int sh, int *dw, int *dh, int *ox, int *oy) {
    int fw, fh;
    if (sw <= 0 || sh <= 0) {
        *dw = *dh = *ox = *oy = 0;
        return;
    }
    fw = RG35XX_LCD_W;
    fh = (int)(((long long)sh * RG35XX_LCD_W) / sw);
    if (fh > RG35XX_LCD_H) {
        fh = RG35XX_LCD_H;
        fw = (int)(((long long)sw * RG35XX_LCD_H) / sh);
    }
    if (fw < 1) fw = 1;
    if (fh < 1) fh = 1;
    *dw = fw;
    *dh = fh;
    *ox = (RG35XX_LCD_W - fw) / 2;
    *oy = (RG35XX_LCD_H - fh) / 2;
}

JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_initDisplay(JNIEnv *env, jclass cls) {
    char driver[32];
    int rc;
    (void)env;
    (void)cls;

    setenv("SDL_VIDEODRIVER", "fbcon", 1);
    rc = load_sdl();
    if (rc) return 100 + rc;
    if (SDL_Init_p(SDL_INIT_VIDEO) != 0) return 110;

    driver[0] = 0;
    SDL_VideoDriverName_p(driver, sizeof(driver));
    printf("RG35XX_A3_SDL_DRIVER=%s\n", driver);
    fflush(stdout);

    screen = SDL_SetVideoMode_p(RG35XX_LCD_W, RG35XX_LCD_H, 32, SDL_SWSURFACE);
    if (!screen) return 120;
    printf("RG35XX_A3_SURFACE=%dx%d PITCH=%u\n", screen->w, screen->h, (unsigned)screen->pitch);
    fflush(stdout);
    if (screen->w != RG35XX_LCD_W || screen->h != RG35XX_LCD_H) return 121;
    return 0;
}

JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXVideo_presentARGB(JNIEnv *env, jclass cls, jintArray pixels, jint width, jint height) {
    jint *src;
    jsize length;
    int dw, dh, ox, oy;
    int x, y;
    uint32_t black;
    (void)cls;

    if (!screen || !screen->pixels || !pixels) return 1;
    if (width <= 0 || height <= 0) return 2;
    length = (*env)->GetArrayLength(env, pixels);
    if ((long long)length < (long long)width * (long long)height) return 3;

    fit_geometry(width, height, &dw, &dh, &ox, &oy);
    if (dw <= 0 || dh <= 0) return 4;

    src = (*env)->GetIntArrayElements(env, pixels, 0);
    if (!src) return 5;

    black = SDL_MapRGB_p(screen->format, 0, 0, 0);
    for (y = 0; y < RG35XX_LCD_H; ++y) {
        uint32_t *row = (uint32_t *)((uint8_t *)screen->pixels + y * screen->pitch);
        for (x = 0; x < RG35XX_LCD_W; ++x) row[x] = black;
    }

    for (y = 0; y < dh; ++y) {
        int sy = (int)(((long long)y * height) / dh);
        uint32_t *dst = (uint32_t *)((uint8_t *)screen->pixels + (oy + y) * screen->pitch) + ox;
        for (x = 0; x < dw; ++x) {
            int sx = (int)(((long long)x * width) / dw);
            uint32_t argb = (uint32_t)src[sy * width + sx];
            dst[x] = SDL_MapRGB_p(screen->format,
                                  (uint8_t)(argb >> 16),
                                  (uint8_t)(argb >> 8),
                                  (uint8_t)argb);
        }
    }

    (*env)->ReleaseIntArrayElements(env, pixels, src, JNI_ABORT);
    if (SDL_Flip_p(screen) != 0) return 6;
    return 0;
}

JNIEXPORT void JNICALL Java_org_recompile_rg35xx_RG35XXVideo_shutdownDisplay(JNIEnv *env, jclass cls) {
    (void)env;
    (void)cls;
    if (SDL_Quit_p) SDL_Quit_p();
    screen = 0;
    if (sdl) dlclose(sdl);
    sdl = 0;
    SDL_Init_p = 0;
    SDL_Quit_p = 0;
    SDL_SetVideoMode_p = 0;
    SDL_Flip_p = 0;
    SDL_MapRGB_p = 0;
    SDL_VideoDriverName_p = 0;
}
