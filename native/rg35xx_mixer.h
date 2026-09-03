#ifndef RG35XX_MIXER_H
#define RG35XX_MIXER_H

#include "rg35xx_media_cache.h"
#include "rg35xx_media_events.h"
#include <stdint.h>
#include <stddef.h>

/* Tasklog: RGJ-B3-006 */
#define RG35XX_MIXER_RATE 44100
#define RG35XX_MIXER_CHANNELS 2

void rg35xx_mixer_init(rg35xx_media_event_cb event_cb);
void rg35xx_mixer_reset(void);
int rg35xx_mixer_play(uint32_t player_id);
int rg35xx_mixer_pause(uint32_t player_id);
int rg35xx_mixer_stop(uint32_t player_id);
int rg35xx_mixer_seek(uint32_t player_id, uint64_t media_time_us);
int rg35xx_mixer_set_volume(uint32_t player_id, int level);
int rg35xx_mixer_set_loop_count(uint32_t player_id, int count);
void rg35xx_mixer_release(uint32_t player_id);

/* Mixes frames into interleaved signed stereo PCM16. Called by audio worker. */
size_t rg35xx_mixer_render(int16_t *out, size_t frames);

#endif
