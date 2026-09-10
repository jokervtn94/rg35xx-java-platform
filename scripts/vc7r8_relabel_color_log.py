#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 2:
    raise SystemExit('usage: vc7r8_relabel_color_log.py <rg35xx_golden_video.c>')

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
old = '/mnt/mmc/freej2me-vc7r4-color.log'
new = '/mnt/mmc/freej2me-vc7r8-color.log'

n = s.count(old)
if n != 1:
    raise SystemExit('VC7R8 LOG RELABEL FAIL: old path count=%d' % n)
if new in s:
    raise SystemExit('VC7R8 LOG RELABEL FAIL: new path already present')

s = s.replace(old, new, 1)

if old in s:
    raise SystemExit('VC7R8 LOG RELABEL FAIL: stale VC7R4 path remains')
if s.count(new) != 1:
    raise SystemExit('VC7R8 LOG RELABEL FAIL: new path count=%d' % s.count(new))

p.write_text(s, encoding='utf-8', newline='\n')
print('VC7R8 COLOR LOG RELABEL=PASS')
print('LOG=' + new)
