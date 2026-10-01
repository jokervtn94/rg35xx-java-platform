#!/usr/bin/env python3
from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
src = root / "adapter/native/rg35xx_audio_sdl1_mixer.c"
out = root / "build/audio01/rg35xx_audio_sdl1_mixer_trace.c"
expected_blob = "6c12bdf12e16e9ddfbdecf0e60e1330dcc4bcacc"

if not src.is_file():
    raise SystemExit("AUDIO01_STAGE_FAIL source missing")
blob = subprocess.check_output(["git", "-C", str(root), "hash-object", str(src)], text=True).strip()
if blob != expected_blob:
    raise SystemExit("AUDIO01_STAGE_FAIL source blob drift: " + blob)

s = src.read_text(encoding="utf-8")

def replace_once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("AUDIO01_STAGE_FAIL anchor %s count=%d" % (label, n))
    s = s.replace(old, new, 1)

replace_once(
    "static MusicContext *g_contexts;\n",
    "static MusicContext *g_contexts;\n\n"
    "/* AUDIO-01 diagnostic-only trace. No playback control semantics change. */\n"
    "static unsigned long g_audio01_trace_seq;\n"
    "static void audio01_trace(const char *event, void *handle, int loops) {\n"
    "    int playing = (g_audio_open && Mix_PlayingMusic_p) ? Mix_PlayingMusic_p() : -1;\n"
    "    printf(\"RG35XX_AUDIO01_TRACE SEQ=%lu EVENT=%s HANDLE=%p CURRENT=%p LOOPS=%d PLAYING=%d\\n\",\n"
    "           ++g_audio01_trace_seq, event, handle, g_current_music, loops, playing);\n"
    "    fflush(stdout);\n"
    "}\n",
    "trace-helper")

replace_once(
    "    if (Mix_HookMusicFinished_p) Mix_HookMusicFinished_p(0);\n    ctx = find_context(g_current_music);",
    "    audio01_trace(\"CALLBACK_BEGIN\", g_current_music, 0);\n"
    "    if (Mix_HookMusicFinished_p) Mix_HookMusicFinished_p(0);\n"
    "    ctx = find_context(g_current_music);",
    "callback")

replace_once(
    "    music = Mix_LoadMUS_p(path);\n    (*env)->ReleaseStringUTFChars(env, filePath, path);",
    "    music = Mix_LoadMUS_p(path);\n"
    "    printf(\"RG35XX_AUDIO01_LOAD_MIDI PATH=%s HANDLE=%p PLAYER=%p\\n\", path, music, (void *)player);\n"
    "    fflush(stdout);\n"
    "    (*env)->ReleaseStringUTFChars(env, filePath, path);",
    "load-midi")

replace_once(
    "    chunk = Mix_LoadWAV_RW_p(rw, 1);\n    if (!chunk) {",
    "    chunk = Mix_LoadWAV_RW_p(rw, 1);\n"
    "    printf(\"RG35XX_AUDIO01_LOAD_WAV HANDLE=%p\\n\", chunk);\n"
    "    fflush(stdout);\n"
    "    if (!chunk) {",
    "load-wav")

replace_once(
    "    if (!g_audio_open || !music) return -1;\n    Mix_HaltMusic_p();\n    g_current_music = music;",
    "    if (!g_audio_open || !music) return -1;\n"
    "    audio01_trace(\"PLAY_MIDI_BEFORE_HALT\", music, loops);\n"
    "    Mix_HaltMusic_p();\n"
    "    audio01_trace(\"PLAY_MIDI_AFTER_HALT\", music, loops);\n"
    "    g_current_music = music;",
    "play-midi-before")

replace_once(
    "    printf(\"RG35XX_A7_AUDIO_MIDI_PLAY=PASS LOOPS=%d\\n\", (int)loops);",
    "    audio01_trace(\"PLAY_MIDI_AFTER_PLAY\", music, loops);\n"
    "    printf(\"RG35XX_A7_AUDIO_MIDI_PLAY=PASS LOOPS=%d\\n\", (int)loops);",
    "play-midi-after")

replace_once(
    "    if (!g_audio_open || !chunk) return -1;\n    Mix_HaltChannel_p(RG35XX_WAV_CHANNEL);",
    "    if (!g_audio_open || !chunk) return -1;\n"
    "    audio01_trace(\"PLAY_WAV_BEFORE_HALT\", chunk, loops);\n"
    "    Mix_HaltChannel_p(RG35XX_WAV_CHANNEL);",
    "play-wav-before")

replace_once(
    "    printf(\"RG35XX_A7_AUDIO_WAV_PLAY=PASS LOOPS=%d\\n\", (int)loops);",
    "    audio01_trace(\"PLAY_WAV_AFTER_PLAY\", chunk, loops);\n"
    "    printf(\"RG35XX_A7_AUDIO_WAV_PLAY=PASS LOOPS=%d\\n\", (int)loops);",
    "play-wav-after")

replace_once(
    "JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseMusic\n  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) Mix_PauseMusic_p(); }\n"
    "JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeMusic\n  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) Mix_ResumeMusic_p(); }\n"
    "JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopMusic\n  (JNIEnv *env, jobject obj) { (void)env; (void)obj; if (g_audio_open) { Mix_HookMusicFinished_p(0); Mix_HaltMusic_p(); } }\n"
    "JNIEXPORT jboolean JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlaying\n  (JNIEnv *env, jobject obj) { (void)env; (void)obj; return (g_audio_open && Mix_PlayingMusic_p()) ? JNI_TRUE : JNI_FALSE; }",
    "JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerPauseMusic\n"
    "  (JNIEnv *env, jobject obj) {\n"
    "    (void)env; (void)obj; audio01_trace(\"PAUSE_MIDI\", g_current_music, 0);\n"
    "    if (g_audio_open) Mix_PauseMusic_p();\n"
    "  }\n"
    "JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerResumeMusic\n"
    "  (JNIEnv *env, jobject obj) {\n"
    "    (void)env; (void)obj; audio01_trace(\"RESUME_MIDI\", g_current_music, 0);\n"
    "    if (g_audio_open) Mix_ResumeMusic_p();\n"
    "  }\n"
    "JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerStopMusic\n"
    "  (JNIEnv *env, jobject obj) {\n"
    "    (void)env; (void)obj; audio01_trace(\"STOP_MIDI\", g_current_music, 0);\n"
    "    if (g_audio_open) { Mix_HookMusicFinished_p(0); Mix_HaltMusic_p(); }\n"
    "  }\n"
    "JNIEXPORT jboolean JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerIsPlaying\n"
    "  (JNIEnv *env, jobject obj) {\n"
    "    jboolean r; (void)env; (void)obj;\n"
    "    r = (g_audio_open && Mix_PlayingMusic_p()) ? JNI_TRUE : JNI_FALSE;\n"
    "    audio01_trace(r ? \"ISPLAYING_MIDI_TRUE\" : \"ISPLAYING_MIDI_FALSE\", g_current_music, 0);\n"
    "    return r;\n"
    "  }",
    "midi-controls")

replace_once(
    "    if (!music) return;\n    if (g_current_music == music) {",
    "    if (!music) return;\n"
    "    audio01_trace(\"FREE_MIDI_BEGIN\", music, 0);\n"
    "    if (g_current_music == music) {",
    "free-midi-begin")

replace_once(
    "    remove_context(env, music);\n    if (Mix_FreeMusic_p) Mix_FreeMusic_p(music);",
    "    remove_context(env, music);\n"
    "    if (Mix_FreeMusic_p) Mix_FreeMusic_p(music);\n"
    "    audio01_trace(\"FREE_MIDI_END\", music, 0);",
    "free-midi-end")

replace_once(
    "JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit\n  (JNIEnv *env, jclass cls) {\n    (void)cls;",
    "JNIEXPORT void JNICALL Java_org_recompile_mobile_SdlMixerManager_sdlMixerQuit\n"
    "  (JNIEnv *env, jclass cls) {\n"
    "    (void)cls;\n"
    "    audio01_trace(\"QUIT_BEGIN\", g_current_music, 0);",
    "quit")

out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(s, encoding="utf-8")
print("AUDIO01_STAGE_SOURCE_BLOB=" + blob)
print("AUDIO01_TRACE_MARKER_COUNT=" + str(s.count("RG35XX_AUDIO01_")))
print("AUDIO01_STAGE=PASS")
