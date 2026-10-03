#!/usr/bin/env python3
import re
import sys
from pathlib import Path

if len(sys.argv) != 4:
    raise SystemExit("usage: compare_p2b_jdk_freetype.py <jdk-backend.log> <jdk-raster.log> <freetype.log>")

backend = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").splitlines()
raster = Path(sys.argv[2]).read_text(encoding="utf-8", errors="replace").splitlines()
ft = Path(sys.argv[3]).read_text(encoding="utf-8", errors="replace").splitlines()

jdk_metrics = {}
jdk_samples = {}
jdk_raster = {}
ft_metrics = {}
ft_samples = {}

m_metric = re.compile(r"^P2B_STYLE=(\d+) SIZE=(\d+) AWT_STYLE=(\d+) HEIGHT=(-?\d+) ASCENT=(-?\d+) DESCENT=(-?\d+) LEADING=(-?\d+)$")
m_sample = re.compile(r"^P2B_STYLE=(\d+) SIZE=(\d+) SAMPLE=(\d+) WIDTH=(-?\d+) DISPLAY=([^ ]+) RASTER_SHA256=([0-9a-f]+)$")
m_jr = re.compile(r"^P2B_JDK_STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) SAMPLE=(\d+) WIDTH=(-?\d+) INK=(\d+) ALPHA_SUM=(\d+) ALPHA_LEVELS=(\d+) BOUNDS=(-?\d+),(-?\d+),(-?\d+),(-?\d+)$")
m_fm = re.compile(r"^P2B_FT_STYLE=(\d+) NORMALIZED=(\d+) SIZE=(\d+) HEIGHT=(-?\d+) ASCENT=(-?\d+) DESCENT=(-?\d+)$")
m_fs = re.compile(r"^P2B_FT_STYLE=(\d+) SIZE=(\d+) SAMPLE=(\d+) WIDTH=(-?\d+) DISPLAY=([^ ]+) INK=(\d+) ALPHA_SUM=(\d+) BOUNDS=(-?\d+),(-?\d+),(-?\d+),(-?\d+)$")

for line in backend:
    m = m_metric.match(line)
    if m:
        st, sz, norm, h, a, d, lead = map(int, m.groups())
        jdk_metrics[(st, sz)] = (norm, h, a, d, lead)
        continue
    m = m_sample.match(line)
    if m:
        st, sz, sample = map(int, m.group(1,2,3))
        jdk_samples[(st,sz,sample)] = (int(m.group(4)), m.group(5), m.group(6))

for line in raster:
    m = m_jr.match(line)
    if m:
        st, norm, sz, sample, width, ink, asum, levels, x0,y0,x1,y1 = map(int, m.groups())
        jdk_raster[(st,sz,sample)] = (norm,width,ink,asum,levels,(x0,y0,x1,y1))

for line in ft:
    m = m_fm.match(line)
    if m:
        st, norm, sz, h, a, d = map(int, m.groups())
        ft_metrics[(st,sz)] = (norm,h,a,d)
        continue
    m = m_fs.match(line)
    if m:
        st,sz,sample = map(int,m.group(1,2,3))
        ft_samples[(st,sz,sample)] = (int(m.group(4)),m.group(5),int(m.group(6)),int(m.group(7)),tuple(map(int,m.group(8,9,10,11))))

expected_metrics = 8*3
expected_samples = 8*3*6
for name, obj, n in [
    ("jdk_metrics",jdk_metrics,expected_metrics),
    ("jdk_samples",jdk_samples,expected_samples),
    ("jdk_raster",jdk_raster,expected_samples),
    ("ft_metrics",ft_metrics,expected_metrics),
    ("ft_samples",ft_samples,expected_samples),
]:
    if len(obj) != n:
        raise SystemExit("P2B_DIFF_PARSE_FAIL %s count=%d expected=%d" % (name,len(obj),n))

metric_exact = metric_h_exact = metric_a_exact = metric_d_exact = 0
norm_exact = 0
width_exact = display_exact = 0
width_abs_total = width_abs_max = 0
bounds_exact = bounds_within1 = 0
ink_exact = alpha_sum_exact = 0
raster_cases = 0

for key in sorted(jdk_metrics):
    jnorm,jh,ja,jd,jlead = jdk_metrics[key]
    fnorm,fh,fa,fd = ft_metrics[key]
    norm_exact += (jnorm == fnorm)
    metric_h_exact += (jh == fh)
    metric_a_exact += (ja == fa)
    metric_d_exact += (jd == fd)
    metric_exact += ((jh,ja,jd) == (fh,fa,fd))

for key in sorted(jdk_samples):
    jw,jdisp,_ = jdk_samples[key]
    fw,fdisp,fink,fasum,fbounds = ft_samples[key]
    diff = abs(jw-fw)
    width_abs_total += diff
    width_abs_max = max(width_abs_max,diff)
    width_exact += (jw == fw)
    display_exact += (jdisp == fdisp)
    jr = jdk_raster[key]
    jnorm,jrw,jink,jasum,jlevels,jbounds = jr
    if jrw != jw:
        raise SystemExit("P2B_DIFF_INTERNAL_FAIL width disagreement key=%r backend=%d raster=%d" % (key,jw,jrw))
    raster_cases += 1
    bounds_exact += (jbounds == fbounds)
    bounds_within1 += all(abs(a-b) <= 1 for a,b in zip(jbounds,fbounds))
    ink_exact += (jink == fink)
    alpha_sum_exact += (jasum == fasum)

print("P2B_DIFF_PARSE=PASS")
print("P2B_DIFF_METRIC_CASES=%d" % expected_metrics)
print("P2B_DIFF_METRIC_NORMALIZED_STYLE_EXACT=%d" % norm_exact)
print("P2B_DIFF_METRIC_TRIPLE_EXACT=%d" % metric_exact)
print("P2B_DIFF_HEIGHT_EXACT=%d" % metric_h_exact)
print("P2B_DIFF_ASCENT_EXACT=%d" % metric_a_exact)
print("P2B_DIFF_DESCENT_EXACT=%d" % metric_d_exact)
print("P2B_DIFF_SAMPLE_CASES=%d" % expected_samples)
print("P2B_DIFF_WIDTH_EXACT=%d" % width_exact)
print("P2B_DIFF_WIDTH_ABS_ERROR_TOTAL=%d" % width_abs_total)
print("P2B_DIFF_WIDTH_ABS_ERROR_MAX=%d" % width_abs_max)
print("P2B_DIFF_DISPLAY_MASK_EXACT=%d" % display_exact)
print("P2B_DIFF_RASTER_CASES=%d" % raster_cases)
print("P2B_DIFF_RASTER_BOUNDS_EXACT=%d" % bounds_exact)
print("P2B_DIFF_RASTER_BOUNDS_WITHIN1=%d" % bounds_within1)
print("P2B_DIFF_RASTER_INK_EXACT=%d" % ink_exact)
print("P2B_DIFF_RASTER_ALPHA_SUM_EXACT=%d" % alpha_sum_exact)

# Classification is descriptive only. Candidate authorization remains a separate audit decision.
if metric_exact == expected_metrics and width_exact == expected_samples and display_exact == expected_samples:
    layout = "EXACT_ON_PROBED_MATRIX"
elif display_exact == expected_samples and width_abs_max <= 1 and metric_h_exact == expected_metrics:
    layout = "NEAR_EXACT_REQUIRES_CALIBRATION_REVIEW"
else:
    layout = "DIVERGENT_REQUIRES_CALIBRATION_OR_OTHER_BACKEND"
print("P2B_FREETYPE_LAYOUT_CLASSIFICATION=%s" % layout)
print("P2B_FREETYPE_RASTER_CLASSIFICATION=DIAGNOSTIC_ONLY")
print("P2B_RUNTIME_PATCH=FORBIDDEN")
print("P2B_DIFF_RESULT=PASS")
