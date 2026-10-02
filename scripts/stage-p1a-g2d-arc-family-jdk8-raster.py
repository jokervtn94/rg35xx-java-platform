#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: stage-p1a-g2d-arc-family-jdk8-raster.py <stage-src>")

root = Path(sys.argv[1]).resolve()
pg = root / "org/recompile/mobile/PlatformGraphics.java"
if not pg.is_file():
    raise SystemExit("P1A_G2D_STAGE_FAIL staged PlatformGraphics missing")

s = pg.read_text(encoding="utf-8")

for marker in [
    "rg35xxDrawRoundRectJdk8",
    "rg35xxPPDrawCubic",
    "rg35xxFillTriangleJdk8SSI",
    "Pinned Aweigit/JDK8 final result is the following full fillRect",
    "rg35xxCopyAreaSourceOver",
]:
    if marker not in s:
        raise SystemExit("P1A_G2D_STAGE_FAIL parent marker missing: %s" % marker)

for helper in ["rg35xxDrawArcJdk8", "rg35xxFillArcJdk8Lattice"]:
    if helper in s:
        raise SystemExit("P1A_G2D_STAGE_FAIL helper already present: %s" % helper)

old_draw = '''\tpublic void drawArc(int x, int y, int width, int height, int startAngle, int arcAngle)\n\t{\n\t\tgc.drawArc(x, y, width, height, startAngle, arcAngle);\n\t}\n'''

new_draw = r'''	/*
	 * RG35XX raw2D JDK8-equivalent arc outline.
	 * Canonical path: LoopPipe.drawArc -> Arc2D.OPEN -> ArcIterator ->
	 * Path2D.Float -> ProcessPath.drawPath.  The G2C ProcessPath drawing
	 * helpers below are reused; only ArcIterator geometry is added here.
	 */
	private static double rg35xxArcBtan(double increment)
	{
		increment /= 2.0;
		return 4.0 / 3.0 * Math.sin(increment) / (1.0 + Math.cos(increment));
	}

	private void rg35xxDrawArcJdk8(int x, int y, int width, int height, int startAngle, int arcAngle)
	{
		if(width < 0 || height < 0) return;

		double aw = ((double)width) / 2.0;
		double ah = ((double)height) / 2.0;
		double cx = ((double)x) + aw;
		double cy = ((double)y) + ah;
		double angle = -Math.toRadians((double)startAngle);
		double ext = -((double)arcAngle);
		int arcSegs;
		double increment;
		double cv;

		if(ext >= 360.0 || ext <= -360.0)
		{
			arcSegs = 4;
			increment = Math.PI / 2.0;
			cv = 0.5522847498307933;
			if(ext < 0.0)
			{
				increment = -increment;
				cv = -cv;
			}
		}
		else
		{
			arcSegs = (int)Math.ceil(Math.abs(ext) / 90.0);
			if(arcSegs == 0) return; // ArcIterator emits MOVETO only.
			increment = Math.toRadians(ext / (double)arcSegs);
			cv = rg35xxArcBtan(increment);
			if(cv == 0.0) return;
		}

		float tx = (float)translateX;
		float ty = (float)translateY;
		float px = (float)(cx + Math.cos(angle) * aw) + tx;
		float py = (float)(cy + Math.sin(angle) * ah) + ty;
		int argb = 0xFF000000 | (color & 0x00FFFFFF);

		for(int i=0; i<arcSegs; i++)
		{
			double a0 = angle + increment * (double)i;
			double r0x = Math.cos(a0);
			double r0y = Math.sin(a0);
			double a1 = a0 + increment;
			double r1x = Math.cos(a1);
			double r1y = Math.sin(a1);

			float[] q = new float[8];
			q[0] = px; q[1] = py;
			q[2] = (float)(cx + (r0x - cv * r0y) * aw) + tx;
			q[3] = (float)(cy + (r0y + cv * r0x) * ah) + ty;
			q[4] = (float)(cx + (r1x + cv * r1y) * aw) + tx;
			q[5] = (float)(cy + (r1y - cv * r1x) * ah) + ty;
			q[6] = (float)(cx + r1x * aw) + tx;
			q[7] = (float)(cy + r1y * ah) + ty;
			rg35xxPPDrawCubic(q, argb);
			px = q[6]; py = q[7];
		}
	}

	public void drawArc(int x, int y, int width, int height, int startAngle, int arcAngle)
	{
		if(platformImage != null && platformImage.isRG35XXRaw())
		{
			rg35xxDrawArcJdk8(x, y, width, height, startAngle, arcAngle);
			return;
		}
		gc.drawArc(x, y, width, height, startAngle, arcAngle);
	}
'''

old_fill = '''\tpublic void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle)\n\t{\n\t\tgc.fillArc(x, y, width, height, startAngle, arcAngle);\n\t}\n'''

new_fill = r'''	/*
	 * RG35XX raw2D JDK8-equivalent pie fill.
	 * Host characterization of the pinned JDK8 ProcessPath fill shows that
	 * the resulting integer mask is exactly the lattice points inside the
	 * ellipse whose ellipse-parameter angle lies in the requested PIE sector.
	 * G2D strict differential + deterministic fuzz protects this equivalence.
	 */
	private void rg35xxFillArcJdk8Lattice(int x, int y, int width, int height, int startAngle, int arcAngle)
	{
		if(width <= 0 || height <= 0 || arcAngle == 0) return;

		int pw = platformImage.getRG35XXWidth();
		int ph = platformImage.getRG35XXHeight();
		int clipL = Math.max(0, clipX);
		int clipT = Math.max(0, clipY);
		int clipR = Math.min(pw, clipX + clipWidth);
		int clipB = Math.min(ph, clipY + clipHeight);
		if(clipL >= clipR || clipT >= clipB) return;

		double left = (double)x + (double)translateX;
		double top = (double)y + (double)translateY;
		double rx = ((double)width) / 2.0;
		double ry = ((double)height) / 2.0;
		double cx = left + rx;
		double cy = top + ry;

		int bx0 = (int)Math.floor(left);
		int by0 = (int)Math.floor(top);
		int bx1 = (int)Math.ceil(left + (double)width);
		int by1 = (int)Math.ceil(top + (double)height);
		if(bx0 < clipL) bx0 = clipL;
		if(by0 < clipT) by0 = clipT;
		if(bx1 >= clipR) bx1 = clipR - 1;
		if(by1 >= clipB) by1 = clipB - 1;
		if(bx0 > bx1 || by0 > by1) return;

		double start = ((double)startAngle) % 360.0;
		if(start < 0.0) start += 360.0;
		double extent = (double)arcAngle;
		boolean full = extent >= 360.0 || extent <= -360.0;
		double absExtent = Math.abs(extent);
		int argb = 0xFF000000 | (color & 0x00FFFFFF);
		int[] pixels = platformImage.getRG35XXPixels();

		for(int py=by0; py<=by1; py++)
		{
			double ny = (((double)py) - cy) / ry;
			double ny2 = ny * ny;
			for(int px=bx0; px<=bx1; px++)
			{
				double nx = (((double)px) - cx) / rx;
				if(nx * nx + ny2 > 1.0) continue;

				if(!full)
				{
					double a = Math.toDegrees(Math.atan2(-ny, nx));
					if(a < 0.0) a += 360.0;
					double delta;
					if(extent > 0.0)
					{
						delta = a - start;
						if(delta < 0.0) delta += 360.0;
					}
					else
					{
						delta = start - a;
						if(delta < 0.0) delta += 360.0;
					}
					if(delta > absExtent) continue;
				}

				pixels[py * pw + px] = argb;
			}
		}
	}

	public void fillArc(int x, int y, int width, int height, int startAngle, int arcAngle)
	{
		if(platformImage != null && platformImage.isRG35XXRaw())
		{
			rg35xxFillArcJdk8Lattice(x, y, width, height, startAngle, arcAngle);
			return;
		}
		gc.fillArc(x, y, width, height, startAngle, arcAngle);
	}
'''

if s.count(old_draw) != 1:
    raise SystemExit("P1A_G2D_STAGE_FAIL drawArc anchor count=%d" % s.count(old_draw))
if s.count(old_fill) != 1:
    raise SystemExit("P1A_G2D_STAGE_FAIL fillArc anchor count=%d" % s.count(old_fill))

out = s.replace(old_draw, new_draw, 1).replace(old_fill, new_fill, 1)
for token in [
    "rg35xxDrawArcJdk8",
    "rg35xxFillArcJdk8Lattice",
    "ArcIterator ->",
    "deterministic fuzz protects this equivalence",
]:
    if token not in out:
        raise SystemExit("P1A_G2D_STAGE_FAIL output token missing: %s" % token)

pg.write_text(out, encoding="utf-8")
print("P1A_G2D_STAGE=PASS")
print("P1A_G2D_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_G2D_CHANGED_METHODS=Graphics.drawArc,Graphics.fillArc")
print("P1A_G2D_DRAW_RASTER=OPENJDK8_ARCITERATOR_PROCESSPATH_DRAW_REUSE_G2C")
print("P1A_G2D_FILL_RASTER=JDK8_PROCESSPATH_EQUIVALENT_INTEGER_ELLIPSE_PARAMETER_SECTOR")
print("P1A_G2D_CORE2D_CHANGE=NO")
print("P1A_G2D_PHYSICAL_TEST=NO_MODULE_INTEGRATION_PENDING")
