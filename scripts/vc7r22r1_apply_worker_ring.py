#!/usr/bin/env python3
"""VC7R22-R1 fail-closed Golden-style worker-ring reconstruction.

R1 restores asynchronous ownership only. It intentionally keeps the historical
44.1 kHz stereo mixer/TSF path; recovered Golden 14700 Hz mono x3 staging is a
separate R2 checkpoint.
"""
import pathlib
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: vc7r22r1_apply_worker_ring.py freej2me_libretro.c")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s

if "RG35XX-VC7R22R1-WORKER-RING" in s:
    raise SystemExit("VC7R22-R1 worker-ring already applied")
if "RG35XX-VC7R3-AUDIO-NATIVE" not in s:
    raise SystemExit("VC7R22-R1 FAIL: VC7R3 foundation missing")


def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("VC7R22-R1 FAIL: %s count=%d" % (label, n))
    s = s.replace(old, new, 1)


old = r'''#define RG35XX_AUDIO_FRAMES_PER_RUN 735u
static int16_t rg35xx_audio_run_buffer[RG35XX_AUDIO_FRAMES_PER_RUN*2u];
static void rg35xx_pump_media_audio(void){int drained=rg35xx_audio_pipe_drain(&rg35xx_java_audio_pipe);size_t frames;if(drained<0&&rg35xx_java_audio_pipe.read_fd>=0)log_fn(RETRO_LOG_WARN,"RG35XX VC7R3 audio pipe drain failed.\n");frames=rg35xx_mixer_render(rg35xx_audio_run_buffer,RG35XX_AUDIO_FRAMES_PER_RUN);if(AudioBatch&&soundEnabled&&frames>0)AudioBatch(rg35xx_audio_run_buffer,frames);{struct rg35xx_media_event_record e;while(rg35xx_media_event_queue_pop(&e))rg35xx_send_media_event(&e);}}
static void rg35xx_native_media_init(void){rg35xx_media_cache_reset();rg35xx_media_event_queue_reset();rg35xx_mixer_init(rg35xx_core_media_event);if(rg35xx_load_soundfont_bytes()&&!rg35xx_media_runtime_init(rg35xx_soundfont_bytes,rg35xx_soundfont_size))log_fn(RETRO_LOG_WARN,"RG35XX VC7R3 MIDI runtime init failed; PCM remains available.\n");}
static void rg35xx_native_media_shutdown(void){rg35xx_audio_pipe_close(&rg35xx_java_audio_pipe);rg35xx_mixer_reset();rg35xx_media_event_queue_reset();rg35xx_media_cache_reset();rg35xx_media_runtime_shutdown();rg35xx_release_soundfont_bytes();}
'''

new = r'''/* RG35XX-VC7R22R1-WORKER-RING
 * Java media FD -> dedicated worker -> mixer -> ring -> async callback.
 * retro_run() has no audio drain/render ownership.
 */
#define RG35XX_AUDIO_RING_FRAMES 16384u
#define RG35XX_AUDIO_WORKER_CHUNK 1470u
#define RG35XX_AUDIO_PRIME_FRAMES 3072u
#define RG35XX_AUDIO_HIGH_WATER (RG35XX_AUDIO_PRIME_FRAMES + RG35XX_AUDIO_WORKER_CHUNK)

static int16_t rg35xx_audio_ring[RG35XX_AUDIO_RING_FRAMES * 2u];
static int16_t rg35xx_audio_worker_buffer[RG35XX_AUDIO_WORKER_CHUNK * 2u];
static int16_t rg35xx_audio_callback_buffer[RG35XX_AUDIO_WORKER_CHUNK * 2u];
static size_t rg35xx_audio_ring_read;
static size_t rg35xx_audio_ring_write;
static size_t rg35xx_audio_ring_count;
static int rg35xx_audio_ring_primed;
static int rg35xx_audio_worker_running;
static int rg35xx_audio_worker_started;
static int rg35xx_async_audio_registered;
static int rg35xx_async_audio_enabled;
static unsigned int rg35xx_audio_underrun_log_budget = 8u;
static pthread_t rg35xx_audio_worker_thread;
static pthread_mutex_t rg35xx_audio_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t rg35xx_audio_cond = PTHREAD_COND_INITIALIZER;

static void rg35xx_audio_ring_reset_locked(void)
{
    rg35xx_audio_ring_read = 0;
    rg35xx_audio_ring_write = 0;
    rg35xx_audio_ring_count = 0;
    rg35xx_audio_ring_primed = 0;
}

static size_t rg35xx_audio_ring_write_locked(const int16_t *src, size_t frames)
{
    size_t i;
    size_t free_frames = RG35XX_AUDIO_RING_FRAMES - rg35xx_audio_ring_count;
    if(frames > free_frames) frames = free_frames;
    for(i = 0; i < frames; ++i) {
        size_t d = rg35xx_audio_ring_write * 2u;
        rg35xx_audio_ring[d] = src[i * 2u];
        rg35xx_audio_ring[d + 1u] = src[i * 2u + 1u];
        rg35xx_audio_ring_write = (rg35xx_audio_ring_write + 1u) % RG35XX_AUDIO_RING_FRAMES;
    }
    rg35xx_audio_ring_count += frames;
    return frames;
}

static size_t rg35xx_audio_ring_read_locked(int16_t *dst, size_t frames)
{
    size_t i;
    if(frames > rg35xx_audio_ring_count) frames = rg35xx_audio_ring_count;
    for(i = 0; i < frames; ++i) {
        size_t q = rg35xx_audio_ring_read * 2u;
        dst[i * 2u] = rg35xx_audio_ring[q];
        dst[i * 2u + 1u] = rg35xx_audio_ring[q + 1u];
        rg35xx_audio_ring_read = (rg35xx_audio_ring_read + 1u) % RG35XX_AUDIO_RING_FRAMES;
    }
    rg35xx_audio_ring_count -= frames;
    return frames;
}

static void rg35xx_audio_send_pending_events(void)
{
    struct rg35xx_media_event_record e;
    while(rg35xx_media_event_queue_pop(&e)) rg35xx_send_media_event(&e);
}

static void *rg35xx_audio_worker(void *unused)
{
    (void)unused;
    log_fn(RETRO_LOG_INFO,
        "RG35XX-AUDIO: worker START ring=16384 target=3072 chunk=1470\n");

    while(rg35xx_audio_worker_running) {
        int drained;
        int can_render;
        size_t frames;
        size_t wrote;

        /* The worker remains the sole command/mixer owner even while the
         * frontend temporarily disables async callback delivery. */
        drained = rg35xx_audio_pipe_drain(&rg35xx_java_audio_pipe);
        if(drained < 0 && rg35xx_java_audio_pipe.read_fd >= 0)
            log_fn(RETRO_LOG_WARN,
                "RG35XX-AUDIO: media pipe drain failed; worker continues.\n");
        rg35xx_audio_send_pending_events();

        pthread_mutex_lock(&rg35xx_audio_mutex);
        can_render = (rg35xx_audio_ring_count + RG35XX_AUDIO_WORKER_CHUNK
                      <= RG35XX_AUDIO_HIGH_WATER);
        pthread_mutex_unlock(&rg35xx_audio_mutex);

        /* Do not fill all 16384 frames with silence. Keep queue depth near the
         * CN prime target while retaining the large capacity for recovery. */
        if(!can_render) {
            usleep(2000u);
            continue;
        }

        frames = rg35xx_mixer_render(
            rg35xx_audio_worker_buffer, RG35XX_AUDIO_WORKER_CHUNK);
        rg35xx_audio_send_pending_events();

        if(frames > 0) {
            pthread_mutex_lock(&rg35xx_audio_mutex);
            wrote = rg35xx_audio_ring_write_locked(
                rg35xx_audio_worker_buffer, frames);
            if(!rg35xx_audio_ring_primed &&
               rg35xx_audio_ring_count >= RG35XX_AUDIO_PRIME_FRAMES) {
                rg35xx_audio_ring_primed = 1;
                log_fn(RETRO_LOG_INFO,
                    "RG35XX-AUDIO: PRIMED queued=%u target=3072\n",
                    (unsigned int)rg35xx_audio_ring_count);
            }
            pthread_mutex_unlock(&rg35xx_audio_mutex);
            if(wrote < frames)
                log_fn(RETRO_LOG_WARN,
                    "RG35XX-AUDIO: ring short write %u/%u\n",
                    (unsigned int)wrote, (unsigned int)frames);
        } else {
            usleep(1000u);
        }
    }

    rg35xx_audio_send_pending_events();
    log_fn(RETRO_LOG_INFO, "RG35XX-AUDIO: worker STOP\n");
    return NULL;
}

static int rg35xx_audio_worker_start(void)
{
    if(rg35xx_audio_worker_started) return 1;
    pthread_mutex_lock(&rg35xx_audio_mutex);
    rg35xx_audio_ring_reset_locked();
    rg35xx_audio_worker_running = 1;
    pthread_mutex_unlock(&rg35xx_audio_mutex);
    if(pthread_create(&rg35xx_audio_worker_thread, NULL,
                      rg35xx_audio_worker, NULL) != 0) {
        pthread_mutex_lock(&rg35xx_audio_mutex);
        rg35xx_audio_worker_running = 0;
        pthread_mutex_unlock(&rg35xx_audio_mutex);
        log_fn(RETRO_LOG_ERROR, "RG35XX-AUDIO: worker create failed\n");
        return 0;
    }
    rg35xx_audio_worker_started = 1;
    return 1;
}

static void rg35xx_audio_worker_stop(void)
{
    if(!rg35xx_audio_worker_started) return;
    pthread_mutex_lock(&rg35xx_audio_mutex);
    rg35xx_audio_worker_running = 0;
    pthread_cond_broadcast(&rg35xx_audio_cond);
    pthread_mutex_unlock(&rg35xx_audio_mutex);
    pthread_join(rg35xx_audio_worker_thread, NULL);
    rg35xx_audio_worker_started = 0;
    pthread_mutex_lock(&rg35xx_audio_mutex);
    rg35xx_audio_ring_reset_locked();
    pthread_mutex_unlock(&rg35xx_audio_mutex);
}

static void rg35xx_audio_callback(void)
{
    size_t frames = 0;
    pthread_mutex_lock(&rg35xx_audio_mutex);
    if(rg35xx_async_audio_enabled && rg35xx_audio_ring_primed) {
        frames = rg35xx_audio_ring_count;
        if(frames > RG35XX_AUDIO_WORKER_CHUNK)
            frames = RG35XX_AUDIO_WORKER_CHUNK;
        if(frames > 0)
            frames = rg35xx_audio_ring_read_locked(
                rg35xx_audio_callback_buffer, frames);
        if(rg35xx_audio_ring_count == 0) {
            rg35xx_audio_ring_primed = 0;
            if(rg35xx_audio_underrun_log_budget) {
                --rg35xx_audio_underrun_log_budget;
                log_fn(RETRO_LOG_WARN,
                    "RG35XX-AUDIO: underrun queued=0; re-prime target=3072\n");
            }
        }
        pthread_cond_signal(&rg35xx_audio_cond);
    }
    pthread_mutex_unlock(&rg35xx_audio_mutex);

    if(frames > 0 && AudioBatch && soundEnabled)
        AudioBatch(rg35xx_audio_callback_buffer, frames);
}

static void rg35xx_audio_set_state(bool enabled)
{
    pthread_mutex_lock(&rg35xx_audio_mutex);
    rg35xx_async_audio_enabled = enabled ? 1 : 0;
    pthread_mutex_unlock(&rg35xx_audio_mutex);

    /* set_state(false) must not stop media command progression. The worker is
     * tied to the Java media FD/process lifecycle, not callback cadence. */
    if(enabled && !rg35xx_audio_worker_started &&
       rg35xx_java_audio_pipe.read_fd >= 0)
        rg35xx_audio_worker_start();
}

static struct retro_audio_callback rg35xx_audio_cb = {
    rg35xx_audio_callback,
    rg35xx_audio_set_state
};

static void rg35xx_register_async_audio(void)
{
    rg35xx_async_audio_registered =
        Environ && Environ(RETRO_ENVIRONMENT_SET_AUDIO_CALLBACK,
                           &rg35xx_audio_cb);
    log_fn(RETRO_LOG_INFO,
        "RG35XX-AUDIO: async callback registered=%d\n",
        rg35xx_async_audio_registered);
}

static void rg35xx_native_media_init(void)
{
    rg35xx_media_cache_reset();
    rg35xx_media_event_queue_reset();
    rg35xx_mixer_init(rg35xx_core_media_event);
    pthread_mutex_lock(&rg35xx_audio_mutex);
    rg35xx_audio_ring_reset_locked();
    rg35xx_async_audio_enabled = 0;
    pthread_mutex_unlock(&rg35xx_audio_mutex);
    if(rg35xx_load_soundfont_bytes() &&
       !rg35xx_media_runtime_init(rg35xx_soundfont_bytes,
                                  rg35xx_soundfont_size))
        log_fn(RETRO_LOG_WARN,
            "RG35XX VC7R22-R1 MIDI runtime init failed; PCM remains available.\n");
    rg35xx_register_async_audio();
}

static void rg35xx_native_media_shutdown(void)
{
    rg35xx_audio_worker_stop();
    rg35xx_audio_pipe_close(&rg35xx_java_audio_pipe);
    rg35xx_mixer_reset();
    rg35xx_media_event_queue_reset();
    rg35xx_media_cache_reset();
    rg35xx_media_runtime_shutdown();
    rg35xx_release_soundfont_bytes();
    rg35xx_async_audio_registered = 0;
    rg35xx_async_audio_enabled = 0;
}
'''

once(old, new, "replace fixed frame pump")
once(
    '''void retro_run(void)\n{\n#ifdef __linux__\n\trg35xx_pump_media_audio();\n#endif\n''',
    '''void retro_run(void)\n{\n''',
    "remove retro_run audio ownership")
once(
    '''\t\tif(rg35xx_java_audio_pipe.read_fd >= 0) rg35xx_audio_pipe_parent_after_fork(&rg35xx_java_audio_pipe);\n\t\tclose(pRead[1]);\n''',
    '''\t\tif(rg35xx_java_audio_pipe.read_fd >= 0) { rg35xx_audio_pipe_parent_after_fork(&rg35xx_java_audio_pipe); rg35xx_audio_worker_start(); }\n\t\tclose(pRead[1]);\n''',
    "start worker after parent FD handoff")

required = (
    "RG35XX-VC7R22R1-WORKER-RING",
    "RG35XX_AUDIO_RING_FRAMES 16384u",
    "RG35XX_AUDIO_WORKER_CHUNK 1470u",
    "RG35XX_AUDIO_PRIME_FRAMES 3072u",
    "RG35XX_AUDIO_HIGH_WATER",
    "RETRO_ENVIRONMENT_SET_AUDIO_CALLBACK",
    "RG35XX-AUDIO: async callback registered=%d",
    "RG35XX-AUDIO: worker START ring=16384 target=3072 chunk=1470",
    "RG35XX-AUDIO: underrun queued=0; re-prime target=3072",
    "rg35xx_audio_worker_stop();",
    "rg35xx_golden_video_present(",
    "RETRO_PIXEL_FORMAT_RGB565",
)
for token in required:
    if token not in s:
        raise SystemExit("VC7R22-R1 FAIL missing: " + token)

for forbidden in (
    "#define RG35XX_AUDIO_FRAMES_PER_RUN 735u",
    "rg35xx_pump_media_audio();",
    "AudioBatch(rg35xx_audio_run_buffer,frames)",
):
    if forbidden in s:
        raise SystemExit("VC7R22-R1 FAIL frame-coupled residue: " + forbidden)

if s == orig:
    raise SystemExit("VC7R22-R1 FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("VC7R22-R1 WORKER-RING OVERLAY=PASS")
print("VC7R22-R1 RING=16384 PRIME=3072 CHUNK=1470")
print("VC7R22-R1 RETRO_RUN_AUDIO_PUMP=REMOVED")
print("VC7R22-R1 WORKER_LIFECYCLE=MEDIA_FD_NOT_CALLBACK_STATE")
print("VC7R22-R1 SYNTH_PATH=44100_STEREO_R1_NOT_GOLDEN_FIDELITY")
