#include <jni.h>
#include <fcntl.h>
#include <poll.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>

struct js_event { uint32_t time; int16_t value; uint8_t type; uint8_t number; } __attribute__((packed));
#define JS_EVENT_BUTTON 0x01
#define JS_EVENT_AXIS 0x02
#define JS_EVENT_INIT 0x80
static int fd=-1;

/* Locked M1.3C semantic map:
 UP axis7-, DOWN axis7+, LEFT axis6-, RIGHT axis6+,
 A/B/X/Y buttons0/1/2/3, START8, SELECT7, L5, R6. */
static int match_control(int c, const struct js_event *e) {
    uint8_t t=(uint8_t)(e->type & ~JS_EVENT_INIT);
    if(c==0) return t==JS_EVENT_AXIS && e->number==7 && e->value < -16000;
    if(c==1) return t==JS_EVENT_AXIS && e->number==7 && e->value > 16000;
    if(c==2) return t==JS_EVENT_AXIS && e->number==6 && e->value < -16000;
    if(c==3) return t==JS_EVENT_AXIS && e->number==6 && e->value > 16000;
    if(t!=JS_EVENT_BUTTON || e->value!=1) return 0;
    if(c==4) return e->number==0;
    if(c==5) return e->number==1;
    if(c==6) return e->number==2;
    if(c==7) return e->number==3;
    if(c==8) return e->number==8;
    if(c==9) return e->number==7;
    if(c==10) return e->number==5;
    if(c==11) return e->number==6;
    return 0;
}

JNIEXPORT jint JNICALL Java_M17InputProbe_openInput(JNIEnv *env,jclass cls) {
    (void)env;(void)cls;
    if(fd>=0) close(fd);
    fd=open("/dev/input/js0",O_RDONLY|O_NONBLOCK);
    return fd>=0 ? 0 : (100+errno);
}

JNIEXPORT jint JNICALL Java_M17InputProbe_waitControl(JNIEnv *env,jclass cls,jint control,jint timeoutMs) {
    struct pollfd p; struct js_event e; int elapsed=0, slice=100, pr; ssize_t n;
    (void)env;(void)cls;
    if(fd<0 || control<0 || control>11) return 2;
    p.fd=fd; p.events=POLLIN;
    while(elapsed<timeoutMs) {
        pr=poll(&p,1,slice); elapsed+=slice;
        if(pr<0) { if(errno==EINTR) continue; return 3; }
        if(pr==0) continue;
        while((n=read(fd,&e,sizeof(e)))==(ssize_t)sizeof(e)) if(match_control((int)control,&e)) return 0;
        if(n<0 && errno!=EAGAIN && errno!=EWOULDBLOCK) return 4;
    }
    return 1;
}

JNIEXPORT void JNICALL Java_M17InputProbe_closeInput(JNIEnv *env,jclass cls) {
    (void)env;(void)cls; if(fd>=0) close(fd); fd=-1;
}
