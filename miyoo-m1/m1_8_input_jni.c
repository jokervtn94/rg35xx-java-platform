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
static int axis6=0, axis7=0;

/* Returns (action<<8)|control. action: 1 press, 0 release. -1 timeout, <-1 error.
   Physical mapping is frozen from M1.7/M1.3C. */
static int button_control(uint8_t n) {
    switch(n) { case 0:return 4; case 1:return 5; case 2:return 6; case 3:return 7;
        case 8:return 8; case 7:return 9; case 5:return 10; case 6:return 11; default:return -1; }
}
static int axis_control(uint8_t n, int v) {
    if(n==7) { if(v<0)return 0; if(v>0)return 1; }
    if(n==6) { if(v<0)return 2; if(v>0)return 3; }
    return -1;
}
JNIEXPORT jint JNICALL Java_org_recompile_mobile_M18DeviceDispatchProbe_openInput(JNIEnv *e,jclass c) {
    (void)e;(void)c; if(fd>=0)close(fd); axis6=axis7=0;
    fd=open("/dev/input/js0",O_RDONLY|O_NONBLOCK); return fd>=0?0:(100+errno);
}
JNIEXPORT jint JNICALL Java_org_recompile_mobile_M18DeviceDispatchProbe_nextTransition(JNIEnv *env,jclass cls,jint timeoutMs) {
    struct pollfd p; struct js_event e; int elapsed=0, pr, old, ctl; ssize_t n;
    (void)env;(void)cls; if(fd<0)return -2; p.fd=fd;p.events=POLLIN;
    while(elapsed<timeoutMs) {
        pr=poll(&p,1,100); elapsed+=100; if(pr<0){if(errno==EINTR)continue;return -3;} if(pr==0)continue;
        while((n=read(fd,&e,sizeof(e)))==(ssize_t)sizeof(e)) {
            if(e.type & JS_EVENT_INIT) continue;
            if((e.type & ~JS_EVENT_INIT)==JS_EVENT_BUTTON) {
                ctl=button_control(e.number); if(ctl>=0)return ((e.value?1:0)<<8)|ctl;
            } else if((e.type & ~JS_EVENT_INIT)==JS_EVENT_AXIS && (e.number==6 || e.number==7)) {
                old=(e.number==6)?axis6:axis7;
                if(e.value==0) { ctl=axis_control(e.number,old); if(e.number==6)axis6=0;else axis7=0; if(ctl>=0)return ctl; }
                else { if(e.number==6)axis6=e.value;else axis7=e.value; ctl=axis_control(e.number,e.value); if(ctl>=0)return (1<<8)|ctl; }
            }
        }
        if(n<0 && errno!=EAGAIN && errno!=EWOULDBLOCK)return -4;
    }
    return -1;
}
JNIEXPORT void JNICALL Java_org_recompile_mobile_M18DeviceDispatchProbe_closeInput(JNIEnv *e,jclass c) {(void)e;(void)c;if(fd>=0)close(fd);fd=-1;}
