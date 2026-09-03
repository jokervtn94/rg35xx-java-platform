#ifndef RG35XX_TSF_WORKER_H
#define RG35XX_TSF_WORKER_H

#include <stddef.h>
#include <stdint.h>

/*
 * Replacement declaration contract for the historical RG35XX TML/TSF worker.
 * Implementation is authorized by RGJ-RC1-010F but remains dependency-gated.
 *
 * SoundFont ownership is explicit: the consolidated native core supplies the
 * exact SF2 bytes once. No guessed filesystem path is owned by this module.
 */
int rg35xx_tsf_worker_init(const uint8_t *soundfont, size_t size);
void rg35xx_tsf_worker_shutdown(void);
int rg35xx_tsf_worker_ready(void);

/* Existing MIDI-adapter hook contract. Return nonzero on success. */
int rg35xx_tsf_open_memory(int slot, const uint8_t *midi, size_t size);
int rg35xx_tsf_start(int slot, int volume, int loop_count, uint64_t media_time_us);
int rg35xx_tsf_pause(int slot);
int rg35xx_tsf_stop(int slot);
int rg35xx_tsf_seek(int slot, uint64_t media_time_us);
void rg35xx_tsf_close(int slot);
size_t rg35xx_tsf_mix_slot(int slot, int32_t *accum, size_t frames);
int rg35xx_tsf_slot_finished(int slot);
uint64_t rg35xx_tsf_slot_time_us(int slot);

/*
 * Returns nonzero exactly once for each actual intermediate timeline restart.
 * The adapter/event bridge may consume this to emit RC1 EVENT_LOOPED without
 * taking ownership of loop counting itself.
 */
int rg35xx_tsf_take_looped(int slot);

#endif
