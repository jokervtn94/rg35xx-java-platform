#!/usr/bin/env python3
from pathlib import Path

p = Path('upstream/src/javax/microedition/lcdui/game/Sprite.java')
s = p.read_text()

start_marker = '\tprivate static boolean checkPixCollision('
end_marker = '\tprivate int getImageTopLeft('

start = s.find(start_marker)
end = s.find(end_marker)

if start < 0 or end < 0 or end <= start:
    raise SystemExit('DP_R7_COLLISION_CORE_PATCH=FAIL_BOUNDARY')

old = s[start:end]

# Fail closed: make sure this is the known pre-r93d helper set.
required = [
    'getARGBData(image1',
    'getARGBData(image2',
    'getSpriteIncrAndStartPos(transform1, width',
    'private static int[] getARGBData('
]
for token in required:
    if token not in old:
        raise SystemExit('DP_R7_COLLISION_CORE_PATCH=FAIL_EXPECTED_PREIMAGE:' + token)

new = '''\tprivate static boolean checkPixCollision(int image1XOffset,
\t\tint image1YOffset, int image2XOffset, int image2YOffset,
\t\tImage image1, int transform1, Image image2, int transform2,int width,
\t\tint height)
\t{
\t\t// DP-R7 PRIMARY VARIABLE:
\t\t// Backport transformed per-pixel collision core from upstream
\t\t// FreeJ2ME-Plus commit 93d866ef7836b4aa6be89d58e1919bcc05c9bb3f.
\t\tint numPixels = width * height;
\t\tint[] argbData1 = new int[numPixels];
\t\tint[] argbData2 = new int[numPixels];

\t\tfinal int[] data1Pos = getSpriteIncrAndStartPos(transform1, width,
\t\t\theight, numPixels);

\t\tfinal int[] data2Pos = getSpriteIncrAndStartPos(transform2, width,
\t\t\theight, numPixels);

\t\timage1.getRGB(argbData1, 0, data1Pos[3], image1XOffset, image1YOffset, data1Pos[3], data1Pos[4]);
\t\timage2.getRGB(argbData2, 0, data2Pos[3], image2XOffset, image2YOffset, data2Pos[3], data2Pos[4]);

\t\tint row1 = data1Pos[0];
\t\tint row2 = data2Pos[0];

\t\tint x1, x2, alpha1, alpha2;
\t\tfor (int row = 0; row < height; row++)
\t\t{
\t\t\tx1 = row1;
\t\t\tx2 = row2;
\t\t\tfor (int col = 0; col < width; col++)
\t\t\t{
\t\t\t\talpha1 = (argbData1[x1] >> 24) & 0xFF;
\t\t\t\talpha2 = (argbData2[x2] >> 24) & 0xFF;
\t\t\t\tif ((alpha1 == 0xFF) && (alpha2 == 0xFF))
\t\t\t\t\treturn true;

\t\t\t\tx1 += data1Pos[1];
\t\t\t\tx2 += data2Pos[1];
\t\t\t}

\t\t\trow1 += data1Pos[2];
\t\t\trow2 += data2Pos[2];
\t\t}

\t\treturn false;
\t}

\tprivate static int[] getSpriteIncrAndStartPos(int transform, int width, int height, int numPixels)
\t{
\t\tboolean is90 = (transform & 0x4) != 0;
\t\tboolean isRot180 = (transform & 0x1) != 0;
\t\tboolean isMirrorX = (transform & 0x2) != 0;

\t\tint stride = is90 ? height : width;
\t\tif (is90) { height = width; }

\t\tint xIncr = is90 ? (isRot180 ? -stride : stride) : (isMirrorX ? -1 : 1);
\t\tint yIncr = is90 ? (isMirrorX ? -1 : 1) : (isRot180 ? -stride : stride);

\t\tint startY = 0;
\t\tif (isRot180) { startY += numPixels - stride; }
\t\tif (isMirrorX) { startY += stride - 1; }

\t\treturn new int[] { startY, xIncr, yIncr, stride, height };
\t}

'''

p.write_text(s[:start] + new + s[end:])

post = p.read_text()
if 'DP-R7 PRIMARY VARIABLE:' not in post:
    raise SystemExit('DP_R7_COLLISION_CORE_PATCH=FAIL_POSTMARKER')
if 'private static int[] getARGBData(' in post:
    raise SystemExit('DP_R7_COLLISION_CORE_PATCH=FAIL_OLD_HELPER_REMAINS')

print('DP_R7_COLLISION_CORE_PATCH=PASS')
print('DP_R7_PRIMARY_VARIABLE=SPRITE_TRANSFORM_PIXEL_COLLISION_CORE_ONLY')
print('DP_R7_UPSTREAM_REFERENCE=93d866ef7836b4aa6be89d58e1919bcc05c9bb3f')
