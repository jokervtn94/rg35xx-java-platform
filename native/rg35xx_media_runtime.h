#ifndef RG35XX_MEDIA_RUNTIME_H
#define RG35XX_MEDIA_RUNTIME_H

#include <stddef.h>
#include <stdint.h>

/*
 * RC1 consolidated native media lifecycle owner.
 *
 * The libretro core supplies authoritative SoundFont bytes. This coordinator
 * only orders the already-owned SoundFont source and TML/TSF worker; it does
 * not discover files, allocate an SF2, or own the mixer/audio pipe.
 */
int rg35xx_media_runtime_init(const uint8_t *soundfont, size_t size);
void rg35xx_media_runtime_shutdown(void);
int rg35xx_media_runtime_ready(void);

#endif
