#!/usr/bin/env python3
from pathlib import Path
p=Path('upstream/src/org/recompile/mobile/PlatformGraphics.java')
s=p.read_text()
old='''\tprivate int rg35xxBitmapScale() { return font.getHeight()>=26 ? 2 : 1; }'''
new='''\tprivate static int rg35xxR2D4SmallBudget=2;
\tprivate static int rg35xxR2D4MediumBudget=2;
\tprivate static int rg35xxR2D4LargeBudget=2;
\tprivate int rg35xxBitmapScale() {
\t\tint h=font.getHeight();
\t\tint scale=h>=26 ? 2 : 1;
\t\tif(Boolean.getBoolean("rg35xx.font.size.diagnostic")) {
\t\t\tint size=font.getSize();
\t\t\tboolean emit=false;
\t\t\tif(size==8 && rg35xxR2D4SmallBudget>0) { rg35xxR2D4SmallBudget--; emit=true; }
\t\t\telse if(size==0 && rg35xxR2D4MediumBudget>0) { rg35xxR2D4MediumBudget--; emit=true; }
\t\t\telse if(size==16 && rg35xxR2D4LargeBudget>0) { rg35xxR2D4LargeBudget--; emit=true; }
\t\t\tif(emit) System.out.println("M1_14_R2D4_SIZE_COVERAGE SIZE="+size+" HEIGHT="+h+" SCALE="+scale);
\t\t}
\t\treturn scale;
\t}'''
if s.count(old)!=1: raise SystemExit('M1_14_R2D4_PATCH=FAIL_SCALE_ANCHOR')
s=s.replace(old,new,1)
p.write_text(s)
print('M1_14_R2D4_SIZE_COVERAGE_TRACE_PATCH=PASS')
