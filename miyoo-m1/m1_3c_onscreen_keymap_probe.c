#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <dlfcn.h>
#include <sys/time.h>
#include <sys/select.h>
#include <linux/joystick.h>

typedef unsigned char Uint8;
typedef unsigned short Uint16;
typedef unsigned int Uint32;
typedef struct SDL_PixelFormat SDL_PixelFormat;
typedef struct SDL_Rect { short x, y; unsigned short w, h; } SDL_Rect;
typedef struct SDL_Surface {
    Uint32 flags; SDL_PixelFormat *format; int w, h; Uint16 pitch; void *pixels;
    int offset; void *hwdata; SDL_Rect clip_rect; Uint32 unused1; Uint32 locked;
    void *map; unsigned int format_version; int refcount;
} SDL_Surface;

typedef int (*PFN_SDL_Init)(Uint32);
typedef void (*PFN_SDL_Quit)(void);
typedef const char *(*PFN_SDL_GetError)(void);
typedef char *(*PFN_SDL_VideoDriverName)(char *, int);
typedef SDL_Surface *(*PFN_SDL_SetVideoMode)(int,int,int,Uint32);
typedef Uint32 (*PFN_SDL_MapRGB)(SDL_PixelFormat *,Uint8,Uint8,Uint8);
typedef int (*PFN_SDL_FillRect)(SDL_Surface *,SDL_Rect *,Uint32);
typedef int (*PFN_SDL_Flip)(SDL_Surface *);
typedef void (*PFN_SDL_Delay)(Uint32);

#define SDL_INIT_VIDEO 0x00000020u
#define SDL_SWSURFACE  0x00000000u
#define SDL_FULLSCREEN 0x80000000u
#define DEVICE_PATH "/dev/input/js0"
#define MAX_AXES 32
#define MAX_BUTTONS 64
#define STEP_TIMEOUT_MS 60000
#define RELEASE_TIMEOUT_MS 10000
#define STALE_DRAIN_MS 250

static PFN_SDL_FillRect pFill;
static PFN_SDL_Flip pFlip;
static PFN_SDL_MapRGB pMap;
static SDL_Surface *screen;

static long now_ms(void) {
    struct timeval tv; gettimeofday(&tv, NULL);
    return (long)(tv.tv_sec * 1000L + tv.tv_usec / 1000L);
}

static int read_event_timeout(int fd, struct js_event *ev, int timeout_ms) {
    fd_set rfds; struct timeval tv; int rc;
    FD_ZERO(&rfds); FD_SET(fd, &rfds);
    tv.tv_sec = timeout_ms / 1000; tv.tv_usec = (timeout_ms % 1000) * 1000;
    rc = select(fd + 1, &rfds, NULL, NULL, &tv);
    if (rc < 0) return -1;
    if (rc == 0) return 0;
    rc = (int)read(fd, ev, sizeof(*ev));
    return rc == (int)sizeof(*ev) ? 1 : -1;
}

static int is_control(const struct js_event *ev) {
    unsigned char t = ev->type & ~JS_EVENT_INIT;
    return t == JS_EVENT_AXIS || t == JS_EVENT_BUTTON;
}

static void *need(void *h, const char *name) {
    void *p = dlsym(h, name);
    if (!p) { fprintf(stderr, "M1.3C FAIL missing_symbol=%s error=%s\n", name, dlerror()); exit(20); }
    return p;
}

/* 5x7 uppercase glyphs, one 5-bit row per byte. */
static const unsigned char *glyph(char c) {
    static unsigned char g[7];
    memset(g,0,sizeof(g));
    switch (c) {
    case 'A': { unsigned char x[7]={14,17,17,31,17,17,17}; memcpy(g,x,7); break; }
    case 'B': { unsigned char x[7]={30,17,17,30,17,17,30}; memcpy(g,x,7); break; }
    case 'C': { unsigned char x[7]={14,17,16,16,16,17,14}; memcpy(g,x,7); break; }
    case 'D': { unsigned char x[7]={30,17,17,17,17,17,30}; memcpy(g,x,7); break; }
    case 'E': { unsigned char x[7]={31,16,16,30,16,16,31}; memcpy(g,x,7); break; }
    case 'F': { unsigned char x[7]={31,16,16,30,16,16,16}; memcpy(g,x,7); break; }
    case 'G': { unsigned char x[7]={14,17,16,23,17,17,15}; memcpy(g,x,7); break; }
    case 'H': { unsigned char x[7]={17,17,17,31,17,17,17}; memcpy(g,x,7); break; }
    case 'I': { unsigned char x[7]={31,4,4,4,4,4,31}; memcpy(g,x,7); break; }
    case 'L': { unsigned char x[7]={16,16,16,16,16,16,31}; memcpy(g,x,7); break; }
    case 'M': { unsigned char x[7]={17,27,21,21,17,17,17}; memcpy(g,x,7); break; }
    case 'N': { unsigned char x[7]={17,25,21,19,17,17,17}; memcpy(g,x,7); break; }
    case 'O': { unsigned char x[7]={14,17,17,17,17,17,14}; memcpy(g,x,7); break; }
    case 'P': { unsigned char x[7]={30,17,17,30,16,16,16}; memcpy(g,x,7); break; }
    case 'R': { unsigned char x[7]={30,17,17,30,20,18,17}; memcpy(g,x,7); break; }
    case 'S': { unsigned char x[7]={15,16,16,14,1,1,30}; memcpy(g,x,7); break; }
    case 'T': { unsigned char x[7]={31,4,4,4,4,4,4}; memcpy(g,x,7); break; }
    case 'U': { unsigned char x[7]={17,17,17,17,17,17,14}; memcpy(g,x,7); break; }
    case 'W': { unsigned char x[7]={17,17,17,21,21,21,10}; memcpy(g,x,7); break; }
    case 'X': { unsigned char x[7]={17,17,10,4,10,17,17}; memcpy(g,x,7); break; }
    case 'Y': { unsigned char x[7]={17,17,10,4,4,4,4}; memcpy(g,x,7); break; }
    default: break;
    }
    return g;
}

static void clear_screen(Uint8 r, Uint8 g, Uint8 b) {
    Uint32 px = pMap(screen->format,r,g,b); pFill(screen,NULL,px);
}

static void draw_text_center(const char *s, int y, int scale, Uint8 r, Uint8 g, Uint8 b) {
    int len=(int)strlen(s), cw=6*scale, total=len*cw, x=(screen->w-total)/2, i,row,col;
    Uint32 px=pMap(screen->format,r,g,b);
    for(i=0;i<len;++i) {
        if(s[i]==' ') { x+=cw; continue; }
        const unsigned char *gr=glyph(s[i]);
        for(row=0;row<7;++row) for(col=0;col<5;++col) if(gr[row]&(1<<(4-col))) {
            SDL_Rect rc; rc.x=(short)(x+col*scale); rc.y=(short)(y+row*scale);
            rc.w=(unsigned short)scale; rc.h=(unsigned short)scale; pFill(screen,&rc,px);
        }
        x+=cw;
    }
}

static void show_prompt(const char *name) {
    clear_screen(0,0,0);
    draw_text_center("PRESS",120,10,255,255,255);
    draw_text_center(name,240,12,255,255,255);
    pFlip(screen);
}

static void show_confirmed(void) {
    clear_screen(0,0,0);
    draw_text_center("CONFIRMED",190,8,255,255,255);
    pFlip(screen);
}

static void show_done(void) {
    clear_screen(0,0,0);
    draw_text_center("DONE",180,14,255,255,255);
    pFlip(screen);
}

static int baseline_for(unsigned char t, unsigned char n, const int *axes, const int *buttons,
                        const unsigned char *axis_valid, const unsigned char *button_valid, int *ok) {
    if(t==JS_EVENT_AXIS && n<MAX_AXES && axis_valid[n]) { *ok=1; return axes[n]; }
    if(t==JS_EVENT_BUTTON && n<MAX_BUTTONS && button_valid[n]) { *ok=1; return buttons[n]; }
    *ok=0; return 0;
}

static int direction_from(int value, int base) { return value>base ? 1 : (value<base ? -1 : 0); }

int main(void) {
    static const char *names[]={"UP","DOWN","LEFT","RIGHT","A","B","X","Y","START","SELECT","L","R"};
    const int steps=12;
    const char *libs[]={"/usr/lib/libSDL-1.2.so.0","/usr/lib/libSDL-1.2.so.0.11.4","libSDL-1.2.so.0",NULL};
    void *h=NULL; int i,fd=-1;
    PFN_SDL_Init SDL_Init; PFN_SDL_Quit SDL_Quit; PFN_SDL_GetError SDL_GetError;
    PFN_SDL_VideoDriverName SDL_VideoDriverName; PFN_SDL_SetVideoMode SDL_SetVideoMode; PFN_SDL_Delay SDL_Delay;
    int axes[MAX_AXES]={0},buttons[MAX_BUTTONS]={0};
    unsigned char axis_valid[MAX_AXES]={0},button_valid[MAX_BUTTONS]={0};
    unsigned char used_type[32]={0},used_num[32]={0}; int used_dir[32]={0}; int used_count=0;
    struct js_event ev;

    printf("RG35XX MIYOO M1.3C ONSCREEN EXACT KEYMAP PROBE\n");
    printf("PRIMARY_VARIABLE=ONSCREEN_SEMANTIC_KEYMAP_ONLY\n");
    printf("DEVICE=%s\n",DEVICE_PATH);

    for(i=0;libs[i];++i){ h=dlopen(libs[i],RTLD_NOW|RTLD_LOCAL); if(h){printf("SDL1_DLOPEN=PASS path=%s\n",libs[i]);break;} }
    if(!h){printf("M1_3C_RESULT=FAIL_SDL_DLOPEN\n");return 10;}
    SDL_Init=(PFN_SDL_Init)need(h,"SDL_Init"); SDL_Quit=(PFN_SDL_Quit)need(h,"SDL_Quit");
    SDL_GetError=(PFN_SDL_GetError)need(h,"SDL_GetError"); SDL_VideoDriverName=(PFN_SDL_VideoDriverName)need(h,"SDL_VideoDriverName");
    SDL_SetVideoMode=(PFN_SDL_SetVideoMode)need(h,"SDL_SetVideoMode"); pMap=(PFN_SDL_MapRGB)need(h,"SDL_MapRGB");
    pFill=(PFN_SDL_FillRect)need(h,"SDL_FillRect"); pFlip=(PFN_SDL_Flip)need(h,"SDL_Flip"); SDL_Delay=(PFN_SDL_Delay)need(h,"SDL_Delay");
    if(SDL_Init(SDL_INIT_VIDEO)!=0){printf("SDL1_INIT_VIDEO=FAIL error=%s\n",SDL_GetError());dlclose(h);return 11;}
    { char driver[64]={0}; if(SDL_VideoDriverName(driver,64)) printf("SDL1_VIDEO_DRIVER=%s\n",driver); }
    screen=SDL_SetVideoMode(640,480,32,SDL_SWSURFACE|SDL_FULLSCREEN);
    if(!screen){printf("SDL1_SET_VIDEO_MODE=FAIL error=%s\n",SDL_GetError());SDL_Quit();dlclose(h);return 12;}
    printf("SDL1_SET_VIDEO_MODE=PASS w=%d h=%d\n",screen->w,screen->h);

    fd=open(DEVICE_PATH,O_RDONLY|O_NONBLOCK);
    if(fd<0){printf("JS0_OPEN=FAIL errno=%d error=%s\n",errno,strerror(errno));SDL_Quit();dlclose(h);return 13;}
    printf("JS0_OPEN=PASS\n");

    { long end=now_ms()+1200; while(now_ms()<end){ int rc=read_event_timeout(fd,&ev,50); if(rc<0){printf("INIT_READ=FAIL\n");goto fail;} if(rc==0)continue; if(!is_control(&ev))continue; if(!(ev.type&JS_EVENT_INIT))continue; { unsigned char t=ev.type&~JS_EVENT_INIT; if(t==JS_EVENT_AXIS&&ev.number<MAX_AXES){axes[ev.number]=ev.value;axis_valid[ev.number]=1;printf("BASELINE type=axis index=%u value=%d\n",ev.number,ev.value);} else if(t==JS_EVENT_BUTTON&&ev.number<MAX_BUTTONS){buttons[ev.number]=ev.value;button_valid[ev.number]=1;printf("BASELINE type=button index=%u value=%d\n",ev.number,ev.value);} } } }
    printf("BASELINE_LOCKED=YES\nCALIBRATION_BEGIN=YES\n"); fflush(stdout);

    for(i=0;i<steps;++i){
        long drain_end=now_ms()+STALE_DRAIN_MS; int got=0,base=0,press=0,dir=0,j; unsigned char pt=0,pn=0;
        while(now_ms()<drain_end){int rc=read_event_timeout(fd,&ev,25); if(rc<=0)continue;}
        show_prompt(names[i]); printf("EXPECT=%s\n",names[i]); fflush(stdout);
        { long deadline=now_ms()+STEP_TIMEOUT_MS;
          while(now_ms()<deadline&&!got){
            int rc=read_event_timeout(fd,&ev,250),ok=0; if(rc<0){printf("STEP=%s READ_FAIL\n",names[i]);goto fail;} if(rc==0)continue;
            if(ev.type&JS_EVENT_INIT)continue; if(!is_control(&ev))continue;
            { unsigned char t=ev.type&~JS_EVENT_INIT; int b=baseline_for(t,ev.number,axes,buttons,axis_valid,button_valid,&ok); if(!ok)continue; if((int)ev.value==b)continue;
              int d=(t==JS_EVENT_AXIS)?direction_from(ev.value,b):1; if(d==0)continue;
              for(j=0;j<used_count;++j){ int dup=0; if(t==JS_EVENT_BUTTON) dup=(used_type[j]==t&&used_num[j]==ev.number); else dup=(used_type[j]==t&&used_num[j]==ev.number&&used_dir[j]==d); if(dup){printf("IGNORED_DUPLICATE type=%s index=%u dir=%d\n",t==JS_EVENT_AXIS?"axis":"button",ev.number,d); goto next_event;} }
              pt=t;pn=ev.number;press=ev.value;base=b;dir=d;got=1;
            }
            next_event: ;
          }
        }
        if(!got){printf("STEP=%s PRESS_TIMEOUT=YES\nM1_3C_RESULT=FAIL_PRESS_TIMEOUT\n",names[i]);goto fail;}
        { long rel_dead=now_ms()+RELEASE_TIMEOUT_MS; int released=0,release=press;
          while(now_ms()<rel_dead&&!released){int rc=read_event_timeout(fd,&ev,250); if(rc<0)goto fail; if(rc==0)continue; if(ev.type&JS_EVENT_INIT)continue; if(!is_control(&ev))continue; {unsigned char t=ev.type&~JS_EVENT_INIT; if(t==pt&&ev.number==pn&&(int)ev.value==base){release=ev.value;released=1;}} }
          if(!released){printf("STEP=%s RELEASE_TIMEOUT=YES type=%s index=%u press=%d baseline=%d\nM1_3C_RESULT=FAIL_RELEASE_TIMEOUT\n",names[i],pt==JS_EVENT_AXIS?"axis":"button",pn,press,base);goto fail;}
          printf("KEYMAP name=%s type=%s index=%u press=%d release=%d baseline=%d direction=%d\n",names[i],pt==JS_EVENT_AXIS?"axis":"button",pn,press,release,base,dir); fflush(stdout);
        }
        used_type[used_count]=pt;used_num[used_count]=pn;used_dir[used_count]=dir;++used_count;
        show_confirmed(); SDL_Delay(700);
    }

    show_done(); SDL_Delay(1500);
    printf("CALIBRATION_END=YES\nKEYMAP_COUNT=%d\nM1_3C_RESULT=PASS\n",used_count); fflush(stdout);
    close(fd); SDL_Quit(); dlclose(h); return 0;

fail:
    printf("M1_3C_RESULT=FAIL\n"); fflush(stdout); if(fd>=0)close(fd); if(h){SDL_Quit();dlclose(h);} return 30;
}
