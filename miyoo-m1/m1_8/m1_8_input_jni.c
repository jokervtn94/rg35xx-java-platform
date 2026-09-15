#include <jni.h>
#include <fcntl.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>

struct js_event { uint32_t time; int16_t value; uint8_t type; uint8_t number; } __attribute__((packed));
#define JS_EVENT_BUTTON 0x01
#define JS_EVENT_AXIS   0x02
#define JS_EVENT_INIT   0x80

/*
 * M1.8 runtime bridge.
 * Single raw owner: this translation unit alone owns /dev/input/js0 for the
 * production MIDP path. M1.7 probe source remains byte-for-byte untouched as
 * the DEVICE-PASS diagnostic baseline and is not linked into this path.
 *
 * Semantic bitmap contract matches M1InputDispatch IDs:
 * bit0 UP, bit1 DOWN, bit2 LEFT, bit3 RIGHT,
 * bit4 A, bit5 B, bit6 X, bit7 Y,
 * bit8 L1, bit9 R1, bit10 START, bit11 SELECT.
 */
static int js_fd = -1;
static uint32_t state_bits = 0;
static int16_t axis6 = 0;
static int16_t axis7 = 0;

static void set_bit(unsigned bit, int down) {
    const uint32_t mask = (uint32_t)1u << bit;
    if (down) state_bits |= mask;
    else state_bits &= ~mask;
}

static void update_axis_bits(void) {
    set_bit(0, axis7 < -16000); /* UP */
    set_bit(1, axis7 >  16000); /* DOWN */
    set_bit(2, axis6 < -16000); /* LEFT */
    set_bit(3, axis6 >  16000); /* RIGHT */
}

static void apply_event(const struct js_event *e) {
    const uint8_t type = (uint8_t)(e->type & ~JS_EVENT_INIT);
    if (type == JS_EVENT_AXIS) {
        if (e->number == 6) axis6 = e->value;
        else if (e->number == 7) axis7 = e->value;
        else return;
        update_axis_bits();
        return;
    }
    if (type != JS_EVENT_BUTTON) return;

    const int down = e->value != 0;
    switch (e->number) {
        case 0: set_bit(4, down); break;  /* A */
        case 1: set_bit(5, down); break;  /* B */
        case 2: set_bit(6, down); break;  /* X */
        case 3: set_bit(7, down); break;  /* Y */
        case 5: set_bit(8, down); break;  /* L1 */
        case 6: set_bit(9, down); break;  /* R1 */
        case 8: set_bit(10, down); break; /* START */
        case 7: set_bit(11, down); break; /* SELECT */
        default: break;
    }
}

static int ensure_open(void) {
    if (js_fd >= 0) return 0;
    js_fd = open("/dev/input/js0", O_RDONLY | O_NONBLOCK);
    if (js_fd < 0) return -errno;
    state_bits = 0;
    axis6 = axis7 = 0;
    return 0;
}

JNIEXPORT jint JNICALL Java_org_recompile_mobile_M1Input_rawGetState(JNIEnv *env, jclass cls) {
    struct js_event e;
    ssize_t n;
    (void)env; (void)cls;

    if (ensure_open() != 0) return 0;

    while ((n = read(js_fd, &e, sizeof(e))) == (ssize_t)sizeof(e)) {
        apply_event(&e);
    }
    if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
        close(js_fd);
        js_fd = -1;
        state_bits = 0;
        axis6 = axis7 = 0;
    }
    return (jint)state_bits;
}
