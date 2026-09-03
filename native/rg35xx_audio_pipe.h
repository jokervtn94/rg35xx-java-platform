#ifndef RG35XX_AUDIO_PIPE_H
#define RG35XX_AUDIO_PIPE_H

#include "rg35xx_audio_protocol.h"
#include <stdint.h>
#include <stddef.h>

struct rg35xx_audio_pipe {
    int read_fd;
    int write_fd;
    uint8_t header[RG35XX_AUDIO_HEADER_SIZE];
    size_t header_used;
    struct rg35xx_audio_header parsed;
    uint8_t *payload;
    size_t payload_used;
};

void rg35xx_audio_pipe_init(struct rg35xx_audio_pipe *p);
int rg35xx_audio_pipe_create(struct rg35xx_audio_pipe *p);
void rg35xx_audio_pipe_parent_after_fork(struct rg35xx_audio_pipe *p);
void rg35xx_audio_pipe_child_after_fork(struct rg35xx_audio_pipe *p);
int rg35xx_audio_pipe_child_fd(const struct rg35xx_audio_pipe *p);
int rg35xx_audio_pipe_drain(struct rg35xx_audio_pipe *p);
void rg35xx_audio_pipe_close(struct rg35xx_audio_pipe *p);

#endif
