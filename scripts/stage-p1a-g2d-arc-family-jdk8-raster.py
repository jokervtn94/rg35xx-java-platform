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

for helper in ["rg35xxDrawArcJdk8", "rg35xxFillArcJdk8Lattice", "rg35xxPPDrawCubicCanonicalSplit"]:
    if helper in s:
        raise SystemExit("P1A_G2D_STAGE_FAIL helper already present: %s" % helper)

old_draw = '''\tpublic void drawArc(int x, int y, int width, int height, int startAngle, int arcAngle)\n\t{\n\t\tgc.drawArc(x, y, width, height, startAngle, arcAngle);\n\t}\n'''

new_draw = r'''	/*
	 * RG35XX raw2D JDK8-equivalent arc outline.
	 * Canonical path: LoopPipe.drawArc -> Arc2D.OPEN -> ArcIterator ->
	 * Path2D.Float -> ProcessPath.drawPath.
	 *
	 * Important: ArcIterator limits each Bezier to <= 90 degrees, but an
	 * arbitrary start angle means a segment can still cross an ellipse X/Y
	 * extremum. JDK8 ProcessPath therefore solves dX/dt and dY/dt and splits
	 * the cubic at those roots before forward differencing. G2C quarter-round
	 * cubics were already monotonic and did not expose this requirement.
	 */
	private static double rg35xxArcBtan(double increment)
	{
		increment /= 2.0;
		return 4.0 / 3.0 * Math.sin(increment) / (1.0 + Math.cos(increment));
	}

	/* Exact coefficient/root strategy used by QuadCurve2D.solveQuadratic. */
	private static int rg35xxPPSolveQuadratic(double c, double b, double a, double[] res)
	{
		int roots = 0;
		if(a == 0.0)
		{
			if(b == 0.0) return -1;
			res[roots++] = -c / b;
		}
		else
		{
			double d = b * b - 4.0 * a * c;
			if(d < 0.0) return 0;
			d = Math.sqrt(d);
			if(b < 0.0) d = -d;
			double q = (b + d) / -2.0;
			res[roots++] = q / a;
			if(q != 0.0) res[roots++] = c / q;
		}
		return roots;
	}

	private void rg35xxPPDrawFirstCanonicalMonotonicPart(float[] c, float t, int argb)
	{
		float[] first = new float[8];
		float tx, ty;
		first[0] = c[0];
		first[1] = c[1];
		tx = c[2] + t * (c[4] - c[2]);
		ty = c[3] + t * (c[5] - c[3]);
		first[2] = c[0] + t * (c[2] - c[0]);
		first[3] = c[1] + t * (c[3] - c[1]);
		first[4] = first[2] + t * (tx - first[2]);
		first[5] = first[3] + t * (ty - first[3]);
		c[4] = c[4] + t * (c[6] - c[4]);
		c[5] = c[5] + t * (c[7] - c[5]);
		c[2] = tx + t * (c[4] - tx);
		c[3] = ty + t * (c[5] - ty);
		c[0] = first[6] = first[4] + t * (c[2] - first[4]);
		c[1] = first[7] = first[5] + t * (c[3] - first[5]);
		rg35xxPPDrawCubic(first, argb);
	}

	/* JDK8 ProcessPath.ProcessCubic extrema split, specialized for drawArc. */
	private void rg35xxPPDrawCubicCanonicalSplit(float[] c, int argb)
	{
		double[] params = new double[4];
		double[] res = new double[2];
		int cnt = 0;

		if((c[0] > c[2] || c[2] > c[4] || c[4] > c[6]) &&
		   (c[0] < c[2] || c[2] < c[4] || c[4] < c[6]))
		{
			double a = -c[0] + 3.0*c[2] - 3.0*c[4] + c[6];
			double b = 2.0*(c[0] - 2.0*c[2] + c[4]);
			double cc = -c[0] + c[2];
			int nr = rg35xxPPSolveQuadratic(cc, b, a, res);
			for(int i=0; i<nr; i++) if(res[i] > 0.0 && res[i] < 1.0) params[cnt++] = res[i];
		}

		if((c[1] > c[3] || c[3] > c[5] || c[5] > c[7]) &&
		   (c[1] < c[3] || c[3] < c[5] || c[5] < c[7]))
		{
			double a = -c[1] + 3.0*c[3] - 3.0*c[5] + c[7];
			double b = 2.0*(c[1] - 2.0*c[3] + c[5]);
			double cc = -c[1] + c[3];
			int nr = rg35xxPPSolveQuadratic(cc, b, a, res);
			for(int i=0; i<nr; i++) if(res[i] > 0.0 && res[i] < 1.0) params[cnt++] = res[i];
		}

		for(int i=1; i<cnt; i++)
		{
			double v = params[i];
			int j = i - 1;
			while(j >= 0 && params[j] > v) { params[j+1] = params[j]; j--; }
			params[j+1] = v;
		}

		if(cnt > 0)
		{
			rg35xxPPDrawFirstCanonicalMonotonicPart(c, (float)params[0], argb);
			for(int i=1; i<cnt; i++)
			{
				double p = params[i] - params[i-1];
				if(p > 0.0)
					rg35xxPPDrawFirstCanonicalMonotonicPart(c,
						(float)(p / (1.0 - params[i-1])), argb);
			}
		}
		rg35xxPPDrawCubic(c, argb);
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
			if(arcSegs == 0) return;
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
			rg35xxPPDrawCubicCanonicalSplit(q, argb);
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
    "rg35xxPPDrawCubicCanonicalSplit",
    "rg35xxPPSolveQuadratic",
    "ProcessPath.drawPath",
    "deterministic fuzz protects this equivalence",
]:
    if token not in out:
        raise SystemExit("P1A_G2D_STAGE_FAIL output token missing: %s" % token)

pg.write_text(out, encoding="utf-8")
print("P1A_G2D_STAGE=PASS")
print("P1A_G2D_OWNER=RG35XX_GRAPHICS_BOUNDARY")
print("P1A_G2D_CHANGED_METHODS=Graphics.drawArc,Graphics.fillArc")
print("P1A_G2D_DRAW_RASTER=OPENJDK8_ARCITERATOR_PROCESSPATH_DRAWCUBIC_EXTREMA_SPLIT")
print("P1A_G2D_FILL_RASTER=JDK8_PROCESSPATH_EQUIVALENT_INTEGER_ELLIPSE_PARAMETER_SECTOR")
print("P1A_G2D_CORE2D_CHANGE=NO")
print("P1A_G2D_PHYSICAL_TEST=NO_MODULE_INTEGRATION_PENDING")
