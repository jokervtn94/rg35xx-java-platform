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
 * RG35XX P2C raw-input adapter.
 * Existing 12-control mapping remains unchanged. Original-RG35XX measured
 * evidence adds L2 on axis 2 and R2 on axis 5, each baseline -32767 and
 * pressed +32767. This translation unit remains the sole /dev/input/js0 owner.
 */
static int js_fd = -1;
static uint32_t state_bits = 0;
static int16_t axis2 = -32767;
static int16_t axis5 = -32767;
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
    set_bit(12, axis2 > 16000); /* L2: measured baseline -32767, press +32767 */
    set_bit(13, axis5 > 16000); /* R2: measured baseline -32767, press +32767 */
}

static void apply_event(const struct js_event *e) {
    const uint8_t type = (uint8_t)(e->type & ~JS_EVENT_INIT);
    if (type == JS_EVENT_AXIS) {
        if (e->number == 2) axis2 = e->value;
        else if (e->number == 5) axis5 = e->value;
        else if (e->number == 6) axis6 = e->value;
        else if (e->number == 7) axis7 = e->value;
        else return;
        update_axis_bits();
        return;
    }
    if (type != JS_EVENT_BUTTON) return;

    {
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
}

static int ensure_open(void) {
    if (js_fd >= 0) return 0;
    js_fd = open("/dev/input/js0", O_RDONLY | O_NONBLOCK);
    if (js_fd < 0) return -errno;
    state_bits = 0;
    axis2 = -32767;
    axis5 = -32767;
    axis6 = 0;
    axis7 = 0;
    update_axis_bits();
    return 0;
}

JNIEXPORT jint JNICALL Java_org_recompile_rg35xx_RG35XXInput_rawGetState(JNIEnv *env, jclass cls) {
    struct js_event e;
    ssize_t n = 0;
    (void)env;
    (void)cls;

    if (ensure_open() != 0) return 0;

    while ((n = read(js_fd, &e, sizeof(e))) == (ssize_t)sizeof(e)) {
        apply_event(&e);
    }
    if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
        close(js_fd);
        js_fd = -1;
        state_bits = 0;
        axis2 = axis5 = -32767;
        axis6 = axis7 = 0;
    }
    return (jint)state_bits;
}
