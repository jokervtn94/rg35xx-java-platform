#include "rg35xx_golden_video.h"

#include <errno.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct rg35xx_golden_state
{
    int read_fd;
    int write_fd;
    unsigned output_width;
    unsigned output_height;

    pthread_t thread;
    pthread_mutex_t mutex;
    int mutex_ready;
    volatile int run;
    int started;

    struct rg35xx_golden_frame a;
    struct rg35xx_golden_frame b;
    struct rg35xx_golden_frame snapshot;
    struct rg35xx_golden_frame *front;
    struct rg35xx_golden_frame *back;
    unsigned long generation;
    unsigned long presented_generation;

    unsigned char wire_payload[RG35XX_GOLDEN_MAX_PIXELS * 2u];
    uint16_t canvas[RG35XX_GOLDEN_MAX_PIXELS];

    unsigned cached_src_w;
    unsigned cached_src_h;
    unsigned cached_dst_w;
    unsigned cached_dst_h;
    unsigned cached_x;
    unsigned cached_y;
};

static struct rg35xx_golden_state g;

static int read_exact(int fd, void *dst, size_t bytes)
{
    unsigned char *p = (unsigned char *)dst;
    size_t used = 0;
    while(used < bytes)
    {
        ssize_t n = read(fd, p + used, bytes - used);
        if(n > 0)
        {
            used += (size_t)n;
            continue;
        }
        if(n == 0) return 0;
        if(errno == EINTR) continue;
        return -1;
    }
    return 1;
}

static int write_exact(int fd, const void *src, size_t bytes)
{
    const unsigned char *p = (const unsigned char *)src;
    size_t used = 0;
    while(used < bytes)
    {
        ssize_t n = write(fd, p + used, bytes - used);
        if(n > 0)
        {
            used += (size_t)n;
            continue;
        }
        if(n < 0 && errno == EINTR) continue;
        return 0;
    }
    return 1;
}

static uint32_t be32(const unsigned char *p)
{
    return ((uint32_t)p[0] << 24) |
           ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) |
           (uint32_t)p[3];
}

static int valid_header(const unsigned char h[RG35XX_GOLDEN_HEADER_SIZE],
                        unsigned *w, unsigned *hh, unsigned *rotation)
{
    unsigned width;
    unsigned height;
    unsigned rot;
    if(h[0] != 0xFE) return 0;
    width = ((unsigned)h[1] << 8) | h[2];
    height = ((unsigned)h[3] << 8) | h[4];
    rot = h[5];
    if(width == 0 || height == 0) return 0;
    if(width > RG35XX_GOLDEN_MAX_WIDTH || height > RG35XX_GOLDEN_MAX_HEIGHT) return 0;
    if(width > RG35XX_GOLDEN_MAX_PIXELS / height) return 0;
    if(rot > 3u) return 0;
    *w = width;
    *hh = height;
    *rotation = rot;
    return 1;
}

static int read_header_resync(unsigned char h[RG35XX_GOLDEN_HEADER_SIZE],
                              unsigned *w, unsigned *hh, unsigned *rotation)
{
    unsigned char byte;
    unsigned scanned = 0;
    const unsigned max_scan = RG35XX_GOLDEN_MAX_PIXELS * 2u + RG35XX_GOLDEN_HEADER_SIZE;

    while(g.run && scanned < max_scan)
    {
        if(read_exact(g.read_fd, &byte, 1u) <= 0) return 0;
        ++scanned;
        if(byte != 0xFE) continue;
        h[0] = byte;
        if(read_exact(g.read_fd, h + 1, RG35XX_GOLDEN_HEADER_SIZE - 1u) <= 0) return 0;
        scanned += RG35XX_GOLDEN_HEADER_SIZE - 1u;
        if(valid_header(h, w, hh, rotation)) return 1;
    }
    return 0;
}

static void decode_wire_rgb565(struct rg35xx_golden_frame *dst,
                               const unsigned char *src, size_t pixels)
{
    size_t i;
    for(i = 0; i < pixels; ++i)
        dst->pixels[i] = (uint16_t)(((uint16_t)src[i * 2u] << 8) |
                                   (uint16_t)src[i * 2u + 1u]);
}

static void publish_back(unsigned w, unsigned h, unsigned rot,
                         const unsigned char header[RG35XX_GOLDEN_HEADER_SIZE])
{
    struct rg35xx_golden_frame *tmp;
    g.back->width = w;
    g.back->height = h;
    g.back->rotation = rot;
    g.back->vibration_duration = be32(header + 6);
    g.back->vibration_strength = be32(header + 10);
    g.back->restart_requested = header[14];
    g.back->encoding_requested = header[15];

    pthread_mutex_lock(&g.mutex);
    ++g.generation;
    g.back->generation = g.generation;
    tmp = g.front;
    g.front = g.back;
    g.back = tmp;
    pthread_mutex_unlock(&g.mutex);
}

static void *receiver_main(void *unused)
{
    static const unsigned char request[5] = { 0x0F, 0, 0, 0, 0 };
    unsigned char header[RG35XX_GOLDEN_HEADER_SIZE];
    (void)unused;

    while(g.run)
    {
        unsigned w, h, rotation;
        size_t pixels;
        size_t payload;

        if(!write_exact(g.write_fd, request, sizeof(request))) break;
        if(!read_header_resync(header, &w, &h, &rotation)) break;

        pixels = (size_t)w * (size_t)h;
        payload = pixels * 2u;
        if(read_exact(g.read_fd, g.wire_payload, payload) <= 0) break;

        decode_wire_rgb565(g.back, g.wire_payload, pixels);
        publish_back(w, h, rotation, header);
    }

    g.run = 0;
    return NULL;
}

static void fit_geometry(unsigned sw, unsigned sh,
                         unsigned *dw, unsigned *dh,
                         unsigned *x, unsigned *y)
{
    unsigned ow = g.output_width;
    unsigned oh = g.output_height;
    unsigned fw, fh;

    if(sw == 0 || sh == 0 || ow == 0 || oh == 0)
    {
        *dw = *dh = *x = *y = 0;
        return;
    }

    fw = ow;
    fh = (unsigned)(((unsigned long long)sh * ow) / sw);
    if(fh > oh)
    {
        fh = oh;
        fw = (unsigned)(((unsigned long long)sw * oh) / sh);
    }
    if(fw == 0) fw = 1;
    if(fh == 0) fh = 1;
    *dw = fw;
    *dh = fh;
    *x = (ow - fw) / 2u;
    *y = (oh - fh) / 2u;
}

static void blit_nearest(const struct rg35xx_golden_frame *src)
{
    unsigned dw, dh, ox, oy;
    unsigned x, y;
    const unsigned ow = g.output_width;
    const unsigned oh = g.output_height;

    if(src->width != g.cached_src_w || src->height != g.cached_src_h)
    {
        fit_geometry(src->width, src->height, &dw, &dh, &ox, &oy);
        g.cached_src_w = src->width;
        g.cached_src_h = src->height;
        g.cached_dst_w = dw;
        g.cached_dst_h = dh;
        g.cached_x = ox;
        g.cached_y = oy;
    }
    else
    {
        dw = g.cached_dst_w;
        dh = g.cached_dst_h;
        ox = g.cached_x;
        oy = g.cached_y;
    }

    memset(g.canvas, 0, (size_t)ow * oh * sizeof(uint16_t));
    for(y = 0; y < dh; ++y)
    {
        unsigned sy = (unsigned)(((unsigned long long)y * src->height) / dh);
        uint16_t *row = g.canvas + (size_t)(oy + y) * ow + ox;
        const uint16_t *srow = src->pixels + (size_t)sy * src->width;
        for(x = 0; x < dw; ++x)
        {
            unsigned sx = (unsigned)(((unsigned long long)x * src->width) / dw);
            row[x] = srow[sx];
        }
    }
}

int rg35xx_golden_video_init(int read_fd, int write_fd,
                             unsigned output_width, unsigned output_height)
{
    if(read_fd < 0 || write_fd < 0) return 0;
    if(output_width == 0 || output_height == 0) return 0;
    if(output_width > RG35XX_GOLDEN_MAX_WIDTH || output_height > RG35XX_GOLDEN_MAX_HEIGHT) return 0;

    memset(&g, 0, sizeof(g));
    g.read_fd = read_fd;
    g.write_fd = write_fd;
    g.output_width = output_width;
    g.output_height = output_height;
    g.front = &g.a;
    g.back = &g.b;
    if(pthread_mutex_init(&g.mutex, NULL) != 0) return 0;
    g.mutex_ready = 1;
    return 1;
}

int rg35xx_golden_video_start(void)
{
    if(!g.mutex_ready || g.started) return g.started != 0;
    g.run = 1;
    if(pthread_create(&g.thread, NULL, receiver_main, NULL) != 0)
    {
        g.run = 0;
        return 0;
    }
    g.started = 1;
    return 1;
}

void rg35xx_golden_video_stop(void)
{
    if(!g.started) return;
    g.run = 0;
    pthread_cancel(g.thread);
    pthread_join(g.thread, NULL);
    g.started = 0;
}

void rg35xx_golden_video_deinit(void)
{
    rg35xx_golden_video_stop();
    if(g.mutex_ready)
    {
        pthread_mutex_destroy(&g.mutex);
        g.mutex_ready = 0;
    }
}

int rg35xx_golden_video_present(rg35xx_golden_video_cb video_cb,
                                rg35xx_golden_geometry_cb geometry_cb)
{
    size_t bytes;
    unsigned long generation;
    if(!video_cb || !g.mutex_ready) return 0;

    pthread_mutex_lock(&g.mutex);
    generation = g.front->generation;
    if(generation == 0)
    {
        pthread_mutex_unlock(&g.mutex);
        return 0;
    }
    g.snapshot.width = g.front->width;
    g.snapshot.height = g.front->height;
    g.snapshot.rotation = g.front->rotation;
    g.snapshot.vibration_duration = g.front->vibration_duration;
    g.snapshot.vibration_strength = g.front->vibration_strength;
    g.snapshot.restart_requested = g.front->restart_requested;
    g.snapshot.encoding_requested = g.front->encoding_requested;
    g.snapshot.generation = generation;
    bytes = (size_t)g.snapshot.width * g.snapshot.height * sizeof(uint16_t);
    memcpy(g.snapshot.pixels, g.front->pixels, bytes);
    pthread_mutex_unlock(&g.mutex);

    if(g.snapshot.rotation == 0)
        blit_nearest(&g.snapshot);
    else
        return 0;

    if(geometry_cb) geometry_cb(g.output_width, g.output_height);
    video_cb(g.canvas, g.output_width, g.output_height,
             (size_t)g.output_width * sizeof(uint16_t));
    g.presented_generation = generation;
    return 1;
}

int rg35xx_golden_video_source_geometry(unsigned *width, unsigned *height,
                                        unsigned *rotation)
{
    int ok = 0;
    if(!g.mutex_ready || !width || !height || !rotation) return 0;
    pthread_mutex_lock(&g.mutex);
    if(g.front->generation != 0)
    {
        *width = g.front->width;
        *height = g.front->height;
        *rotation = g.front->rotation;
        ok = 1;
    }
    pthread_mutex_unlock(&g.mutex);
    return ok;
}

unsigned long rg35xx_golden_video_generation(void)
{
    return g.generation;
}

unsigned long rg35xx_golden_video_presented_generation(void)
{
    return g.presented_generation;
}
