#ifndef RG35XX_GOLDEN_VIDEO_H
#define RG35XX_GOLDEN_VIDEO_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RG35XX_GOLDEN_MAX_WIDTH   800u
#define RG35XX_GOLDEN_MAX_HEIGHT  800u
#define RG35XX_GOLDEN_MAX_PIXELS  (RG35XX_GOLDEN_MAX_WIDTH * RG35XX_GOLDEN_MAX_HEIGHT)
#define RG35XX_GOLDEN_HEADER_SIZE 16u

struct rg35xx_golden_frame
{
    uint16_t pixels[RG35XX_GOLDEN_MAX_PIXELS];
    unsigned width;
    unsigned height;
    unsigned rotation;
    uint32_t vibration_duration;
    uint32_t vibration_strength;
    uint8_t restart_requested;
    uint8_t encoding_requested;
    unsigned long generation;
};

typedef void (*rg35xx_golden_video_cb)(const void *data,
                                        unsigned width,
                                        unsigned height,
                                        size_t pitch);

typedef void (*rg35xx_golden_geometry_cb)(unsigned width, unsigned height);

/* The read fd is Java stdout -> native. The write fd is native -> Java stdin. */
int rg35xx_golden_video_init(int read_fd, int write_fd,
                             unsigned output_width, unsigned output_height);
int rg35xx_golden_video_start(void);
void rg35xx_golden_video_stop(void);
void rg35xx_golden_video_deinit(void);

/* Nonblocking from the frontend perspective: copies/presents only the latest
 * fully validated generation published by the receiver thread. */
int rg35xx_golden_video_present(rg35xx_golden_video_cb video_cb,
                                rg35xx_golden_geometry_cb geometry_cb);

unsigned long rg35xx_golden_video_generation(void);
unsigned long rg35xx_golden_video_presented_generation(void);

#ifdef __cplusplus
}
#endif

#endif
