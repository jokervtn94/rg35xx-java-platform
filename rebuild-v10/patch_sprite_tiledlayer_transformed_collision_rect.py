#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/javax/microedition/lcdui/game/Sprite.java')
s = p.read_text()

# DP-R10 runs after DP-R8, so the already device-proven helper must exist.
if 'private int[] getTransformedCollisionRectBounds()' not in s:
    raise SystemExit('DP_R10_TILE_COLLISION_RECT_PATCH=FAIL_MISSING_DP_R8_HELPER')

old_init = '''\t\tint sx1 = this.x + this.collisionRectX;\n\t\tint sy1 = this.y + this.collisionRectY;\n\t\tint sx2 = sx1 + this.collisionRectWidth;\n\t\tint sy2 = sy1 + this.collisionRectHeight;'''

new_init = '''\t\t// DP-R10 PRIMARY VARIABLE: use the DP-R8-proven transformed\n\t\t// collision rectangle for Sprite-vs-TiledLayer collision only.\n\t\tint[] thisCollision = this.getTransformedCollisionRectBounds();\n\t\tint sx1 = this.x + thisCollision[0];\n\t\tint sy1 = this.y + thisCollision[1];\n\t\tint sx2 = sx1 + thisCollision[2];\n\t\tint sy2 = sy1 + thisCollision[3];'''

# Scope the replacement to collidesWith(TiledLayer) only by requiring one
# remaining raw-init occurrence after DP-R8 has already changed Sprite-vs-Sprite.
if s.count(old_init) != 1:
    raise SystemExit('DP_R10_TILE_COLLISION_RECT_PATCH=FAIL_INIT_ANCHOR count=%d' % s.count(old_init))
s = s.replace(old_init, new_init, 1)

old_clip = '''\t\t\tif (this.collisionRectX < 0) { sx1 = this.x; }\n\t\t\tif (this.collisionRectY < 0) { sy1 = this.y; }\n\t\t\tif ((this.collisionRectX + this.collisionRectWidth) > this.width) { sx2 = this.x + this.width; }\n\t\t\tif ((this.collisionRectY + this.collisionRectHeight) > this.height) { sy2 = this.y + this.height; }'''

new_clip = '''\t\t\tif (thisCollision[0] < 0) { sx1 = this.x; }\n\t\t\tif (thisCollision[1] < 0) { sy1 = this.y; }\n\t\t\tif ((thisCollision[0] + thisCollision[2]) > this.width) { sx2 = this.x + this.width; }\n\t\t\tif ((thisCollision[1] + thisCollision[3]) > this.height) { sy2 = this.y + this.height; }'''

if s.count(old_clip) != 1:
    raise SystemExit('DP_R10_TILE_COLLISION_RECT_PATCH=FAIL_CLIP_ANCHOR count=%d' % s.count(old_clip))
s = s.replace(old_clip, new_clip, 1)

p.write_text(s)
post = p.read_text()
if 'DP-R10 PRIMARY VARIABLE:' not in post:
    raise SystemExit('DP_R10_TILE_COLLISION_RECT_PATCH=FAIL_POSTMARKER')

print('DP_R10_TILE_COLLISION_RECT_PATCH=PASS')
print('DP_R10_PRIMARY_VARIABLE=SPRITE_VS_TILEDLAYER_TRANSFORMED_COLLISION_RECT_ONLY')
