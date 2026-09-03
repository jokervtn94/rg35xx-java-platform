#ifndef RG35XX_MIDI_BACKEND_H
#define RG35XX_MIDI_BACKEND_H

#include "rg35xx_media_cache.h"
#include "rg35xx_media_events.h"
#include <stdint.h>
#include <stddef.h>

/*
 * Adapter between Media Engine 2.0 and the RG35XX TML/TSF worker.
 * The implementation is intentionally bounded to two contexts on RG35XX.
 * Tasklog: RGJ-B3-006 / RGJ-RC1-010E / RGJ-RC1-010F.
 */
void rg35xx_midi_backend_init(rg35xx_media_event_cb event_cb);
void rg35xx_midi_backend_reset(void);
int rg35xx_midi_backend_play(struct rg35xx_media_entry *entry);
int rg35xx_midi_backend_pause(uint32_t player_id);
int rg35xx_midi_backend_stop(uint32_t player_id);
int rg35xx_midi_backend_seek(uint32_t player_id, uint64_t media_time_us);
void rg35xx_midi_backend_release(uint32_t player_id);
size_t rg35xx_midi_backend_mix(int32_t *accum, size_t frames);

#endif
