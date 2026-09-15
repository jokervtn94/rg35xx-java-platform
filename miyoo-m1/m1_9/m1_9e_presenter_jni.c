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

static int load_sdl(void) {
    const char *libs[] = {"/usr/lib/libSDL-1.2.so.0", "/usr/lib/libSDL-1.2.so.0.11.4", 0};
    int i;
    for (i=0; libs[i] && !sdl; ++i) sdl = dlopen(libs[i], RTLD_NOW | RTLD_LOCAL);
    if (!sdl) return 1;
#define LOADSYM(x) do { x##_p=(p##x)dlsym(sdl,#x); if(!x##_p) return 2; } while(0)
    LOADSYM(SDL_Init); LOADSYM(SDL_Quit); LOADSYM(SDL_SetVideoMode); LOADSYM(SDL_Flip);
    LOADSYM(SDL_MapRGB); LOADSYM(SDL_VideoDriverName);
#undef LOADSYM
    return 0;
}

JNIEXPORT jint JNICALL Java_org_recompile_mobile_M19SdlPresenter_initDisplay(JNIEnv *env, jclass cls) {
    char driver[32]; int rc; (void)env; (void)cls;
    setenv("SDL_VIDEODRIVER", "fbcon", 1);
    rc=load_sdl(); if(rc) return 100+rc;
    if(SDL_Init_p(SDL_INIT_VIDEO)!=0) return 110;
    driver[0]=0; SDL_VideoDriverName_p(driver,sizeof(driver));
    printf("M1_9E_SDL_DRIVER=%s\n",driver); fflush(stdout);
    screen=SDL_SetVideoMode_p(640,480,32,SDL_SWSURFACE);
    if(!screen) return 120;
    printf("M1_9E_SURFACE=%dx%d PITCH=%u\n",screen->w,screen->h,(unsigned)screen->pitch); fflush(stdout);
    return 0;
}

JNIEXPORT jint JNICALL Java_org_recompile_mobile_M19SdlPresenter_presentARGB(JNIEnv *env, jclass cls, jintArray pixels, jint width, jint height) {
    jint *src; int x,y; (void)cls;
    if(!screen || !screen->pixels || !pixels) return 1;
    if(width != 640 || height != 480 || screen->w != width || screen->h != height) return 2;
    if((*env)->GetArrayLength(env,pixels) < width*height) return 3;
    src=(*env)->GetIntArrayElements(env,pixels,0); if(!src) return 4;
    for(y=0;y<height;y++) {
        uint32_t *dst=(uint32_t *)((uint8_t *)screen->pixels + y*screen->pitch);
        for(x=0;x<width;x++) {
            uint32_t argb=(uint32_t)src[y*width+x];
            dst[x]=SDL_MapRGB_p(screen->format,(uint8_t)(argb>>16),(uint8_t)(argb>>8),(uint8_t)argb);
        }
    }
    (*env)->ReleaseIntArrayElements(env,pixels,src,JNI_ABORT);
    if(SDL_Flip_p(screen)!=0) return 5;
    return 0;
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_M19SdlPresenter_shutdownDisplay(JNIEnv *env, jclass cls) {
    (void)env; (void)cls;
    if(SDL_Quit_p) SDL_Quit_p(); screen=0;
    if(sdl) dlclose(sdl); sdl=0;
}
