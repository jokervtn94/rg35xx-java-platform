#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/select.h>
#include <linux/joystick.h>

#define DEVICE_PATH "/dev/input/js0"
#define MAX_AXES 32
#define MAX_BUTTONS 64
#define STEP_TIMEOUT_MS 60000
#define RELEASE_TIMEOUT_MS 10000
#define SETTLE_US 350000

static long now_ms(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (long)(tv.tv_sec * 1000L + tv.tv_usec / 1000L);
}

static int read_event_timeout(int fd, struct js_event *ev, int timeout_ms) {
    fd_set rfds;
    struct timeval tv;
    int rc;
    FD_ZERO(&rfds);
    FD_SET(fd, &rfds);
    tv.tv_sec = timeout_ms / 1000;
    tv.tv_usec = (timeout_ms % 1000) * 1000;
    rc = select(fd + 1, &rfds, NULL, NULL, &tv);
    if (rc < 0) return -1;
    if (rc == 0) return 0;
    rc = (int)read(fd, ev, sizeof(*ev));
    if (rc == (int)sizeof(*ev)) return 1;
    return -1;
}

static int event_is_control(const struct js_event *ev) {
    unsigned char t = ev->type & ~JS_EVENT_INIT;
    return t == JS_EVENT_AXIS || t == JS_EVENT_BUTTON;
}

static int baseline_value(const struct js_event *ev, const int *axes, const int *buttons) {
    unsigned char t = ev->type & ~JS_EVENT_INIT;
    if (t == JS_EVENT_AXIS) {
        if (ev->number >= MAX_AXES) return 0;
        return axes[ev->number];
    }
    if (t == JS_EVENT_BUTTON) {
        if (ev->number >= MAX_BUTTONS) return 0;
        return buttons[ev->number];
    }
    return 0;
}

static int same_raw_control(unsigned char t1, unsigned char n1, unsigned char t2, unsigned char n2) {
    return t1 == t2 && n1 == n2;
}

int main(void) {
    static const char *names[] = {
        "UP", "DOWN", "LEFT", "RIGHT",
        "A", "B", "X", "Y",
        "START", "SELECT", "L", "R"
    };
    const int steps = (int)(sizeof(names) / sizeof(names[0]));
    int fd, i;
    int axes[MAX_AXES];
    int buttons[MAX_BUTTONS];
    unsigned char used_type[32];
    unsigned char used_number[32];
    int used_count = 0;
    struct js_event ev;

    memset(axes, 0, sizeof(axes));
    memset(buttons, 0, sizeof(buttons));
    memset(used_type, 0, sizeof(used_type));
    memset(used_number, 0, sizeof(used_number));

    printf("RG35XX MIYOO M1.3B EXACT KEYMAP PROBE\n");
    printf("PRIMARY_VARIABLE=RAW_JS0_SEMANTIC_KEYMAP_ONLY\n");
    printf("DEVICE=%s\n", DEVICE_PATH);
    printf("CONTROL_COUNT=%d\n", steps);
    printf("ORDER=UP,DOWN,LEFT,RIGHT,A,B,X,Y,START,SELECT,L,R\n");
    fflush(stdout);

    fd = open(DEVICE_PATH, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        printf("JS0_OPEN=FAIL errno=%d error=%s\n", errno, strerror(errno));
        printf("M1_3B_RESULT=FAIL_OPEN\n");
        return 10;
    }
    printf("JS0_OPEN=PASS\n");

    /* Drain initialization events and capture kernel-reported baseline values. */
    {
        long end = now_ms() + 1200;
        while (now_ms() < end) {
            int rc = read_event_timeout(fd, &ev, 50);
            if (rc < 0) {
                printf("INIT_READ=FAIL errno=%d error=%s\n", errno, strerror(errno));
                close(fd);
                return 11;
            }
            if (rc == 0) continue;
            if (!event_is_control(&ev)) continue;
            {
                unsigned char t = ev.type & ~JS_EVENT_INIT;
                if (t == JS_EVENT_AXIS && ev.number < MAX_AXES) axes[ev.number] = ev.value;
                if (t == JS_EVENT_BUTTON && ev.number < MAX_BUTTONS) buttons[ev.number] = ev.value;
                if (ev.type & JS_EVENT_INIT) {
                    printf("BASELINE type=%s index=%u value=%d\n",
                           t == JS_EVENT_AXIS ? "axis" : "button",
                           (unsigned)ev.number, (int)ev.value);
                }
            }
        }
    }

    printf("CALIBRATION_BEGIN=YES\n");
    fflush(stdout);

    for (i = 0; i < steps; ++i) {
        long deadline = now_ms() + STEP_TIMEOUT_MS;
        int got_press = 0;
        unsigned char press_type = 0;
        unsigned char press_number = 0;
        int press_value = 0;
        int base = 0;
        int j;

        printf("EXPECT=%s\n", names[i]);
        fflush(stdout);

        while (now_ms() < deadline && !got_press) {
            int rc = read_event_timeout(fd, &ev, 250);
            if (rc < 0) {
                printf("STEP=%s READ_FAIL errno=%d error=%s\n", names[i], errno, strerror(errno));
                close(fd);
                return 20;
            }
            if (rc == 0) continue;
            if (ev.type & JS_EVENT_INIT) continue;
            if (!event_is_control(&ev)) continue;

            {
                unsigned char t = ev.type & ~JS_EVENT_INIT;
                base = baseline_value(&ev, axes, buttons);
                if ((int)ev.value == base) continue;

                for (j = 0; j < used_count; ++j) {
                    if (same_raw_control(t, ev.number, used_type[j], used_number[j])) {
                        printf("STEP=%s DUPLICATE_RAW_CONTROL type=%s index=%u value=%d\n",
                               names[i], t == JS_EVENT_AXIS ? "axis" : "button",
                               (unsigned)ev.number, (int)ev.value);
                        printf("M1_3B_RESULT=FAIL_DUPLICATE_CONTROL\n");
                        close(fd);
                        return 21;
                    }
                }

                press_type = t;
                press_number = ev.number;
                press_value = ev.value;
                got_press = 1;
            }
        }

        if (!got_press) {
            printf("STEP=%s PRESS_TIMEOUT=YES\n", names[i]);
            printf("M1_3B_RESULT=FAIL_PRESS_TIMEOUT\n");
            close(fd);
            return 22;
        }

        {
            long release_deadline = now_ms() + RELEASE_TIMEOUT_MS;
            int got_release = 0;
            int release_value = press_value;
            while (now_ms() < release_deadline && !got_release) {
                int rc = read_event_timeout(fd, &ev, 250);
                if (rc < 0) {
                    printf("STEP=%s RELEASE_READ_FAIL errno=%d error=%s\n", names[i], errno, strerror(errno));
                    close(fd);
                    return 23;
                }
                if (rc == 0) continue;
                if (ev.type & JS_EVENT_INIT) continue;
                if (!event_is_control(&ev)) continue;
                {
                    unsigned char t = ev.type & ~JS_EVENT_INIT;
                    if (same_raw_control(t, ev.number, press_type, press_number) && (int)ev.value == base) {
                        release_value = ev.value;
                        got_release = 1;
                    }
                }
            }

            if (!got_release) {
                printf("STEP=%s RELEASE_TIMEOUT=YES type=%s index=%u press=%d baseline=%d\n",
                       names[i], press_type == JS_EVENT_AXIS ? "axis" : "button",
                       (unsigned)press_number, press_value, base);
                printf("M1_3B_RESULT=FAIL_RELEASE_TIMEOUT\n");
                close(fd);
                return 24;
            }

            printf("KEYMAP name=%s type=%s index=%u press=%d release=%d baseline=%d\n",
                   names[i], press_type == JS_EVENT_AXIS ? "axis" : "button",
                   (unsigned)press_number, press_value, release_value, base);
            fflush(stdout);
        }

        used_type[used_count] = press_type;
        used_number[used_count] = press_number;
        ++used_count;
        usleep(SETTLE_US);
    }

    printf("CALIBRATION_END=YES\n");
    printf("KEYMAP_COUNT=%d\n", used_count);
    printf("M1_3B_RESULT=PASS\n");
    close(fd);
    return 0;
}
