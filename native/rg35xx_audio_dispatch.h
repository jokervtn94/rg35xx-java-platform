#ifndef RG35XX_AUDIO_DISPATCH_H
#define RG35XX_AUDIO_DISPATCH_H

#include "rg35xx_audio_protocol.h"
#include <stdint.h>

/*
 * Single declaration owner for the Java->native audio command dispatcher.
 * Implementation remains in rg35xx_audio_dispatch.c.
 * Tasklog: RGJ-RC1-010G.
 */
int rg35xx_audio_dispatch(const struct rg35xx_audio_header *h,
                          const uint8_t *payload);

#endif
