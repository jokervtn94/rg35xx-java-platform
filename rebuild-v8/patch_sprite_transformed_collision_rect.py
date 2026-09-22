#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/javax/microedition/lcdui/game/Sprite.java')
s = p.read_text()

anchor = '''\tpublic final boolean collidesWith(Sprite s, boolean pixelLevel)'''
if s.count(anchor) != 1:
    raise SystemExit('DP_R8_TRANSFORMED_COLLISION_RECT_PATCH=FAIL_METHOD_ANCHOR')

helper = r'''
	private int[] getTransformedCollisionRectBounds()
	{
		int tx = collisionRectX;
		int ty = collisionRectY;
		int tw = collisionRectWidth;
		int th = collisionRectHeight;

		// DP-R8 PRIMARY VARIABLE:
		// Transform collision-rectangle geometry for Sprite-vs-Sprite collision.
		switch (currentTransform)
		{
			case TRANS_NONE:
				break;

			case TRANS_MIRROR:
				tx = srcFrameWidth - (collisionRectX + collisionRectWidth);
				break;

			case TRANS_MIRROR_ROT180:
				ty = srcFrameHeight - (collisionRectY + collisionRectHeight);
				break;

			case TRANS_ROT90:
				tx = srcFrameHeight - (collisionRectY + collisionRectHeight);
				ty = collisionRectX;
				tw = collisionRectHeight;
				th = collisionRectWidth;
				break;

			case TRANS_ROT180:
				tx = srcFrameWidth - (collisionRectX + collisionRectWidth);
				ty = srcFrameHeight - (collisionRectY + collisionRectHeight);
				break;

			case TRANS_ROT270:
				tx = collisionRectY;
				ty = srcFrameWidth - (collisionRectX + collisionRectWidth);
				tw = collisionRectHeight;
				th = collisionRectWidth;
				break;

			case TRANS_MIRROR_ROT90:
				tx = srcFrameHeight - (collisionRectY + collisionRectHeight);
				ty = srcFrameWidth - (collisionRectX + collisionRectWidth);
				tw = collisionRectHeight;
				th = collisionRectWidth;
				break;

			case TRANS_MIRROR_ROT270:
				tx = collisionRectY;
				ty = collisionRectX;
				tw = collisionRectHeight;
				th = collisionRectWidth;
				break;

			default:
				break;
		}

		return new int[] {tx, ty, tw, th};
	}

'''

s = s.replace(anchor, helper + anchor, 1)

old_init = '''\t\tint otherLeft = s.x + s.collisionRectX;
\t\tint otherTop = s.y + s.collisionRectY;
\t\tint otherRight = otherLeft + s.collisionRectWidth;
\t\tint otherBottom = otherTop + s.collisionRectHeight;

\t\tint left = this.x + this.collisionRectX;
\t\tint top = this.y + this.collisionRectY;
\t\tint right = left + this.collisionRectWidth;
\t\tint bottom = top + this.collisionRectHeight;'''

new_init = '''\t\tint[] otherCollision = s.getTransformedCollisionRectBounds();
\t\tint otherLeft = s.x + otherCollision[0];
\t\tint otherTop = s.y + otherCollision[1];
\t\tint otherRight = otherLeft + otherCollision[2];
\t\tint otherBottom = otherTop + otherCollision[3];

\t\tint[] thisCollision = this.getTransformedCollisionRectBounds();
\t\tint left = this.x + thisCollision[0];
\t\tint top = this.y + thisCollision[1];
\t\tint right = left + thisCollision[2];
\t\tint bottom = top + thisCollision[3];'''

if s.count(old_init) != 1:
    raise SystemExit('DP_R8_TRANSFORMED_COLLISION_RECT_PATCH=FAIL_INIT_ANCHOR')
s = s.replace(old_init, new_init, 1)

old_clip = '''\t\t\t\tif (this.collisionRectX < 0) { left = this.x; }
\t\t\t\tif (this.collisionRectY < 0) { top = this.y; }
\t\t\t\tif ((this.collisionRectX + this.collisionRectWidth) > this.width) { right = this.x + this.width; }
\t\t\t\tif ((this.collisionRectY + this.collisionRectHeight) > this.height) { bottom = this.y + this.height; }

\t\t\t\tif (s.collisionRectX < 0) { otherLeft = s.x; }
\t\t\t\tif (s.collisionRectY < 0) { otherTop = s.y; }
\t\t\t\tif ((s.collisionRectX + s.collisionRectWidth) > s.width) { otherRight = s.x + s.width; }
\t\t\t\tif ((s.collisionRectY + s.collisionRectHeight) > s.height) { otherBottom = s.y + s.height; }'''

new_clip = '''\t\t\t\tif (thisCollision[0] < 0) { left = this.x; }
\t\t\t\tif (thisCollision[1] < 0) { top = this.y; }
\t\t\t\tif ((thisCollision[0] + thisCollision[2]) > this.width) { right = this.x + this.width; }
\t\t\t\tif ((thisCollision[1] + thisCollision[3]) > this.height) { bottom = this.y + this.height; }

\t\t\t\tif (otherCollision[0] < 0) { otherLeft = s.x; }
\t\t\t\tif (otherCollision[1] < 0) { otherTop = s.y; }
\t\t\t\tif ((otherCollision[0] + otherCollision[2]) > s.width) { otherRight = s.x + s.width; }
\t\t\t\tif ((otherCollision[1] + otherCollision[3]) > s.height) { otherBottom = s.y + s.height; }'''

if s.count(old_clip) != 1:
    raise SystemExit('DP_R8_TRANSFORMED_COLLISION_RECT_PATCH=FAIL_CLIP_ANCHOR')
s = s.replace(old_clip, new_clip, 1)

p.write_text(s)

post = p.read_text()
if 'DP-R8 PRIMARY VARIABLE:' not in post:
    raise SystemExit('DP_R8_TRANSFORMED_COLLISION_RECT_PATCH=FAIL_POSTMARKER')

print('DP_R8_TRANSFORMED_COLLISION_RECT_PATCH=PASS')
print('DP_R8_PRIMARY_VARIABLE=SPRITE_VS_SPRITE_TRANSFORMED_COLLISION_RECT_ONLY')
