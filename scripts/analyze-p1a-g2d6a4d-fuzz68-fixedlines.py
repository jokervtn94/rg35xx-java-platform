#!/usr/bin/env python3
import re
import sys

W,H=48,40
COLOR=0xff3366cc
WHITE=0xffffffff
TARGET=(31,39)
AWT_COUNT=17
AWT_CHECKSUM="7e567c4cfcce292"
SEG_RE=re.compile(r'^G2D6A4D_SEG X0=(-?\d+) Y0=(-?\d+) X1=(-?\d+) Y1=(-?\d+) CHECK=(true|false)$')

if len(sys.argv)!=2:
    raise SystemExit("usage: analyze-p1a-g2d6a4d-fuzz68-fixedlines.py <trace-log>")
lines=open(sys.argv[1],encoding='utf-8').read().splitlines()
segs=[]
raw_count=raw_sum=raw_pixel=None
for line in lines:
    m=SEG_RE.match(line)
    if m:
        segs.append((int(m.group(1)),int(m.group(2)),int(m.group(3)),int(m.group(4)),m.group(5)=='true'))
    elif line.startswith('G2D6A4D_RAW_COUNT='): raw_count=int(line.split('=',1)[1])
    elif line.startswith('G2D6A4D_RAW_CHECKSUM='): raw_sum=line.split('=',1)[1].lower()
    elif line.startswith('G2D6A4D_RAW_PIXEL_31_39='): raw_pixel=line.split('=',1)[1].lower()
if not segs: raise SystemExit('G2D6A4D_ANALYZE_FAIL no fixed-line segments')
if raw_count is None or raw_sum is None or raw_pixel is None: raise SystemExit('G2D6A4D_ANALYZE_FAIL raw summary missing')

def tdiv(a,b):
    if b==0: raise ZeroDivisionError
    q=abs(a)//abs(b)
    return -q if (a<0) != (b<0) else q

def outcode(x,y,xmin,ymin,xmax,ymax):
    c=1 if y<ymin else (2 if y>ymax else 0)
    if x<xmin:c|=4
    elif x>xmax:c|=8
    return c

def adjust_line(x1,y1,x2,y2,xmin=0,ymin=0,xhi=W,yhi=H):
    xmax=xhi-1; ymax=yhi-1
    if xmax<xmin or ymax<ymin:return None
    if x1==x2:
        if x1<xmin or x1>xmax:return None
        if y1>y2:y1,y2=y2,y1
        y1=max(y1,ymin);y2=min(y2,ymax)
        return None if y1>y2 else (x1,y1,x2,y2,x2-x1,y2-y1,0,abs(y2-y1))
    if y1==y2:
        if y1<ymin or y1>ymax:return None
        if x1>x2:x1,x2=x2,x1
        x1=max(x1,xmin);x2=min(x2,xmax)
        return None if x1>x2 else (x1,y1,x2,y2,x2-x1,y2-y1,abs(x2-x1),0)
    ox1,oy1,ox2,oy2=x1,y1,x2,y2
    dx=x2-x1;dy=y2-y1;ax=abs(dx);ay=abs(dy);xmajor=ax>=ay
    o1=outcode(x1,y1,xmin,ymin,xmax,ymax);o2=outcode(x2,y2,xmin,ymin,xmax,ymax)
    while (o1|o2)!=0:
        if (o1&o2)!=0:return None
        if o1!=0:
            if o1&3:
                y1=ymin if (o1&1) else ymax
                ys=abs(y1-oy1);xs=2*ys*ax+ay
                if xmajor:xs+=ay-ax-1
                xs=tdiv(xs,2*ay)
                if dx<0:xs=-xs
                x1=ox1+xs
            else:
                x1=xmin if (o1&4) else xmax
                xs=abs(x1-ox1);ys=2*xs*ay+ax
                if not xmajor:ys+=ax-ay-1
                ys=tdiv(ys,2*ax)
                if dy<0:ys=-ys
                y1=oy1+ys
            o1=outcode(x1,y1,xmin,ymin,xmax,ymax)
        else:
            if o2&3:
                y2=ymin if (o2&1) else ymax
                ys=abs(y2-oy2);xs=2*ys*ax+ay
                if xmajor:xs+=ay-ax
                else:xs-=1
                xs=tdiv(xs,2*ay)
                if dx>0:xs=-xs
                x2=ox2+xs
            else:
                x2=xmin if (o2&4) else xmax
                xs=abs(x2-ox2);ys=2*xs*ay+ax
                if xmajor:ys-=1
                else:ys+=ax-ay
                ys=tdiv(ys,2*ax)
                if dy>0:ys=-ys
                y2=oy2+ys
            o2=outcode(x2,y2,xmin,ymin,xmax,ymax)
    return (x1,y1,x2,y2,dx,dy,ax,ay)

def draw_general(x1,y1,x2,y2,pix):
    b=adjust_line(x1,y1,x2,y2)
    if b is None:return
    x1,y1,x2,y2,dx,dy,ax,ay=b
    if x1==x2:
        if y1>y2:y1,y2=y2,y1
        for y in range(y1,y2+1):
            if 0<=x1<W and 0<=y<H:pix.add((x1,y))
        return
    if y1==y2:
        if x1>x2:x1,x2=x2,x1
        for x in range(x1,x2+1):
            if 0<=x<W and 0<=y1<H:pix.add((x,y1))
        return
    xmajor=ax>=ay
    if xmajor:
        errmajor=ay*2;errminor=ax*2;bmaj=-1 if dx<0 else 1;bmin=-1 if dy<0 else 1;axn=-ax;steps=x2-x1
    else:
        errmajor=ax*2;errminor=ay*2;bmaj=-1 if dy<0 else 1;bmin=-1 if dx<0 else 1;ayn=-ay;steps=y2-y1
    error=-(errminor//2)
    if y1!=b[1]: pass
    # b[0:4] are already clipped; original phase must use the original endpoints.
    # Recompute phase using dx/dy endpoint origin retained in closure arguments below is not possible here,
    # so adjust_line phase is implemented in draw_general_phase instead.
    raise AssertionError('unreachable')

def draw_general_phase(ox1,oy1,ox2,oy2,pix):
    b=adjust_line(ox1,oy1,ox2,oy2)
    if b is None:return
    x1,y1,x2,y2,dx,dy,ax,ay=b
    if x1==x2 or y1==y2:
        if x1==x2:
            if y1>y2:y1,y2=y2,y1
            for y in range(y1,y2+1):
                if 0<=x1<W and 0<=y<H:pix.add((x1,y))
        else:
            if x1>x2:x1,x2=x2,x1
            for x in range(x1,x2+1):
                if 0<=x<W and 0<=y1<H:pix.add((x,y1))
        return
    xmajor=ax>=ay
    if xmajor:
        errmajor=ay*2;errminor=ax*2;bmaj=-1 if dx<0 else 1;bmin=-1 if dy<0 else 1;ax_phase=-ax;ay_phase=ay;steps=x2-x1
    else:
        errmajor=ax*2;errminor=ay*2;bmaj=-1 if dy<0 else 1;bmin=-1 if dx<0 else 1;ax_phase=ax;ay_phase=-ay;steps=y2-y1
    error=-(errminor//2)
    if y1!=oy1:error+=abs(y1-oy1)*ax_phase*2
    if x1!=ox1:error+=abs(x1-ox1)*ay_phase*2
    steps=abs(steps)
    while True:
        if 0<=x1<W and 0<=y1<H:pix.add((x1,y1))
        if steps==0:break
        steps-=1
        if xmajor:
            x1+=bmaj;error+=errmajor
            if error>=0:y1+=bmin;error-=errminor
        else:
            y1+=bmaj;error+=errmajor
            if error>=0:x1+=bmin;error-=errminor

def clip_one(line_min,line_max,a1,b1,a2,b2):
    if not (a1<line_min or a1>line_max):return (a1,b1,False)
    if a1<line_min:
        if a2<line_min:return None
        t=line_min
    else:
        if a2>line_max:return None
        t=line_max
    v=b1+((t-a1)*(b2-b1))/(a2-a1)
    return (int(t),int(v),True)

def native_preclip(x0,y0,x1,y1):
    # Native ProcessPath PROCESS_LINE uses DrawHandler fractional bounds + 0.5.
    xmin=0.0;ymin=0.0;xmax=W-(1.0/1024.0);ymax=H-(1.0/1024.0)
    r=clip_one(ymin,ymax,y0,x0,y1,x1)
    if r is None:return None
    y0,x0,_=r
    r=clip_one(ymin,ymax,y1,x1,y0,x0)
    if r is None:return None
    y1,x1,_=r
    r=clip_one(xmin,xmax,x0,y0,x1,y1)
    if r is None:return None
    x0,y0,_=r
    r=clip_one(xmin,xmax,x1,y1,x0,y0)
    if r is None:return None
    x1,y1,_=r
    return (x0,y0,x1,y1)

def checksum(points):
    h=1469598103934665603
    mask=(1<<64)-1
    for y in range(H):
        for x in range(W):
            v=COLOR if (x,y) in points else WHITE
            h^=v&0xffffffff
            h=(h*1099511628211)&mask
    return format(h,'x')

current=set();native=set();changed=[]
for i,(x0,y0,x1,y1,check) in enumerate(segs):
    draw_general_phase(x0,y0,x1,y1,current)
    nx=(x0,y0,x1,y1)
    if check:
        nx=native_preclip(x0,y0,x1,y1)
        if nx!=(x0,y0,x1,y1): changed.append((i,(x0,y0,x1,y1),nx))
    if nx is not None:
        draw_general_phase(nx[0],nx[1],nx[2],nx[3],native)

cs=checksum(current);ns=checksum(native)
print('G2D6A4D_SEGMENT_COUNT=%d'%len(segs))
print('G2D6A4D_CHECKBOUNDS_SEGMENTS=%d'%sum(1 for s in segs if s[4]))
print('G2D6A4D_NATIVE_PRECLIP_CHANGED_SEGMENTS=%d'%len(changed))
for i,b,a in changed:
    print('G2D6A4D_CHANGED_SEG=%d BEFORE=%s AFTER=%s'%(i,','.join(map(str,b)),'INVISIBLE' if a is None else ','.join(map(str,a))))
print('G2D6A4D_CURRENT_SIM_COUNT=%d'%len(current))
print('G2D6A4D_CURRENT_SIM_CHECKSUM='+cs)
print('G2D6A4D_CURRENT_SIM_TARGET=%s'%('COLOR' if TARGET in current else 'WHITE'))
print('G2D6A4D_NATIVE_SIM_COUNT=%d'%len(native))
print('G2D6A4D_NATIVE_SIM_CHECKSUM='+ns)
print('G2D6A4D_NATIVE_SIM_TARGET=%s'%('COLOR' if TARGET in native else 'WHITE'))

if len(current)!=raw_count or cs!=raw_sum or (TARGET in current)!=(raw_pixel=='ff3366cc'):
    raise SystemExit('G2D6A4D_ANALYZE_FAIL current simulator does not reproduce Raw2D')
print('G2D6A4D_CURRENT_SIM_REPRODUCES_RAW=PASS')
if len(native)!=AWT_COUNT or ns!=AWT_CHECKSUM or TARGET not in native:
    raise SystemExit('G2D6A4D_ANALYZE_FAIL native preclip does not reproduce AWT FUZZ_68')
print('G2D6A4D_NATIVE_PRECLIP_REPRODUCES_AWT=PASS')
print('G2D6A4D_FIRST_DIVERGENCE_PROOF=NATIVE_PROCESSPATH_PROCESS_LINE_PRECLIP')
