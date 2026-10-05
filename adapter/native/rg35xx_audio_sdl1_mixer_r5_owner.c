#define Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi_legacy
#define Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseMusic Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseMusic_legacy
#define Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeMusic Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeMusic_legacy
#define Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopMusic Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopMusic_legacy
#define Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlaying Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlaying_legacy
#define Java_org_recompile_mobile_SdlMixerManager_sdlMixerFreeMusic Java_org_recompile_mobile_SdlMixerManager_sdlMixerFreeMusic_legacy
#define Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit_legacy
#include "rg35xx_audio_sdl1_mixer.c"
#undef Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi
#undef Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseMusic
#undef Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeMusic
#undef Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopMusic
#undef Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlaying
#undef Java_org_recompile_mobile_SdlMixerManager_sdlMixerFreeMusic
#undef Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit

/*
 * R5 candidate: bind the canonical per-PlatformPlayer SdlMixerManager instance
 * to the SDL1_mixer Mix_Music handle it loaded. SDL_mixer exposes only one
 * global music slot, while canonical Java keeps independent Player objects.
 *
 * Canonical Java/MMAPI is intentionally unchanged. pause/resume/isPlaying/stop
 * affect only the Mix_Music currently owned by the calling manager.
 */
typedef struct RG35XXOwnerContext {
    jobject manager;
    void *music;
    struct RG35XXOwnerContext *next;
} RG35XXOwnerContext;

static RG35XXOwnerContext *g_owner_contexts;

static RG35XXOwnerContext *owner_find(JNIEnv *env, jobject manager) {
    RG35XXOwnerContext *p = g_owner_contexts;
    if (!manager) return 0;
    while (p) {
        if (p->manager && (*env)->IsSameObject(env, p->manager, manager) == JNI_TRUE) return p;
        p = p->next;
    }
    return 0;
}

static void owner_bind(JNIEnv *env, jobject manager, void *music) {
    RG35XXOwnerContext *ctx;
    if (!manager || !music) return;
    ctx = owner_find(env, manager);
    if (ctx) {
        ctx->music = music;
        return;
    }
    ctx = (RG35XXOwnerContext *)calloc(1, sizeof(*ctx));
    if (!ctx) return;
    ctx->manager = (*env)->NewGlobalRef(env, manager);
    if (!ctx->manager) {
        free(ctx);
        return;
    }
    ctx->music = music;
    ctx->next = g_owner_contexts;
    g_owner_contexts = ctx;
}

static void owner_remove_music(JNIEnv *env, void *music) {
    RG35XXOwnerContext **pp = &g_owner_contexts;
    while (*pp) {
        RG35XXOwnerContext *p = *pp;
        if (p->music == music) {
            *pp = p->next;
            if (p->manager) (*env)->DeleteGlobalRef(env, p->manager);
            free(p);
            return;
        }
        pp = &p->next;
    }
}

static void owner_clear(JNIEnv *env) {
    RG35XXOwnerContext *p = g_owner_contexts;
    while (p) {
        RG35XXOwnerContext *next = p->next;
        if (p->manager) (*env)->DeleteGlobalRef(env, p->manager);
        free(p);
        p = next;
    }
    g_owner_contexts = 0;
}

static int owner_is_current(JNIEnv *env, jobject manager) {
    RG35XXOwnerContext *ctx = owner_find(env, manager);
    return ctx && ctx->music && ctx->music == g_current_music;
}

JNIEXPORT jlong JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi
  (JNIEnv *env, jobject obj, jstring filePath, jobject player) {
    jlong handle = Java_org_recompile_mobile_SdlMixerManager_sdlMixerLoadMidi_legacy(env, obj, filePath, player);
    if (handle != (jlong)-1 && handle != (jlong)0) {
        owner_bind(env, obj, (void *)(intptr_t)handle);
        printf("RG35XX_R5_AUDIO_OWNER_BIND=PASS\n");
        fflush(stdout);
    }
    return handle;
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseMusic
  (JNIEnv *env, jobject obj) {
    if (g_audio_open && owner_is_current(env, obj)) {
        Mix_PauseMusic_p();
        printf("RG35XX_R5_AUDIO_OWNER_PAUSE=CURRENT\n");
    } else {
        printf("RG35XX_R5_AUDIO_OWNER_PAUSE=IGNORED_NONOWNER\n");
    }
    fflush(stdout);
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeMusic
  (JNIEnv *env, jobject obj) {
    if (g_audio_open && owner_is_current(env, obj)) {
        Mix_ResumeMusic_p();
        printf("RG35XX_R5_AUDIO_OWNER_RESUME=CURRENT\n");
    } else {
        printf("RG35XX_R5_AUDIO_OWNER_RESUME=IGNORED_NONOWNER\n");
    }
    fflush(stdout);
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopMusic
  (JNIEnv *env, jobject obj) {
    if (g_audio_open && owner_is_current(env, obj)) {
        Mix_HookMusicFinished_p(0);
        Mix_HaltMusic_p();
        g_current_music = 0;
        printf("RG35XX_R5_AUDIO_OWNER_STOP=CURRENT\n");
    } else {
        printf("RG35XX_R5_AUDIO_OWNER_STOP=IGNORED_NONOWNER\n");
    }
    fflush(stdout);
}

JNIEXPORT jboolean JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlaying
  (JNIEnv *env, jobject obj) {
    if (!g_audio_open || !owner_is_current(env, obj)) return JNI_FALSE;
    return Mix_PlayingMusic_p() ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerFreeMusic
  (JNIEnv *env, jobject obj, jlong musicHandle) {
    void *music = (void *)(intptr_t)musicHandle;
    (void)obj;
    if (music) owner_remove_music(env, music);
    Java_org_recompile_mobile_SdlMixerManager_sdlMixerFreeMusic_legacy(env, obj, musicHandle);
}

JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit
  (JNIEnv *env, jclass cls) {
    owner_clear(env);
    Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit_legacy(env, cls);
}
