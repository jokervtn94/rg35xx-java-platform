#ifndef RG35XX_AUDIO_PROTOCOL_H
#define RG35XX_AUDIO_PROTOCOL_H

#include <stdint.h>
#include <stddef.h>

/* Tasklog: RGJ-B3-004 / RGJ-B3-005 */
#define RG35XX_AUDIO_MAGIC       UINT32_C(0x41354A52)
#define RG35XX_AUDIO_VERSION     1u
#define RG35XX_AUDIO_HEADER_SIZE 14u
#define RG35XX_AUDIO_MAX_PAYLOAD (4u * 1024u * 1024u)

enum rg35xx_audio_opcode {
    RG35XX_AUDIO_REGISTER_MIDI  = 1,
    RG35XX_AUDIO_REGISTER_PCM16 = 2,
    RG35XX_AUDIO_PLAY           = 3,
    RG35XX_AUDIO_PAUSE          = 4,
    RG35XX_AUDIO_STOP           = 5,
    RG35XX_AUDIO_SEEK_US        = 6,
    RG35XX_AUDIO_SET_VOLUME     = 7,
    RG35XX_AUDIO_SET_LOOP_COUNT = 8,
    RG35XX_AUDIO_RELEASE        = 9,
    RG35XX_AUDIO_RESET          = 10
};

struct rg35xx_audio_header {
    uint8_t version;
    uint8_t opcode;
    uint32_t player_id;
    uint32_t payload_size;
};

static uint32_t rg35xx_audio_u32le(const uint8_t *p)
{
    return ((uint32_t)p[0]) |
           ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) |
           ((uint32_t)p[3] << 24);
}

static int rg35xx_audio_parse_header(const uint8_t *buf, size_t len,
                                     struct rg35xx_audio_header *out)
{
    uint32_t magic;
    if(!buf || !out || len < RG35XX_AUDIO_HEADER_SIZE) return 0;
    magic = rg35xx_audio_u32le(buf);
    if(magic != RG35XX_AUDIO_MAGIC) return 0;
    if(buf[4] != RG35XX_AUDIO_VERSION) return 0;

    out->version = buf[4];
    out->opcode = buf[5];
    out->player_id = rg35xx_audio_u32le(buf + 6);
    out->payload_size = rg35xx_audio_u32le(buf + 10);
    if(out->payload_size > RG35XX_AUDIO_MAX_PAYLOAD) return 0;
    return 1;
}

#endif
