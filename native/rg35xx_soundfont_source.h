#ifndef RG35XX_SOUNDFONT_SOURCE_H
#define RG35XX_SOUNDFONT_SOURCE_H

#include <stddef.h>
#include <stdint.h>

/*
 * RC1 SoundFont source contract.
 *
 * This module does not own a filesystem path and does not bundle/guess an SF2.
 * The consolidated libretro core supplies validated SoundFont bytes from its
 * authoritative configuration/resource owner, then the media layer initializes
 * the TML/TSF worker from those bytes.
 *
 * Lifetime: bytes passed to rg35xx_soundfont_source_set() must remain valid until
 * rg35xx_soundfont_source_clear() or platform shutdown. The source object itself
 * performs no allocation or I/O.
 */
int rg35xx_soundfont_source_set(const uint8_t *data, size_t size);
void rg35xx_soundfont_source_clear(void);
int rg35xx_soundfont_source_ready(void);
const uint8_t *rg35xx_soundfont_source_data(void);
size_t rg35xx_soundfont_source_size(void);

#endif
