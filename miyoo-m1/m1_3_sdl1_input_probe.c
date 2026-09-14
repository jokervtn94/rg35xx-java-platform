#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>
#include <sys/time.h>

typedef unsigned char Uint8;
typedef unsigned int Uint32;
typedef short Sint16;
typedef struct _SDL_Joystick SDL_Joystick;

#define SDL_INIT_JOYSTICK 0x00000200u
#define SDL_ENABLE 1
#define MAX_CONTROLS 64
#define MAX_CHANGE_LINES 256
#define SAMPLE_MS 15000
#define POLL_US 10000

typedef int (*PFN_SDL_Init)(Uint32 flags);
typedef void (*PFN_SDL_Quit)(void);
typedef const char *(*PFN_SDL_GetError)(void);
typedef int (*PFN_SDL_NumJoysticks)(void);
typedef const char *(*PFN_SDL_JoystickName)(int index);
typedef SDL_Joystick *(*PFN_SDL_JoystickOpen)(int index);
typedef int (*PFN_SDL_JoystickOpened)(int index);
typedef int (*PFN_SDL_JoystickIndex)(SDL_Joystick *joystick);
typedef int (*PFN_SDL_JoystickNumAxes)(SDL_Joystick *joystick);
typedef int (*PFN_SDL_JoystickNumBalls)(SDL_Joystick *joystick);
typedef int (*PFN_SDL_JoystickNumHats)(SDL_Joystick *joystick);
typedef int (*PFN_SDL_JoystickNumButtons)(SDL_Joystick *joystick);
typedef void (*PFN_SDL_JoystickUpdate)(void);
typedef Sint16 (*PFN_SDL_JoystickGetAxis)(SDL_Joystick *joystick, int axis);
typedef Uint8 (*PFN_SDL_JoystickGetHat)(SDL_Joystick *joystick, int hat);
typedef Uint8 (*PFN_SDL_JoystickGetButton)(SDL_Joystick *joystick, int button);
typedef int (*PFN_SDL_JoystickEventState)(int state);
typedef void (*PFN_SDL_JoystickClose)(SDL_Joystick *joystick);

static void *req(void *h, const char *name) {
    void *p = dlsym(h, name);
    if (!p) {
        fprintf(stderr, "M1.3 FAIL missing_symbol=%s dlerror=%s\n", name, dlerror());
        exit(20);
    }
    return p;
}

static long now_ms(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (long)(tv.tv_sec * 1000L + tv.tv_usec / 1000L);
}

static int clamp_count(int n) {
    if (n < 0) return 0;
    if (n > MAX_CONTROLS) return MAX_CONTROLS;
    return n;
}

int main(void) {
    const char *candidates[] = {
        "/usr/lib/libSDL-1.2.so.0",
        "/usr/lib/libSDL-1.2.so.0.11.4",
        "libSDL-1.2.so.0",
        NULL
    };
    void *h = NULL;
    int i, j, njoy;
    SDL_Joystick *joy;
    long start, elapsed;
    int changes = 0;

    printf("RG35XX MIYOO M1.3 SDL1 INPUT PROBE\n");
    printf("PRIMARY_VARIABLE=SDL1_JOYSTICK_INPUT_ONLY\n");
    printf("SAMPLE_WINDOW_MS=%d\n", SAMPLE_MS);
    printf("MAX_CHANGE_LINES=%d\n", MAX_CHANGE_LINES);

    for (i = 0; candidates[i]; ++i) {
        h = dlopen(candidates[i], RTLD_NOW | RTLD_LOCAL);
        if (h) {
            printf("SDL1_DLOPEN=PASS path=%s\n", candidates[i]);
            break;
        }
        printf("SDL1_DLOPEN_TRY=FAIL path=%s error=%s\n", candidates[i], dlerror());
    }
    if (!h) {
        printf("SDL1_DLOPEN=FAIL\n");
        return 10;
    }

    PFN_SDL_Init SDL_Init = (PFN_SDL_Init)req(h, "SDL_Init");
    PFN_SDL_Quit SDL_Quit = (PFN_SDL_Quit)req(h, "SDL_Quit");
    PFN_SDL_GetError SDL_GetError = (PFN_SDL_GetError)req(h, "SDL_GetError");
    PFN_SDL_NumJoysticks SDL_NumJoysticks = (PFN_SDL_NumJoysticks)req(h, "SDL_NumJoysticks");
    PFN_SDL_JoystickName SDL_JoystickName = (PFN_SDL_JoystickName)req(h, "SDL_JoystickName");
    PFN_SDL_JoystickOpen SDL_JoystickOpen = (PFN_SDL_JoystickOpen)req(h, "SDL_JoystickOpen");
    PFN_SDL_JoystickOpened SDL_JoystickOpened = (PFN_SDL_JoystickOpened)req(h, "SDL_JoystickOpened");
    PFN_SDL_JoystickIndex SDL_JoystickIndex = (PFN_SDL_JoystickIndex)req(h, "SDL_JoystickIndex");
    PFN_SDL_JoystickNumAxes SDL_JoystickNumAxes = (PFN_SDL_JoystickNumAxes)req(h, "SDL_JoystickNumAxes");
    PFN_SDL_JoystickNumBalls SDL_JoystickNumBalls = (PFN_SDL_JoystickNumBalls)req(h, "SDL_JoystickNumBalls");
    PFN_SDL_JoystickNumHats SDL_JoystickNumHats = (PFN_SDL_JoystickNumHats)req(h, "SDL_JoystickNumHats");
    PFN_SDL_JoystickNumButtons SDL_JoystickNumButtons = (PFN_SDL_JoystickNumButtons)req(h, "SDL_JoystickNumButtons");
    PFN_SDL_JoystickUpdate SDL_JoystickUpdate = (PFN_SDL_JoystickUpdate)req(h, "SDL_JoystickUpdate");
    PFN_SDL_JoystickGetAxis SDL_JoystickGetAxis = (PFN_SDL_JoystickGetAxis)req(h, "SDL_JoystickGetAxis");
    PFN_SDL_JoystickGetHat SDL_JoystickGetHat = (PFN_SDL_JoystickGetHat)req(h, "SDL_JoystickGetHat");
    PFN_SDL_JoystickGetButton SDL_JoystickGetButton = (PFN_SDL_JoystickGetButton)req(h, "SDL_JoystickGetButton");
    PFN_SDL_JoystickEventState SDL_JoystickEventState = (PFN_SDL_JoystickEventState)req(h, "SDL_JoystickEventState");
    PFN_SDL_JoystickClose SDL_JoystickClose = (PFN_SDL_JoystickClose)req(h, "SDL_JoystickClose");

    if (SDL_Init(SDL_INIT_JOYSTICK) != 0) {
        printf("SDL1_INIT_JOYSTICK=FAIL error=%s\n", SDL_GetError());
        dlclose(h);
        return 30;
    }
    printf("SDL1_INIT_JOYSTICK=PASS\n");

    njoy = SDL_NumJoysticks();
    printf("JOYSTICK_COUNT=%d\n", njoy);
    for (i = 0; i < njoy; ++i) {
        const char *name = SDL_JoystickName(i);
        printf("JOYSTICK_%d_NAME=%s\n", i, name ? name : "(null)");
    }
    if (njoy < 1) {
        printf("M1_3_RESULT=FAIL_NO_JOYSTICK\n");
        SDL_Quit();
        dlclose(h);
        return 31;
    }

    joy = SDL_JoystickOpen(0);
    if (!joy) {
        printf("JOYSTICK_OPEN=FAIL error=%s\n", SDL_GetError());
        SDL_Quit();
        dlclose(h);
        return 32;
    }
    printf("JOYSTICK_OPEN=PASS index=%d opened=%d\n", SDL_JoystickIndex(joy), SDL_JoystickOpened(0));

    int axes = clamp_count(SDL_JoystickNumAxes(joy));
    int buttons = clamp_count(SDL_JoystickNumButtons(joy));
    int hats = clamp_count(SDL_JoystickNumHats(joy));
    int balls = clamp_count(SDL_JoystickNumBalls(joy));
    printf("JOYSTICK_CAPS axes=%d buttons=%d hats=%d balls=%d\n", axes, buttons, hats, balls);

    Sint16 prev_axes[MAX_CONTROLS];
    Uint8 prev_buttons[MAX_CONTROLS];
    Uint8 prev_hats[MAX_CONTROLS];
    memset(prev_axes, 0, sizeof(prev_axes));
    memset(prev_buttons, 0, sizeof(prev_buttons));
    memset(prev_hats, 0, sizeof(prev_hats));

    SDL_JoystickEventState(SDL_ENABLE);
    SDL_JoystickUpdate();
    for (i = 0; i < axes; ++i) prev_axes[i] = SDL_JoystickGetAxis(joy, i);
    for (i = 0; i < buttons; ++i) prev_buttons[i] = SDL_JoystickGetButton(joy, i);
    for (i = 0; i < hats; ++i) prev_hats[i] = SDL_JoystickGetHat(joy, i);

    printf("INPUT_CAPTURE_BEGIN=YES\n");
    fflush(stdout);
    start = now_ms();
    while ((elapsed = now_ms() - start) < SAMPLE_MS && changes < MAX_CHANGE_LINES) {
        SDL_JoystickUpdate();
        for (j = 0; j < axes && changes < MAX_CHANGE_LINES; ++j) {
            Sint16 v = SDL_JoystickGetAxis(joy, j);
            if (v != prev_axes[j]) {
                printf("INPUT_CHANGE t_ms=%ld type=axis index=%d value=%d\n", elapsed, j, (int)v);
                prev_axes[j] = v;
                ++changes;
            }
        }
        for (j = 0; j < buttons && changes < MAX_CHANGE_LINES; ++j) {
            Uint8 v = SDL_JoystickGetButton(joy, j);
            if (v != prev_buttons[j]) {
                printf("INPUT_CHANGE t_ms=%ld type=button index=%d value=%u\n", elapsed, j, (unsigned)v);
                prev_buttons[j] = v;
                ++changes;
            }
        }
        for (j = 0; j < hats && changes < MAX_CHANGE_LINES; ++j) {
            Uint8 v = SDL_JoystickGetHat(joy, j);
            if (v != prev_hats[j]) {
                printf("INPUT_CHANGE t_ms=%ld type=hat index=%d value=%u\n", elapsed, j, (unsigned)v);
                prev_hats[j] = v;
                ++changes;
            }
        }
        usleep(POLL_US);
    }
    printf("INPUT_CAPTURE_END=YES\n");
    printf("INPUT_CHANGE_COUNT=%d\n", changes);

    SDL_JoystickClose(joy);
    SDL_Quit();
    dlclose(h);

    if (changes <= 0) {
        printf("M1_3_RESULT=FAIL_NO_INPUT_CHANGES\n");
        return 40;
    }

    printf("M1_3_RESULT=PASS\n");
    return 0;
}
