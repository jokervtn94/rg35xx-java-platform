#define _GNU_SOURCE

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef void *EGLDisplay;
typedef void *EGLDeviceEXT;
typedef void *EGLNativeDisplayType;
typedef unsigned int EGLenum;
typedef int EGLint;
typedef int EGLBoolean;

typedef EGLDisplay (*PFN_eglGetDisplay)(EGLNativeDisplayType native_display);
typedef EGLBoolean (*PFN_eglInitialize)(EGLDisplay display, EGLint *major, EGLint *minor);
typedef const char *(*PFN_eglQueryString)(EGLDisplay display, EGLint name);
typedef EGLint (*PFN_eglGetError)(void);
typedef void *(*PFN_eglGetProcAddress)(const char *name);
typedef EGLDisplay (*PFN_eglGetPlatformDisplay)(EGLenum platform,
                                                 void *native_display,
                                                 const EGLint *attribs);
typedef EGLBoolean (*PFN_eglTerminate)(EGLDisplay display);
typedef EGLBoolean (*PFN_eglQueryDevicesEXT)(EGLint max_devices,
                                             EGLDeviceEXT *devices,
                                             EGLint *num_devices);

#define EGL_EXTENSIONS 0x3055
#define EGL_NO_DISPLAY ((EGLDisplay)0)
#define EGL_PLATFORM_DEVICE_EXT 0x313F
#define EGL_PLATFORM_X11_KHR 0x31D5
#define EGL_PLATFORM_GBM_KHR 0x31D7
#define EGL_PLATFORM_WAYLAND_KHR 0x31D8
#define EGL_PLATFORM_DRM_MESA 0x31D9
#define EGL_PLATFORM_SURFACELESS_MESA 0x31DD

static void *load_symbol(void *handle, const char *name) {
    void *symbol = dlsym(handle, name);
    if (!symbol) fprintf(stderr, "P4_PLATFORM_MISSING_SYMBOL=%s\n", name);
    return symbol;
}

static int has_extension(const char *extensions, const char *needle) {
    size_t needle_len;
    const char *cursor;
    if (!extensions || !needle) return 0;
    needle_len = strlen(needle);
    cursor = extensions;
    while ((cursor = strstr(cursor, needle)) != NULL) {
        int left_ok = (cursor == extensions || cursor[-1] == ' ');
        int right_ok = (cursor[needle_len] == '\0' || cursor[needle_len] == ' ');
        if (left_ok && right_ok) return 1;
        cursor += needle_len;
    }
    return 0;
}

static void print_node(const char *path) {
    printf("P4_PLATFORM_NODE=%s PRESENT=%s READABLE=%s\n", path,
           access(path, F_OK) == 0 ? "YES" : "NO",
           access(path, R_OK) == 0 ? "YES" : "NO");
}

static void print_env(const char *name) {
    const char *value = getenv(name);
    printf("P4_PLATFORM_ENV=%s VALUE=%s\n", name, value ? value : "<unset>");
}

static void print_text_file(const char *path) {
    FILE *file = fopen(path, "r");
    char line[256];
    if (!file) {
        printf("P4_PLATFORM_FILE=%s READ=NO\n", path);
        return;
    }
    if (!fgets(line, sizeof(line), file)) line[0] = '\0';
    fclose(file);
    line[strcspn(line, "\r\n")] = '\0';
    printf("P4_PLATFORM_FILE=%s READ=YES VALUE=%s\n", path,
           line[0] ? line : "<empty>");
}

static int try_platform(const char *name, EGLenum platform,
                        PFN_eglGetPlatformDisplay get_platform_display,
                        PFN_eglInitialize initialize, PFN_eglGetError get_error,
                        PFN_eglTerminate terminate) {
    EGLDisplay display;
    EGLint major = 0;
    EGLint minor = 0;
    if (!get_platform_display) return 0;
    display = get_platform_display(platform, NULL, NULL);
    printf("P4_PLATFORM_DISPLAY=%s VALUE=%s ERROR=0x%04x\n", name,
           display ? "NON_NULL" : "NULL", get_error());
    if (!display) return 0;
    if (!initialize(display, &major, &minor)) {
        printf("P4_PLATFORM_INITIALIZE=%s FAIL ERROR=0x%04x\n", name, get_error());
        terminate(display);
        return 0;
    }
    printf("P4_PLATFORM_INITIALIZE=%s PASS VERSION=%d.%d\n", name, major, minor);
    terminate(display);
    return 1;
}

int main(void) {
    static const char *const egl_names[] = {
        "/usr/lib/libEGL.so.1.0.0", "/usr/lib/libEGL.so.1", "libEGL.so.1",
        "libEGL.so", NULL};
    void *egl = NULL;
    EGLDisplay default_display = EGL_NO_DISPLAY;
    const char *client_extensions = NULL;
    int result = 1;
    int platform_pass = 0;
    int i;

    PFN_eglGetDisplay get_display;
    PFN_eglInitialize initialize;
    PFN_eglQueryString query_string;
    PFN_eglGetError get_error;
    PFN_eglGetProcAddress get_proc_address;
    PFN_eglTerminate terminate;
    PFN_eglGetPlatformDisplay get_platform_display;
    PFN_eglQueryDevicesEXT query_devices;

    printf("P4_PLATFORM_PROBE=BEGIN\n");
    print_node("/dev/fb0");
    print_node("/dev/dri/card0");
    print_node("/dev/mali");
    print_node("/dev/ump");
    print_node("/dev/gpu");
    print_text_file("/sys/class/graphics/fb0/name");
    print_env("DISPLAY");
    print_env("WAYLAND_DISPLAY");
    print_env("SDL_VIDEODRIVER");
    print_env("SDL_FBDEV");
    print_env("EGL_PLATFORM");

    for (i = 0; egl_names[i] != NULL; ++i) {
        egl = dlopen(egl_names[i], RTLD_NOW | RTLD_LOCAL);
        if (egl) {
            printf("P4_PLATFORM_LIBRARY=%s\n", egl_names[i]);
            break;
        }
    }
    if (!egl) {
        fprintf(stderr, "P4_PLATFORM_DLOPEN_FAIL=%s\n", dlerror());
        goto cleanup;
    }

    get_display = (PFN_eglGetDisplay)load_symbol(egl, "eglGetDisplay");
    initialize = (PFN_eglInitialize)load_symbol(egl, "eglInitialize");
    query_string = (PFN_eglQueryString)load_symbol(egl, "eglQueryString");
    get_error = (PFN_eglGetError)load_symbol(egl, "eglGetError");
    get_proc_address = (PFN_eglGetProcAddress)load_symbol(egl, "eglGetProcAddress");
    terminate = (PFN_eglTerminate)load_symbol(egl, "eglTerminate");
    if (!get_display || !initialize || !query_string || !get_error || !terminate) goto cleanup;

    client_extensions = query_string(EGL_NO_DISPLAY, EGL_EXTENSIONS);
    printf("P4_PLATFORM_CLIENT_EXTENSIONS=%s\n",
           client_extensions ? client_extensions : "<null>");
    default_display = get_display(NULL);
    printf("P4_PLATFORM_DEFAULT_DISPLAY=%s ERROR=0x%04x\n",
           default_display ? "NON_NULL" : "NULL", get_error());
    if (default_display) {
        EGLint major = 0;
        EGLint minor = 0;
        if (initialize(default_display, &major, &minor)) {
            printf("P4_PLATFORM_DEFAULT_INITIALIZE=PASS VERSION=%d.%d\n", major, minor);
            platform_pass = 1;
            terminate(default_display);
        } else {
            printf("P4_PLATFORM_DEFAULT_INITIALIZE=FAIL ERROR=0x%04x\n", get_error());
        }
    }

    get_platform_display = (PFN_eglGetPlatformDisplay)load_symbol(egl, "eglGetPlatformDisplay");
    if (!get_platform_display && get_proc_address)
        get_platform_display = (PFN_eglGetPlatformDisplay)get_proc_address("eglGetPlatformDisplay");
    if (!get_platform_display && get_proc_address)
        get_platform_display = (PFN_eglGetPlatformDisplay)get_proc_address("eglGetPlatformDisplayEXT");
    printf("P4_PLATFORM_GET_PLATFORM_DISPLAY=%s\n",
           get_platform_display ? "AVAILABLE" : "MISSING");

    if (has_extension(client_extensions, "EGL_EXT_platform_device")) {
        query_devices = (PFN_eglQueryDevicesEXT)load_symbol(egl, "eglQueryDevicesEXT");
        if (!query_devices && get_proc_address)
            query_devices = (PFN_eglQueryDevicesEXT)get_proc_address("eglQueryDevicesEXT");
        if (query_devices && get_platform_display) {
            EGLDeviceEXT devices[4];
            EGLint count = 0;
            if (query_devices(4, devices, &count)) {
                printf("P4_PLATFORM_DEVICES=PASS COUNT=%d\n", count);
                for (i = 0; i < count && i < 4; ++i) {
                    EGLDisplay display = get_platform_display(EGL_PLATFORM_DEVICE_EXT,
                                                              devices[i], NULL);
                    EGLint major = 0;
                    EGLint minor = 0;
                    printf("P4_PLATFORM_DEVICE_DISPLAY[%d]=%s ERROR=0x%04x\n", i,
                           display ? "NON_NULL" : "NULL", get_error());
                    if (display && initialize(display, &major, &minor)) {
                        printf("P4_PLATFORM_DEVICE_INITIALIZE[%d]=PASS VERSION=%d.%d\n",
                               i, major, minor);
                        platform_pass = 1;
                        terminate(display);
                    } else if (display) {
                        printf("P4_PLATFORM_DEVICE_INITIALIZE[%d]=FAIL ERROR=0x%04x\n",
                               i, get_error());
                    }
                }
            } else {
                printf("P4_PLATFORM_DEVICES=FAIL ERROR=0x%04x\n", get_error());
            }
        } else {
            printf("P4_PLATFORM_DEVICE_ENUMERATION=UNAVAILABLE\n");
        }
    } else {
        printf("P4_PLATFORM_DEVICE_EXTENSION=ABSENT\n");
    }

    if (has_extension(client_extensions, "EGL_KHR_platform_x11"))
        platform_pass |= try_platform("X11", EGL_PLATFORM_X11_KHR, get_platform_display,
                                      initialize, get_error, terminate);
    if (has_extension(client_extensions, "EGL_KHR_platform_gbm") ||
        has_extension(client_extensions, "EGL_MESA_platform_gbm"))
        platform_pass |= try_platform("GBM", EGL_PLATFORM_GBM_KHR, get_platform_display,
                                      initialize, get_error, terminate);
    if (has_extension(client_extensions, "EGL_KHR_platform_wayland"))
        platform_pass |= try_platform("WAYLAND", EGL_PLATFORM_WAYLAND_KHR, get_platform_display,
                                      initialize, get_error, terminate);
    if (has_extension(client_extensions, "EGL_MESA_platform_drm"))
        platform_pass |= try_platform("DRM_MESA", EGL_PLATFORM_DRM_MESA, get_platform_display,
                                      initialize, get_error, terminate);
    if (has_extension(client_extensions, "EGL_MESA_platform_surfaceless"))
        platform_pass |= try_platform("SURFACELESS_MESA", EGL_PLATFORM_SURFACELESS_MESA,
                                      get_platform_display, initialize, get_error, terminate);

    printf("P4_PLATFORM_RESULT=%s\n", platform_pass ? "PASS" : "REVIEW_REQUIRED");
    result = platform_pass ? 0 : 1;

cleanup:
    if (egl) dlclose(egl);
    if (result != 0) printf("P4_PLATFORM_RESULT=REVIEW_REQUIRED\n");
    return result;
}
