#define _GNU_SOURCE

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

typedef void *EGLDisplay;
typedef void *EGLConfig;
typedef void *EGLContext;
typedef void *EGLSurface;

typedef EGLDisplay (*PFN_eglGetDisplay)(void *native_display);
typedef int (*PFN_eglInitialize)(EGLDisplay display, int *major, int *minor);
typedef const char *(*PFN_eglQueryString)(EGLDisplay display, int name);
typedef int (*PFN_eglBindAPI)(int api);
typedef int (*PFN_eglChooseConfig)(EGLDisplay display, const int *attribs,
                                   EGLConfig *configs, int config_size,
                                   int *num_config);
typedef EGLSurface (*PFN_eglCreatePbufferSurface)(EGLDisplay display,
                                                   EGLConfig config,
                                                   const int *attribs);
typedef EGLContext (*PFN_eglCreateContext)(EGLDisplay display, EGLConfig config,
                                            EGLContext share_context,
                                            const int *attribs);
typedef int (*PFN_eglMakeCurrent)(EGLDisplay display, EGLSurface draw,
                                  EGLSurface read, EGLContext context);
typedef int (*PFN_eglDestroyContext)(EGLDisplay display, EGLContext context);
typedef int (*PFN_eglDestroySurface)(EGLDisplay display, EGLSurface surface);
typedef int (*PFN_eglTerminate)(EGLDisplay display);
typedef int (*PFN_eglGetError)(void);
typedef const unsigned char *(*PFN_glGetString)(unsigned int name);

#define EGL_DEFAULT_DISPLAY ((void *)0)
#define EGL_OPENGL_ES_API 0x30A0
#define EGL_RENDERABLE_TYPE 0x3040
#define EGL_OPENGL_ES2_BIT 0x0004
#define EGL_SURFACE_TYPE 0x3033
#define EGL_PBUFFER_BIT 0x0001
#define EGL_WIDTH 0x3057
#define EGL_HEIGHT 0x3056
#define EGL_CONTEXT_CLIENT_VERSION 0x3098
#define EGL_NONE 0x3038
#define EGL_VENDOR 0x3053
#define EGL_VERSION 0x3054
#define EGL_EXTENSIONS 0x3055
#define GL_VENDOR 0x1F00
#define GL_RENDERER 0x1F01
#define GL_VERSION 0x1F02
#define GL_EXTENSIONS 0x1F03

static void *load_symbol(void *handle, const char *name) {
    void *symbol = dlsym(handle, name);
    if (!symbol) {
        fprintf(stderr, "P4_CONTEXT_MISSING_SYMBOL=%s\n", name);
    }
    return symbol;
}

static void *open_library(const char *const *names) {
    int i;
    for (i = 0; names[i] != NULL; ++i) {
        void *handle = dlopen(names[i], RTLD_NOW | RTLD_LOCAL);
        if (handle) {
            printf("P4_CONTEXT_LIBRARY=%s\n", names[i]);
            return handle;
        }
    }
    fprintf(stderr, "P4_CONTEXT_DLOPEN_FAIL=%s\n", dlerror());
    return NULL;
}

int main(void) {
    static const char *const egl_names[] = {
        "/usr/lib/libEGL.so.1.0.0", "/usr/lib/libEGL.so.1", "libEGL.so.1",
        "libEGL.so", NULL};
    static const char *const gles_names[] = {
        "/usr/lib/libGLESv2.so.2.0.0", "/usr/lib/libGLESv2.so.2",
        "libGLESv2.so.2", "libGLESv2.so", NULL};
    void *egl = NULL;
    void *gles = NULL;
    EGLDisplay display = NULL;
    EGLConfig config = NULL;
    EGLSurface surface = NULL;
    EGLContext context = NULL;
    int major = 0;
    int minor = 0;
    int config_count = 0;
    int result = 1;
    int attribs[] = {
        EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_NONE};
    int pbuffer_attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
    int context_attribs[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};

    PFN_eglGetDisplay eglGetDisplay;
    PFN_eglInitialize eglInitialize;
    PFN_eglQueryString eglQueryString;
    PFN_eglBindAPI eglBindAPI;
    PFN_eglChooseConfig eglChooseConfig;
    PFN_eglCreatePbufferSurface eglCreatePbufferSurface;
    PFN_eglCreateContext eglCreateContext;
    PFN_eglMakeCurrent eglMakeCurrent;
    PFN_eglDestroyContext eglDestroyContext;
    PFN_eglDestroySurface eglDestroySurface;
    PFN_eglTerminate eglTerminate;
    PFN_eglGetError eglGetError;
    PFN_glGetString glGetString;

    printf("P4_CONTEXT_PROBE=BEGIN\n");
    egl = open_library(egl_names);
    gles = open_library(gles_names);
    if (!egl || !gles) goto cleanup;

    eglGetDisplay = (PFN_eglGetDisplay)load_symbol(egl, "eglGetDisplay");
    eglInitialize = (PFN_eglInitialize)load_symbol(egl, "eglInitialize");
    eglQueryString = (PFN_eglQueryString)load_symbol(egl, "eglQueryString");
    eglBindAPI = (PFN_eglBindAPI)load_symbol(egl, "eglBindAPI");
    eglChooseConfig = (PFN_eglChooseConfig)load_symbol(egl, "eglChooseConfig");
    eglCreatePbufferSurface = (PFN_eglCreatePbufferSurface)load_symbol(egl, "eglCreatePbufferSurface");
    eglCreateContext = (PFN_eglCreateContext)load_symbol(egl, "eglCreateContext");
    eglMakeCurrent = (PFN_eglMakeCurrent)load_symbol(egl, "eglMakeCurrent");
    eglDestroyContext = (PFN_eglDestroyContext)load_symbol(egl, "eglDestroyContext");
    eglDestroySurface = (PFN_eglDestroySurface)load_symbol(egl, "eglDestroySurface");
    eglTerminate = (PFN_eglTerminate)load_symbol(egl, "eglTerminate");
    eglGetError = (PFN_eglGetError)load_symbol(egl, "eglGetError");
    glGetString = (PFN_glGetString)load_symbol(gles, "glGetString");
    if (!eglGetDisplay || !eglInitialize || !eglQueryString || !eglBindAPI ||
        !eglChooseConfig || !eglCreatePbufferSurface || !eglCreateContext ||
        !eglMakeCurrent || !eglDestroyContext || !eglDestroySurface ||
        !eglTerminate || !eglGetError || !glGetString) goto cleanup;

    display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    printf("P4_CONTEXT_EGL_DISPLAY=%s ERROR=0x%04x\n",
           display ? "NON_NULL" : "NULL", eglGetError());
    if (!display) goto cleanup;
    if (!eglInitialize(display, &major, &minor)) {
        printf("P4_CONTEXT_EGL_INITIALIZE=FAIL ERROR=0x%04x\n", eglGetError());
        goto cleanup;
    }
    printf("P4_CONTEXT_EGL_INITIALIZE=PASS VERSION=%d.%d\n", major, minor);
    printf("P4_CONTEXT_EGL_VENDOR=%s\n", eglQueryString(display, EGL_VENDOR));
    printf("P4_CONTEXT_EGL_VERSION=%s\n", eglQueryString(display, EGL_VERSION));
    printf("P4_CONTEXT_EGL_EXTENSIONS=%s\n", eglQueryString(display, EGL_EXTENSIONS));
    if (!eglBindAPI(EGL_OPENGL_ES_API)) {
        printf("P4_CONTEXT_EGL_BIND_ES=FAIL ERROR=0x%04x\n", eglGetError());
        goto cleanup;
    }
    printf("P4_CONTEXT_EGL_BIND_ES=PASS\n");
    if (!eglChooseConfig(display, attribs, &config, 1, &config_count) || config_count < 1) {
        printf("P4_CONTEXT_EGL_CHOOSE_CONFIG=FAIL ERROR=0x%04x COUNT=%d\n",
               eglGetError(), config_count);
        goto cleanup;
    }
    printf("P4_CONTEXT_EGL_CHOOSE_CONFIG=PASS COUNT=%d\n", config_count);
    surface = eglCreatePbufferSurface(display, config, pbuffer_attribs);
    printf("P4_CONTEXT_EGL_PBUFFER=%s ERROR=0x%04x\n",
           surface ? "PASS" : "FAIL", eglGetError());
    if (!surface) goto cleanup;
    context = eglCreateContext(display, config, NULL, context_attribs);
    printf("P4_CONTEXT_EGL_CONTEXT=%s ERROR=0x%04x\n",
           context ? "PASS" : "FAIL", eglGetError());
    if (!context) goto cleanup;
    if (!eglMakeCurrent(display, surface, surface, context)) {
        printf("P4_CONTEXT_EGL_MAKE_CURRENT=FAIL ERROR=0x%04x\n", eglGetError());
        goto cleanup;
    }
    printf("P4_CONTEXT_EGL_MAKE_CURRENT=PASS\n");
    printf("P4_CONTEXT_GL_VENDOR=%s\n", glGetString(GL_VENDOR));
    printf("P4_CONTEXT_GL_RENDERER=%s\n", glGetString(GL_RENDERER));
    printf("P4_CONTEXT_GL_VERSION=%s\n", glGetString(GL_VERSION));
    printf("P4_CONTEXT_GL_EXTENSIONS=%s\n", glGetString(GL_EXTENSIONS));
    printf("P4_CONTEXT_RESULT=PASS\n");
    result = 0;

cleanup:
    if (display && context) eglDestroyContext(display, context);
    if (display && surface) eglDestroySurface(display, surface);
    if (display) eglTerminate(display);
    if (gles) dlclose(gles);
    if (egl) dlclose(egl);
    if (result != 0) printf("P4_CONTEXT_RESULT=FAIL\n");
    return result;
}
