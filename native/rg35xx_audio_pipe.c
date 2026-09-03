#include "rg35xx_audio_protocol.h"
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* Implemented by rg35xx_audio_dispatch.c. */
int rg35xx_audio_dispatch(const struct rg35xx_audio_header *h,
                          const uint8_t *payload);

/* Tasklog: RGJ-B3-004. Parent owns read end; JamVM child inherits write end. */
struct rg35xx_audio_pipe {
    int read_fd;
    int write_fd;
    uint8_t header[RG35XX_AUDIO_HEADER_SIZE];
    size_t header_used;
    struct rg35xx_audio_header parsed;
    uint8_t *payload;
    size_t payload_used;
};

void rg35xx_audio_pipe_init(struct rg35xx_audio_pipe *p)
{
    if(!p) return;
    memset(p, 0, sizeof(*p));
    p->read_fd = -1;
    p->write_fd = -1;
}

int rg35xx_audio_pipe_create(struct rg35xx_audio_pipe *p)
{
    int fds[2];
    int flags;
    if(!p || pipe(fds) != 0) return 0;
    p->read_fd = fds[0];
    p->write_fd = fds[1];

    /* Parent drain must never block retro/audio worker shutdown. */
    flags = fcntl(p->read_fd, F_GETFL, 0);
    if(flags >= 0) fcntl(p->read_fd, F_SETFL, flags | O_NONBLOCK);

    /* Do not set CLOEXEC on write_fd: JamVM child must inherit it. */
    return 1;
}

void rg35xx_audio_pipe_parent_after_fork(struct rg35xx_audio_pipe *p)
{
    if(!p) return;
    if(p->write_fd >= 0) close(p->write_fd);
    p->write_fd = -1;
}

void rg35xx_audio_pipe_child_after_fork(struct rg35xx_audio_pipe *p)
{
    if(!p) return;
    if(p->read_fd >= 0) close(p->read_fd);
    p->read_fd = -1;
}

int rg35xx_audio_pipe_child_fd(const struct rg35xx_audio_pipe *p)
{
    return p ? p->write_fd : -1;
}

static void rg35xx_audio_pipe_reset_message(struct rg35xx_audio_pipe *p)
{
    if(p->payload) free(p->payload);
    p->payload = NULL;
    p->payload_used = 0;
    p->header_used = 0;
    memset(&p->parsed, 0, sizeof(p->parsed));
}

void rg35xx_audio_pipe_close(struct rg35xx_audio_pipe *p)
{
    if(!p) return;
    if(p->read_fd >= 0) close(p->read_fd);
    if(p->write_fd >= 0) close(p->write_fd);
    p->read_fd = p->write_fd = -1;
    rg35xx_audio_pipe_reset_message(p);
}

/*
 * Drain complete protocol messages. Partial header/payload state is retained
 * across calls, so the caller can invoke this from the existing audio worker.
 */
int rg35xx_audio_pipe_drain(struct rg35xx_audio_pipe *p)
{
    ssize_t n;
    int dispatched = 0;
    if(!p || p->read_fd < 0) return 0;

    for(;;)
    {
        if(p->header_used < RG35XX_AUDIO_HEADER_SIZE)
        {
            n = read(p->read_fd, p->header + p->header_used,
                     RG35XX_AUDIO_HEADER_SIZE - p->header_used);
            if(n > 0) { p->header_used += (size_t)n; continue; }
            if(n == 0) return dispatched;
            if(errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) return dispatched;
            return -1;
        }

        if(p->parsed.version == 0)
        {
            if(!rg35xx_audio_parse_header(p->header, RG35XX_AUDIO_HEADER_SIZE, &p->parsed))
            {
                rg35xx_audio_pipe_reset_message(p);
                return -1;
            }
            if(p->parsed.payload_size)
            {
                p->payload = (uint8_t *)malloc(p->parsed.payload_size);
                if(!p->payload) { rg35xx_audio_pipe_reset_message(p); return -1; }
            }
        }

        if(p->payload_used < p->parsed.payload_size)
        {
            n = read(p->read_fd, p->payload + p->payload_used,
                     p->parsed.payload_size - p->payload_used);
            if(n > 0) { p->payload_used += (size_t)n; continue; }
            if(n == 0) return dispatched;
            if(errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) return dispatched;
            return -1;
        }

        rg35xx_audio_dispatch(&p->parsed, p->payload);
        dispatched++;
        rg35xx_audio_pipe_reset_message(p);
    }
}
