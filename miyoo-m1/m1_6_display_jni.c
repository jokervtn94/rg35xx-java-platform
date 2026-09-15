#include <jni.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

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
typedef int (*pSDL_FillRect)(SDL_Surface *, void *, uint32_t);
typedef char *(*pSDL_VideoDriverName)(char *, int);

static void *sdl;
static SDL_Surface *screen;
static pSDL_Init SDL_Init_p;
static pSDL_Quit SDL_Quit_p;
static pSDL_SetVideoMode SDL_SetVideoMode_p;
static pSDL_Flip SDL_Flip_p;
static pSDL_MapRGB SDL_MapRGB_p;
static pSDL_FillRect SDL_FillRect_p;
static pSDL_VideoDriverName SDL_VideoDriverName_p;

#define SDL_INIT_VIDEO 0x00000020u
#define SDL_SWSURFACE 0x00000000u

static int load_sdl(void) {
    const char *libs[] = {"/usr/lib/libSDL-1.2.so.0", "/usr/lib/libSDL-1.2.so.0.11.4", 0};
    int i;
    for (i=0; libs[i] && !sdl; ++i) sdl = dlopen(libs[i], RTLD_NOW | RTLD_LOCAL);
    if (!sdl) return 1;
#define LOADSYM(x) do { x##_p=(p##x)dlsym(sdl,#x); if(!x##_p) return 2; } while(0)
    LOADSYM(SDL_Init); LOADSYM(SDL_Quit); LOADSYM(SDL_SetVideoMode); LOADSYM(SDL_Flip);
    LOADSYM(SDL_MapRGB); LOADSYM(SDL_FillRect); LOADSYM(SDL_VideoDriverName);
#undef LOADSYM
    return 0;
}

JNIEXPORT jint JNICALL Java_M16DisplayProbe_initDisplay(JNIEnv *env, jclass cls) {
    char driver[32]; int rc; (void)env; (void)cls;
    setenv("SDL_VIDEODRIVER", "fbcon", 1);
    rc=load_sdl(); if(rc) return 100+rc;
    if(SDL_Init_p(SDL_INIT_VIDEO)!=0) return 110;
    driver[0]=0; SDL_VideoDriverName_p(driver,sizeof(driver));
    printf("M1_6_SDL_DRIVER=%s\n",driver); fflush(stdout);
    screen=SDL_SetVideoMode_p(640,480,32,SDL_SWSURFACE);
    if(!screen) return 120;
    printf("M1_6_SURFACE=%dx%d PITCH=%u\n",screen->w,screen->h,(unsigned)screen->pitch); fflush(stdout);
    return 0;
}

JNIEXPORT jint JNICALL Java_M16DisplayProbe_showColor(JNIEnv *env, jclass cls, jint rgb, jint ms) {
    uint8_t r,g,b; uint32_t px; (void)env; (void)cls;
    if(!screen) return 1;
    r=(uint8_t)((rgb>>16)&255); g=(uint8_t)((rgb>>8)&255); b=(uint8_t)(rgb&255);
    px=SDL_MapRGB_p(screen->format,r,g,b);
    if(SDL_FillRect_p(screen,0,px)!=0) return 2;
    if(SDL_Flip_p(screen)!=0) return 3;
    usleep((useconds_t)ms*1000u);
    return 0;
}

JNIEXPORT void JNICALL Java_M16DisplayProbe_shutdownDisplay(JNIEnv *env, jclass cls) {
    (void)env; (void)cls;
    if(SDL_Quit_p) SDL_Quit_p(); screen=0;
    if(sdl) dlclose(sdl); sdl=0;
}
