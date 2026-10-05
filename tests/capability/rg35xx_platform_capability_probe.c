#define _GNU_SOURCE
#include <arpa/inet.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>

static void emit_kv(const char *key, const char *value) {
    printf("%s=%s\n", key, value ? value : "<null>");
}

static void emit_errno(const char *key) {
    printf("%s=FAIL ERRNO=%d MSG=%s\n", key, errno, strerror(errno));
}

static void *thread_worker(void *arg) {
    volatile int *value = (volatile int *)arg;
    *value = 0x35;
    return NULL;
}

static void test_thread(void) {
    pthread_t thread;
    volatile int value = 0;
    int rc = pthread_create(&thread, NULL, thread_worker, (void *)&value);
    if (rc != 0) {
        printf("CAP_THREAD_CREATE=FAIL RC=%d\n", rc);
        return;
    }
    rc = pthread_join(thread, NULL);
    if (rc == 0 && value == 0x35) {
        emit_kv("CAP_THREAD_CREATE_JOIN", "PASS");
    } else {
        printf("CAP_THREAD_CREATE_JOIN=FAIL RC=%d VALUE=%d\n", rc, (int)value);
    }
}

static void test_time(void) {
    struct timeval tv;
    if (gettimeofday(&tv, NULL) == 0) {
        printf("CAP_GETTIMEOFDAY=PASS SEC=%ld USEC=%ld\n", (long)tv.tv_sec, (long)tv.tv_usec);
    } else {
        emit_errno("CAP_GETTIMEOFDAY");
    }
}

static void test_mmap(void) {
    long page = sysconf(_SC_PAGESIZE);
    void *mem;
    if (page <= 0) page = 4096;
    mem = mmap(NULL, (size_t)page, PROT_READ | PROT_WRITE,
               MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mem == MAP_FAILED) {
        emit_errno("CAP_MMAP_RW");
        return;
    }
    memset(mem, 0x5a, (size_t)page);
    emit_kv("CAP_MMAP_RW", "PASS");
    if (mprotect(mem, (size_t)page, PROT_READ | PROT_EXEC) == 0) {
        emit_kv("CAP_MPROTECT_RX", "PASS");
    } else {
        emit_errno("CAP_MPROTECT_RX");
    }
    munmap(mem, (size_t)page);
}

static void test_filesystem(const char *dir) {
    char path_a[512];
    char path_b[512];
    const char payload[] = "RG35XX_CAPABILITY_PROBE\n";
    char buf[64];
    int fd;
    ssize_t n;

    if (!dir || strlen(dir) > 400) {
        emit_kv("CAP_FILESYSTEM_ACTIVE", "FAIL_BAD_DIR");
        return;
    }
    snprintf(path_a, sizeof(path_a), "%s/.capability-probe-a.tmp", dir);
    snprintf(path_b, sizeof(path_b), "%s/.capability-probe-b.tmp", dir);
    unlink(path_a);
    unlink(path_b);

    fd = open(path_a, O_CREAT | O_TRUNC | O_RDWR, 0600);
    if (fd < 0) {
        emit_errno("CAP_FS_CREATE");
        return;
    }
    emit_kv("CAP_FS_CREATE", "PASS");

    n = write(fd, payload, sizeof(payload) - 1);
    if (n != (ssize_t)(sizeof(payload) - 1)) {
        emit_errno("CAP_FS_WRITE");
        close(fd);
        unlink(path_a);
        return;
    }
    emit_kv("CAP_FS_WRITE", "PASS");
    if (fsync(fd) == 0) emit_kv("CAP_FS_FSYNC", "PASS");
    else emit_errno("CAP_FS_FSYNC");
    close(fd);

    if (rename(path_a, path_b) != 0) {
        emit_errno("CAP_FS_RENAME");
        unlink(path_a);
        return;
    }
    emit_kv("CAP_FS_RENAME", "PASS");

    fd = open(path_b, O_RDONLY);
    if (fd < 0) {
        emit_errno("CAP_FS_REOPEN");
        unlink(path_b);
        return;
    }
    memset(buf, 0, sizeof(buf));
    n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (n == (ssize_t)(sizeof(payload) - 1) && memcmp(buf, payload, sizeof(payload) - 1) == 0) {
        emit_kv("CAP_FS_READBACK", "PASS");
    } else {
        printf("CAP_FS_READBACK=FAIL BYTES=%ld\n", (long)n);
    }

    if (unlink(path_b) == 0) emit_kv("CAP_FS_DELETE", "PASS");
    else emit_errno("CAP_FS_DELETE");
}

static void test_network(void) {
    int fd;
    struct sockaddr_in addr;
    socklen_t addrlen = (socklen_t)sizeof(addr);
    struct addrinfo hints;
    struct addrinfo *res = NULL;
    int rc;

    fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd >= 0) {
        emit_kv("CAP_SOCKET_UDP", "PASS");
        close(fd);
    } else {
        emit_errno("CAP_SOCKET_UDP");
    }

    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        emit_errno("CAP_SOCKET_TCP");
    } else {
        emit_kv("CAP_SOCKET_TCP", "PASS");
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        addr.sin_port = htons(0);
        if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) == 0 &&
            getsockname(fd, (struct sockaddr *)&addr, &addrlen) == 0 &&
            listen(fd, 1) == 0) {
            printf("CAP_SOCKET_LOOPBACK_LISTEN=PASS PORT=%u\n", (unsigned)ntohs(addr.sin_port));
        } else {
            emit_errno("CAP_SOCKET_LOOPBACK_LISTEN");
        }
        close(fd);
    }

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    rc = getaddrinfo("localhost", NULL, &hints, &res);
    if (rc == 0) {
        emit_kv("CAP_GETADDRINFO_LOCALHOST", "PASS");
        freeaddrinfo(res);
    } else {
        printf("CAP_GETADDRINFO_LOCALHOST=FAIL RC=%d MSG=%s\n", rc, gai_strerror(rc));
    }
}

static void check_library(const char *label,
                          const char *const *candidates,
                          const char *const *symbols) {
    void *handle = NULL;
    int i;
    int all_symbols = 1;
    const char *loaded = NULL;

    for (i = 0; candidates[i]; ++i) {
        dlerror();
        handle = dlopen(candidates[i], RTLD_LAZY | RTLD_LOCAL);
        if (handle) {
            loaded = candidates[i];
            break;
        }
    }

    if (!handle) {
        printf("CAP_LIB_%s_LOAD=NOT_FOUND_OR_UNLOADABLE\n", label);
        return;
    }

    printf("CAP_LIB_%s_LOAD=PASS PATH=%s\n", label, loaded);
    for (i = 0; symbols && symbols[i]; ++i) {
        void *sym;
        dlerror();
        sym = dlsym(handle, symbols[i]);
        if (sym) {
            printf("CAP_LIB_%s_SYMBOL_%s=PASS\n", label, symbols[i]);
        } else {
            printf("CAP_LIB_%s_SYMBOL_%s=FAIL\n", label, symbols[i]);
            all_symbols = 0;
        }
    }
    printf("CAP_LIB_%s_REQUIRED_SYMBOLS=%s\n", label, all_symbols ? "PASS" : "PARTIAL");
    dlclose(handle);
}

static void print_abi(void) {
    union { uint32_t u; unsigned char b[4]; } endian;
    endian.u = 0x01020304u;
    printf("CAP_ABI_POINTER_BITS=%u\n", (unsigned)(sizeof(void *) * 8u));
    printf("CAP_ABI_LONG_BITS=%u\n", (unsigned)(sizeof(long) * 8u));
    printf("CAP_ABI_ENDIAN=%s\n", endian.b[0] == 0x04 ? "LITTLE" : (endian.b[0] == 0x01 ? "BIG" : "UNKNOWN"));
#ifdef __arm__
    emit_kv("CAP_ABI_ARM", "YES");
#else
    emit_kv("CAP_ABI_ARM", "NO");
#endif
#ifdef __ARM_PCS_VFP
    emit_kv("CAP_ABI_ARM_HARDFLOAT_COMPILE", "YES");
#else
    emit_kv("CAP_ABI_ARM_HARDFLOAT_COMPILE", "NO_OR_UNKNOWN");
#endif
#ifdef __ARM_NEON
    emit_kv("CAP_ABI_NEON_COMPILE", "YES");
#else
    emit_kv("CAP_ABI_NEON_COMPILE", "NO_OR_UNKNOWN");
#endif
}

int main(int argc, char **argv) {
    const char *evidence_dir = argc > 1 ? argv[1] : "/tmp";

    static const char *const sdl1_libs[] = {
        "libSDL-1.2.so.0", "libSDL.so", "/usr/lib/libSDL-1.2.so.0", NULL};
    static const char *const sdl1_syms[] = {
        "SDL_Init", "SDL_SetVideoMode", "SDL_PollEvent", "SDL_GetVideoInfo", NULL};
    static const char *const sdl2_libs[] = {
        "libSDL2-2.0.so.0", "libSDL2.so", "/usr/lib/libSDL2-2.0.so.0", NULL};
    static const char *const sdl2_syms[] = {
        "SDL_Init", "SDL_CreateWindow", "SDL_PollEvent", "SDL_GetCurrentVideoDriver", NULL};
    static const char *const sdlmixer1_libs[] = {
        "libSDL_mixer-1.2.so.0", "libSDL_mixer.so", NULL};
    static const char *const sdlmixer2_libs[] = {
        "libSDL2_mixer-2.0.so.0", "libSDL2_mixer.so", NULL};
    static const char *const mixer_syms[] = {
        "Mix_OpenAudio", "Mix_LoadWAV_RW", "Mix_PlayChannelTimed", NULL};
    static const char *const egl_libs[] = {
        "libEGL.so.1", "libEGL.so", "/usr/lib/libEGL.so.1.0.0", NULL};
    static const char *const egl_syms[] = {
        "eglGetDisplay", "eglInitialize", "eglChooseConfig", "eglCreateContext", NULL};
    static const char *const gles1_libs[] = {
        "libGLESv1_CM.so.1", "libGLESv1_CM.so", "libGLES_CM.so", NULL};
    static const char *const gles1_syms[] = {
        "glGetString", "glClear", "glDrawArrays", NULL};
    static const char *const gles2_libs[] = {
        "libGLESv2.so.2", "libGLESv2.so", NULL};
    static const char *const gles2_syms[] = {
        "glGetString", "glCreateShader", "glShaderSource", "glCompileShader", NULL};
    static const char *const zlib_libs[] = {
        "libz.so.1", "libz.so", NULL};
    static const char *const zlib_syms[] = {
        "inflateInit_", "inflate", "deflateInit_", NULL};
    static const char *const png_libs[] = {
        "libpng16.so.16", "libpng16.so", "libpng12.so.0", "libpng12.so", "libpng.so", NULL};
    static const char *const png_syms[] = {
        "png_create_read_struct", "png_read_info", NULL};
    static const char *const jpeg_libs[] = {
        "libjpeg.so.62", "libjpeg.so.8", "libjpeg.so", NULL};
    static const char *const jpeg_syms[] = {
        "jpeg_std_error", "jpeg_CreateDecompress", NULL};
    static const char *const freetype_libs[] = {
        "libfreetype.so.6", "libfreetype.so", NULL};
    static const char *const freetype_syms[] = {
        "FT_Init_FreeType", "FT_New_Face", NULL};
    static const char *const sdlttf1_libs[] = {
        "libSDL_ttf-2.0.so.0", "libSDL_ttf.so", NULL};
    static const char *const sdlttf2_libs[] = {
        "libSDL2_ttf-2.0.so.0", "libSDL2_ttf.so", NULL};
    static const char *const ttf_syms[] = {
        "TTF_Init", "TTF_OpenFont", NULL};
    static const char *const alsa_libs[] = {
        "libasound.so.2", "libasound.so", NULL};
    static const char *const alsa_syms[] = {
        "snd_pcm_open", "snd_pcm_close", NULL};
    static const char *const bluetooth_libs[] = {
        "libbluetooth.so.3", "libbluetooth.so", NULL};
    static const char *const bluetooth_syms[] = {
        "hci_get_route", "hci_open_dev", NULL};
    static const char *const ssl_libs[] = {
        "libssl.so.3", "libssl.so.1.1", "libssl.so.1.0.0", "libssl.so", NULL};
    static const char *const ssl_syms[] = {
        "SSL_CTX_new", "SSL_new", NULL};
    static const char *const stdcpp_libs[] = {
        "libstdc++.so.6", "libstdc++.so", NULL};

    printf("RG35XX_NATIVE_CAPABILITY_PROBE=BEGIN\n");
    print_abi();
    test_time();
    test_thread();
    test_mmap();
    test_filesystem(evidence_dir);
    test_network();

    check_library("SDL1", sdl1_libs, sdl1_syms);
    check_library("SDL2", sdl2_libs, sdl2_syms);
    check_library("SDL_MIXER1", sdlmixer1_libs, mixer_syms);
    check_library("SDL_MIXER2", sdlmixer2_libs, mixer_syms);
    check_library("EGL", egl_libs, egl_syms);
    check_library("GLES1", gles1_libs, gles1_syms);
    check_library("GLES2", gles2_libs, gles2_syms);
    check_library("ZLIB", zlib_libs, zlib_syms);
    check_library("PNG", png_libs, png_syms);
    check_library("JPEG", jpeg_libs, jpeg_syms);
    check_library("FREETYPE", freetype_libs, freetype_syms);
    check_library("SDL_TTF1", sdlttf1_libs, ttf_syms);
    check_library("SDL_TTF2", sdlttf2_libs, ttf_syms);
    check_library("ALSA", alsa_libs, alsa_syms);
    check_library("BLUETOOTH", bluetooth_libs, bluetooth_syms);
    check_library("OPENSSL", ssl_libs, ssl_syms);
    check_library("LIBSTDCXX", stdcpp_libs, NULL);

    printf("RG35XX_NATIVE_CAPABILITY_PROBE=END\n");
    return 0;
}
