#include <jni.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

/*
 * Original-RG35XX audio adapter for Aweigit's SdlMixerManager JNI surface.
 *
 * Ownership rules:
 * - keep canonical Java MMAPI / PlatformPlayer semantics;
 * - use the device-present SDL 1.2 + SDL_mixer 1.2 libraries;
 * - never call SDL_Quit(), because the accepted A6 SDL1/fbcon video owner is
 *   a separate protected subsystem;
 * - initialize/quit only SDL_INIT_AUDIO and only when media is exercised;
 * - no frame-coupled pumping and no JavaSound fallback.
 */

typedef struct SDL_RWops SDL_RWops;

typedef int (*pSDL_InitSubSystem)(uint32_t);
typedef void (*pSDL_QuitSubSystem)(uint32_t);
typedef SDL_RWops *(*pSDL_RWFromFile)(const char *, const char *);
typedef const char *(*pSDL_GetError)(void);

typedef int (*pMix_OpenAudio)(int, uint16_t, int, int);
typedef void (*pMix_CloseAudio)(void);
typedef void *(*pMix_LoadMUS)(const char *);
typedef void *(*pMix_LoadWAV_RW)(SDL_RWops *, int);
typedef int (*pMix_PlayMusic)(void *, int);
typedef int (*pMix_PlayChannelTimed)(int, void *, int, int);
typedef int (*pMix_HaltMusic)(void);
typedef int (*pMix_HaltChannel)(int);
typedef void (*pMix_HookMusicFinished)(void (*)(void));
typedef void (*pMix_PauseMusic)(void);
typedef void (*pMix_ResumeMusic)(void);
typedef void (*pMix_Pause)(int);
typedef void (*pMix_Resume)(int);
typedef int (*pMix_PlayingMusic)(void);
typedef int (*pMix_Playing)(int);
typedef int (*pMix_VolumeMusic)(int);
typedef int (*pMix_Volume)(int, int);
typedef void (*pMix_FreeMusic)(void *);
typedef void (*pMix_FreeChunk)(void *);

#define SDL_INIT_AUDIO 0x00000010u
#define RG35XX_AUDIO_FREQ 44100
#define RG35XX_AUDIO_S16LSB 0x8010u
#define RG35XX_AUDIO_CHANNELS 2
#define RG35XX_AUDIO_CHUNK 4096
#define RG35XX_WAV_CHANNEL 0

static void *g_sdl;
static void *g_mix;
static int g_audio_open;
static JavaVM *g_vm;
static void *g_current_music;

static pSDL_InitSubSystem SDL_InitSubSystem_p;
static pSDL_QuitSubSystem SDL_QuitSubSystem_p;
static pSDL_RWFromFile SDL_RWFromFile_p;
static pSDL_GetError SDL_GetError_p;
static pMix_OpenAudio Mix_OpenAudio_p;
static pMix_CloseAudio Mix_CloseAudio_p;
static pMix_LoadMUS Mix_LoadMUS_p;
static pMix_LoadWAV_RW Mix_LoadWAV_RW_p;
static pMix_PlayMusic Mix_PlayMusic_p;
static pMix_PlayChannelTimed Mix_PlayChannelTimed_p;
static pMix_HaltMusic Mix_HaltMusic_p;
static pMix_HaltChannel Mix_HaltChannel_p;
static pMix_HookMusicFinished Mix_HookMusicFinished_p;
static pMix_PauseMusic Mix_PauseMusic_p;
static pMix_ResumeMusic Mix_ResumeMusic_p;
static pMix_Pause Mix_Pause_p;
static pMix_Resume Mix_Resume_p;
static pMix_PlayingMusic Mix_PlayingMusic_p;
static pMix_Playing Mix_Playing_p;
static pMix_VolumeMusic Mix_VolumeMusic_p;
static pMix_Volume Mix_Volume_p;
static pMix_FreeMusic Mix_FreeMusic_p;
static pMix_FreeChunk Mix_FreeChunk_p;

typedef struct MusicContext {
    void *music;
    jobject player;
    jmethodID on_complete;
    struct MusicContext *next;
} MusicContext;

static MusicContext *g_contexts;

static const char *sdl_error(void) {
    const char *e = SDL_GetError_p ? SDL_GetError_p() : 0;
    return (e && *e) ? e : "unknown";
}

static void *open_first(const char *const *names) {
    int i;
    void *h = 0;
    for (i = 0; names[i] && !h; ++i) h = dlopen(names[i], RTLD_NOW | RTLD_LOCAL);
    return h;
}

static int load_backend(void) {
    static const char *const sdl_names[] = {
        "/usr/lib/libSDL-1.2.so.0",
        "/usr/lib/libSDL-1.2.so.0.11.4",
        0
    };
    static const char *const mix_names[] = {
        "/usr/lib/libSDL_mixer-1.2.so.0",
        "/usr/lib/libSDL_mixer-1.2.so.0.12.1",
        "/usr/lib/libSDL_mixer-1.2.so.0.12.0",
        0
    };

    if (g_sdl && g_mix) return 0;
    g_sdl = open_first(sdl_names);
    if (!g_sdl) return 101;
    g_mix = open_first(mix_names);
    if (!g_mix) return 102;

#define LOAD_SDL(name) do { name##_p = (p##name)dlsym(g_sdl, #name); if (!name##_p) return 110; } while (0)
#define LOAD_MIX(name) do { name##_p = (p##name)dlsym(g_mix, #name); if (!name##_p) return 120; } while (0)
    LOAD_SDL(SDL_InitSubSystem);
    LOAD_SDL(SDL_QuitSubSystem);
    LOAD_SDL(SDL_RWFromFile);
    LOAD_SDL(SDL_GetError);
    LOAD_MIX(Mix_OpenAudio);
    LOAD_MIX(Mix_CloseAudio);
    LOAD_MIX(Mix_LoadMUS);
    LOAD_MIX(Mix_LoadWAV_RW);
    LOAD_MIX(Mix_PlayMusic);
    LOAD_MIX(Mix_PlayChannelTimed);
    LOAD_MIX(Mix_HaltMusic);
    LOAD_MIX(Mix_HaltChannel);
    LOAD_MIX(Mix_HookMusicFinished);
    LOAD_MIX(Mix_PauseMusic);
    LOAD_MIX(Mix_ResumeMusic);
    LOAD_MIX(Mix_Pause);
    LOAD_MIX(Mix_Resume);
    LOAD_MIX(Mix_PlayingMusic);
    LOAD_MIX(Mix_Playing);
    LOAD_MIX(Mix_VolumeMusic);
    LOAD_MIX(Mix_Volume);
    LOAD_MIX(Mix_FreeMusic);
    LOAD_MIX(Mix_FreeChunk);
#undef LOAD_SDL
#undef LOAD_MIX
    return 0;
}

static MusicContext *find_context(void *music) {
    MusicContext *p = g_contexts;
    while (p) {
        if (p->music == music) return p;
        p = p->next;
    }
    return 0;
}

static void remove_context(JNIEnv *env, void *music) {
    MusicContext **pp = &g_contexts;
    while (*pp) {
        MusicContext *p = *pp;
        if (p->music == music) {
            *pp = p->next;
            if (p->player) (*env)->DeleteGlobalRef(env, p->player);
            free(p);
            return;
        }
        pp = &p->next;
    }
}

static void clear_contexts(JNIEnv *env) {
    MusicContext *p = g_contexts;
    while (p) {
        MusicContext *next = p->next;
        if (p->player) (*env)->DeleteGlobalRef(env, p->player);
        free(p);
        p = next;
    }
    g_contexts = 0;
}

static int get_callback_env(JNIEnv **out) {
    jint rc;
    if (!g_vm) return -1;
    rc = (*g_vm)->GetEnv(g_vm, (void **)out, JNI_VERSION_1_2);
    if (rc == JNI_OK) return 0;
    if (rc != JNI_EDETACHED) return -1;
    if ((*g_vm)->AttachCurrentThread(g_vm, (void **)out, 0) != JNI_OK) return -1;
    return 1;
}

static void music_finished_callback(void) {
    JNIEnv *env = 0;
    int attached;
    MusicContext *ctx;

    if (Mix_HookMusicFinished_p) Mix_HookMusicFinished_p(0);
    ctx = find_context(g_current_music);
    if (!ctx || !ctx->player || !ctx->on_complete) return;

    attached = get_callback_env(&env);
    if (attached < 0 || !env) return;
    (*env)->CallVoidMethod(env, ctx->player, ctx->on_complete);
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
    }
    if (attached > 0) (*g_vm)->DetachCurrentThread(g_vm);
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)reserved;
    g_vm = vm;
    return JNI_VERSION_1_2;
}

JNIEXPORT void JNICALL JNI_OnUnload(JavaVM *vm, void *reserved) {
    (void)vm;
    (void)reserved;
    g_vm = 0;
}

JNIEXPORT jint JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerInit
  (JNIEnv *env, jclass cls, jint frequency, jint format, jint channels, jint chunksize) {
    int rc;
    int freq = frequency > 0 ? frequency : RG35XX_AUDIO_FREQ;
    uint16_t fmt = format != 0 ? (uint16_t)format : (uint16_t)RG35XX_AUDIO_S16LSB;
    int ch = channels > 0 ? channels : RG35XX_AUDIO_CHANNELS;
    int chunk = chunksize > 0 ? chunksize : RG35XX_AUDIO_CHUNK;
    (void)env;
    (void)cls;

    if (g_audio_open) return 0;
    rc = load_backend();
    if (rc) {
        fprintf(stderr, "RG35XX_A7_AUDIO_BACKEND_LOAD_FAIL=%d\n", rc);
        fflush(stderr);
        return -1;
    }
    if (SDL_InitSubSystem_p(SDL_INIT_AUDIO) != 0) {
        fprintf(stderr, "RG35XX_A7_AUDIO_SDL_INIT_FAIL=%s\n", sdl_error());
        fflush(stderr);
        return -1;
    }
    if (Mix_OpenAudio_p(freq, fmt, ch, chunk) != 0) {
        fprintf(stderr, "RG35XX_A7_AUDIO_MIX_OPEN_FAIL=%s\n", sdl_error());
        fflush(stderr);
        SDL_QuitSubSystem_p(SDL_INIT_AUDIO);
        return -1;
    }
    g_audio_open = 1;
    printf("RG35XX_A7_AUDIO_INIT=PASS BACKEND=SDL1_MIXER FREQ=%d FORMAT=%u CHANNELS=%d CHUNK=%d\n",
           freq, (unsigned)fmt, ch, chunk);
    fflush(stdout);
    return 0;
}

JNIEXPORT jint JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlHapticInit
  (JNIEnv *env, jclass cls) {
    (void)env;
    (void)cls;
    return -1;
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlHaptic
  (JNIEnv *env, jclass cls, jint duration) {
    (void)env;
    (void)cls;
    (void)duration;
}

JNIEXPORT jlong JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi
  (JNIEnv *env, jobject obj, jstring filePath, jobject player) {
    const char *path;
    void *music;
    MusicContext *ctx;
    jclass player_class;
    (void)obj;

    if (!g_audio_open || !filePath || !Mix_LoadMUS_p) return (jlong)-1;
    path = (*env)->GetStringUTFChars(env, filePath, 0);
    if (!path) return (jlong)-1;
    music = Mix_LoadMUS_p(path);
    (*env)->ReleaseStringUTFChars(env, filePath, path);
    if (!music) {
        fprintf(stderr, "RG35XX_A7_AUDIO_MIDI_LOAD_FAIL=%s\n", sdl_error());
        fflush(stderr);
        return (jlong)-1;
    }

    if ((*env)->GetJavaVM(env, &g_vm) != JNI_OK) g_vm = 0;
    if (player) {
        ctx = (MusicContext *)calloc(1, sizeof(*ctx));
        if (ctx) {
            ctx->music = music;
            ctx->player = (*env)->NewGlobalRef(env, player);
            player_class = (*env)->GetObjectClass(env, player);
            if (player_class) {
                ctx->on_complete = (*env)->GetMethodID(env, player_class, "onPlaybackComplete", "()V");
                if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
                (*env)->DeleteLocalRef(env, player_class);
            }
            ctx->next = g_contexts;
            g_contexts = ctx;
        }
    }
    printf("RG35XX_A7_AUDIO_MIDI_LOAD=PASS\n");
    fflush(stdout);
    return (jlong)(intptr_t)music;
}

JNIEXPORT jlong JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadWav
  (JNIEnv *env, jobject obj, jstring filePath) {
    const char *path;
    SDL_RWops *rw;
    void *chunk;
    (void)obj;

    if (!g_audio_open || !filePath || !SDL_RWFromFile_p || !Mix_LoadWAV_RW_p) return (jlong)-1;
    path = (*env)->GetStringUTFChars(env, filePath, 0);
    if (!path) return (jlong)-1;
    rw = SDL_RWFromFile_p(path, "rb");
    (*env)->ReleaseStringUTFChars(env, filePath, path);
    if (!rw) {
        fprintf(stderr, "RG35XX_A7_AUDIO_WAV_RW_FAIL=%s\n", sdl_error());
        fflush(stderr);
        return (jlong)-1;
    }
    chunk = Mix_LoadWAV_RW_p(rw, 1);
    if (!chunk) {
        fprintf(stderr, "RG35XX_A7_AUDIO_WAV_LOAD_FAIL=%s\n", sdl_error());
        fflush(stderr);
        return (jlong)-1;
    }
    printf("RG35XX_A7_AUDIO_WAV_LOAD=PASS\n");
    fflush(stdout);
    return (jlong)(intptr_t)chunk;
}

JNIEXPORT jint JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerPlayMusic
  (JNIEnv *env, jobject obj, jlong musicHandle, jint loops) {
    void *music = (void *)(intptr_t)musicHandle;
    (void)env;
    (void)obj;
    if (!g_audio_open || !music) return -1;
    Mix_HaltMusic_p();
    g_current_music = music;
    Mix_HookMusicFinished_p(loops == -1 ? 0 : music_finished_callback);
    if (Mix_PlayMusic_p(music, loops) != 0) {
        Mix_HookMusicFinished_p(0);
        fprintf(stderr, "RG35XX_A7_AUDIO_MIDI_PLAY_FAIL=%s\n", sdl_error());
        fflush(stderr);
        return -1;
    }
    printf("RG35XX_A7_AUDIO_MIDI_PLAY=PASS LOOPS=%d\n", (int)loops);
    fflush(stdout);
    return 0;
}

JNIEXPORT jint JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerPlayWav
  (JNIEnv *env, jobject obj, jlong musicHandle, jint loops) {
    void *chunk = (void *)(intptr_t)musicHandle;
    (void)env;
    (void)obj;
    if (!g_audio_open || !chunk) return -1;
    Mix_HaltChannel_p(RG35XX_WAV_CHANNEL);
    if (Mix_PlayChannelTimed_p(RG35XX_WAV_CHANNEL, chunk, loops, -1) < 0) {
        fprintf(stderr, "RG35XX_A7_AUDIO_WAV_PLAY_FAIL=%s\n", sdl_error());
        fflush(stderr);
        return -1;
    }
    printf("RG35XX_A7_AUDIO_WAV_PLAY=PASS LOOPS=%d\n", (int)loops);
    fflush(stdout);
    return 0;
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseMusic
  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) Mix_PauseMusic_p(); }
JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeMusic
  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) Mix_ResumeMusic_p(); }
JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopMusic
  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) { Mix_HookMusicFinished_p(0); Mix_HaltMusic_p(); } }
JNIEXPORT jboolean JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlaying
  (JNIEnv *env, jobject obj) { (void)env; (void)obj; return (g_audio_open && Mix_PlayingMusic_p()) ? JNI_TRUE : JNI_FALSE; }

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseWav
  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) Mix_Pause_p(RG35XX_WAV_CHANNEL); }
JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeWav
  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) Mix_Resume_p(RG35XX_WAV_CHANNEL); }
JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopWav
  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) Mix_HaltChannel_p(RG35XX_WAV_CHANNEL); }
JNIEXPORT jboolean JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlayingWav
  (JNIEnv *env, jobject obj) { (void)env; (void)obj; return (g_audio_open && Mix_Playing_p(RG35XX_WAV_CHANNEL)) ? JNI_TRUE : JNI_FALSE; }

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerSetVolume
  (JNIEnv *env, jobject obj, jint volume) {
    int v = (128 * (int)volume) / 100;
    (void)env;
    (void)obj;
    if (v < 0) v = 0;
    if (v > 128) v = 128;
    if (g_audio_open) Mix_VolumeMusic_p(v);
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerSetVolumeWav
  (JNIEnv *env, jobject obj, jint volume) {
    int v = (128 * (int)volume) / 100;
    (void)env;
    (void)obj;
    if (v < 0) v = 0;
    if (v > 128) v = 128;
    if (g_audio_open) Mix_Volume_p(RG35XX_WAV_CHANNEL, v);
}

JNIEXPORT jint JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerGetVolume
  (JNIEnv *env, jobject obj) {
    (void)env;
    (void)obj;
    return g_audio_open ? Mix_VolumeMusic_p(-1) : 0;
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerFreeMusic
  (JNIEnv *env, jobject obj, jlong musicHandle) {
    void *music = (void *)(intptr_t)musicHandle;
    (void)obj;
    if (!music) return;
    if (g_current_music == music) {
        if (g_audio_open) { Mix_HookMusicFinished_p(0); Mix_HaltMusic_p(); }
        g_current_music = 0;
    }
    remove_context(env, music);
    if (Mix_FreeMusic_p) Mix_FreeMusic_p(music);
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerFreeWav
  (JNIEnv *env, jobject obj, jlong musicHandle) {
    void *chunk = (void *)(intptr_t)musicHandle;
    (void)env;
    (void)obj;
    if (!chunk) return;
    if (g_audio_open) Mix_HaltChannel_p(RG35XX_WAV_CHANNEL);
    if (Mix_FreeChunk_p) Mix_FreeChunk_p(chunk);
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit
  (JNIEnv *env, jclass cls) {
    (void)cls;
    if (g_audio_open) {
        Mix_HookMusicFinished_p(0);
        Mix_HaltMusic_p();
        Mix_HaltChannel_p(RG35XX_WAV_CHANNEL);
    }
    clear_contexts(env);
    g_current_music = 0;
    if (g_audio_open) {
        Mix_CloseAudio_p();
        SDL_QuitSubSystem_p(SDL_INIT_AUDIO);
        g_audio_open = 0;
    }
    printf("RG35XX_A7_AUDIO_SHUTDOWN=PASS VIDEO_SDL_OWNER_PRESERVED=YES\n");
    fflush(stdout);
}
