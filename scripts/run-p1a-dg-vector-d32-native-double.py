#!/usr/bin/env python3
from pathlib import Path

src = Path("tests/p1a/RG35XXDGVectorD3GenericPolygonSSIGate.java")
outdir = Path("out/p1a-dg-vector-d32/generated/org/recompile/rg35xx/p1a")
outdir.mkdir(parents=True, exist_ok=True)
out = outdir / "RG35XXDGVectorD32GenericPolygonNativeDoubleGate.java"

s = src.read_text(encoding="utf-8")

old_class = "RG35XXDGVectorD3GenericPolygonSSIGate"
new_class = "RG35XXDGVectorD32GenericPolygonNativeDoubleGate"
old_precision = "float sf=(float)Math.floor(slope);"
new_precision = "double sf=Math.floor((double)slope);"

if s.count(old_class) != 1:
    raise SystemExit("DGVD32_GENERATOR_FAIL class anchor count=%d" % s.count(old_class))
if s.count(old_precision) != 1:
    raise SystemExit("DGVD32_GENERATOR_FAIL precision anchor count=%d" % s.count(old_precision))
if s.count("DGVD3_") < 8:
    raise SystemExit("DGVD32_GENERATOR_FAIL marker family missing")

# D3.2 must preserve the exact D3 17-fixed + 320-fuzz matrix and all raster
# logic except the single source-proven precision correction from D3.1:
# OpenJDK C computes slope - floor(slope) in double precision because floor()
# returns double. The accepted G2B Java specialization narrowed floor(slope)
# back to float before the subtraction.
t = s.replace(old_class, new_class, 1)
t = t.replace("DGVD3_", "DGVD32_")
t = t.replace(old_precision, new_precision, 1)

if old_precision in t:
    raise SystemExit("DGVD32_GENERATOR_FAIL stale float subtraction remains")
if new_precision not in t:
    raise SystemExit("DGVD32_GENERATOR_FAIL native-double subtraction missing")
if "private static final long SEED = 0x35D3001L;" not in t:
    raise SystemExit("DGVD32_GENERATOR_FAIL D3 seed changed")
if "for (int i=0; i<320; i++)" not in t:
    raise SystemExit("DGVD32_GENERATOR_FAIL D3 fuzz count changed")
if "check(new Case(\"DOUBLE_LOOP_EVEN_ODD\"" not in t:
    raise SystemExit("DGVD32_GENERATOR_FAIL D3 fixed matrix changed")

out.write_text(t, encoding="utf-8")
print("DGVD32_GENERATOR=PASS")
print("DGVD32_SOURCE_MATRIX=D3_EXACT_17_FIXED_PLUS_320_FUZZ")
print("DGVD32_SEMANTIC_DELTA=ONLY_SLOPE_FLOOR_SUBTRACTION_PRECISION")
print("DGVD32_OPENJDK_C_SUBTRACTION=DOUBLE")
print("DGVD32_RUNTIME_CHANGE=NO")
print("DGVD32_OUTPUT=" + str(out))
