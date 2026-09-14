#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/time.h>

#define JS_EVENT_BUTTON 0x01
#define JS_EVENT_AXIS   0x02
#define JS_EVENT_INIT   0x80
#define SAMPLE_MS 20000
#define MAX_EVENTS 256
#define POLL_US 5000

struct js_event {
    uint32_t time;
    int16_t value;
    uint8_t type;
    uint8_t number;
};

static long now_ms(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (long)(tv.tv_sec * 1000L + tv.tv_usec / 1000L);
}

int main(void) {
    const char *path = "/dev/input/js0";
    int fd, count = 0;
    long start, elapsed;
    struct js_event e;

    printf("RG35XX MIYOO M1.3A RAW JS0 INPUT PROBE\n");
    printf("PRIMARY_VARIABLE=RAW_LINUX_JS0_INPUT_ONLY\n");
    printf("DEVICE=%s\n", path);
    printf("SAMPLE_WINDOW_MS=%d\n", SAMPLE_MS);
    printf("MAX_EVENTS=%d\n", MAX_EVENTS);

    fd = open(path, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        printf("JS0_OPEN=FAIL errno=%d error=%s\n", errno, strerror(errno));
        return 30;
    }
    printf("JS0_OPEN=PASS\n");
    printf("INPUT_CAPTURE_BEGIN=YES\n");
    fflush(stdout);

    start = now_ms();
    while ((elapsed = now_ms() - start) < SAMPLE_MS && count < MAX_EVENTS) {
        ssize_t n = read(fd, &e, sizeof(e));
        if (n == (ssize_t)sizeof(e)) {
            unsigned type = (unsigned)e.type;
            unsigned base = type & ~JS_EVENT_INIT;
            if (base == JS_EVENT_AXIS || base == JS_EVENT_BUTTON) {
                printf("RAW_INPUT t_ms=%ld kernel_ms=%u type=%s index=%u value=%d init=%u\n",
                       elapsed,
                       (unsigned)e.time,
                       base == JS_EVENT_AXIS ? "axis" : "button",
                       (unsigned)e.number,
                       (int)e.value,
                       (type & JS_EVENT_INIT) ? 1u : 0u);
                ++count;
                fflush(stdout);
            }
        } else if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
            printf("JS0_READ=FAIL errno=%d error=%s\n", errno, strerror(errno));
            close(fd);
            return 31;
        }
        usleep(POLL_US);
    }

    printf("INPUT_CAPTURE_END=YES\n");
    printf("RAW_EVENT_COUNT=%d\n", count);
    close(fd);

    if (count <= 0) {
        printf("M1_3A_RESULT=FAIL_NO_RAW_EVENTS\n");
        return 40;
    }
    printf("M1_3A_RESULT=PASS\n");
    return 0;
}
