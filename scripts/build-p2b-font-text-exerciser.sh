#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail(){ echo "P2B_EXERCISER_BUILD_FAIL=$*" >&2; exit 1; }

JAVA8="${JAVA8:-${JAVA_HOME:-}}"
[ -n "$JAVA8" ] || fail "JAVA8/JAVA_HOME not set"
for t in javac java jar; do [ -x "$JAVA8/bin/$t" ] || fail "$t missing"; done

OUT="$ROOT/out/p2b-font-text-candidate-r1"
PLATFORM="$OUT/freej2me-rg35xx.jar"
FONT="$ROOT/build/a3/p2b-font-text-r1/font.ttf"
SRC="$ROOT/tests/p2b/exerciser/RG35XXP2BFontTextExerciser.java"
BUILD="$ROOT/build/p2b-font-text-exerciser"
RES="$BUILD/resources"
EXPECTED="$RES/p2b/expected.tsv"
JAROUT="$OUT/RG35XX-Platform-Exerciser-P2B-FontText.jar"
IDENTITY="$OUT/P2B-FONT-TEXT-EXERCISER-IDENTITY.txt"
FONT_SHA=1a5f4112daaa9473747c6834041646cc9b2c338cb40ab5dbb2f0161f8968ca10
FONT_SIZE=8092724

[ -f "$PLATFORM" ] || fail "P2B candidate platform jar missing"
[ -f "$FONT" ] || fail "exact staged font missing"
[ -f "$SRC" ] || fail "exerciser source missing"
[ "$(sha256sum "$FONT" | awk '{print $1}')" = "$FONT_SHA" ] || fail "font sha"
[ "$(wc -c < "$FONT" | tr -d ' ')" = "$FONT_SIZE" ] || fail "font size"
rm -rf "$BUILD"
mkdir -p "$BUILD/classes" "$BUILD/host" "$RES/p2b"

cat > "$BUILD/P2BExpectedGenerator.java" <<'JAVA'
import java.awt.Color;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.PrintWriter;

public final class P2BExpectedGenerator {
    private static final int W=320,H=128;
    private static final int[] POINTS={12,14,16};
    private static final int[] STYLES={0,1,2,3,4};
    private static final String[] STRINGS={
        "ABCxyz09","Tiếng Việt","Đặng","中文","A\u0301","\u0644\u0627"
    };
    private static final int[] ANCHORS={20,68,36,3};

    private static boolean white(int p){ return (p & 0x00ffffff)==0x00ffffff; }
    private static int inkCount(int[] p){
        int n=0; for(int i=0;i<p.length;i++) if(!white(p[i])) n++; return n;
    }
    private static int hash1(int[] p){
        int h=0x13579BDF;
        for(int i=0;i<p.length;i++) h=h*33+(white(p[i])?0:1);
        return h;
    }
    private static int hash2(int[] p){
        int h=0x2468ACE0;
        for(int i=0;i<p.length;i++) h=h*65599+(white(p[i])?0:(i+1));
        return h;
    }
    private static String hex(int v){
        String s=Integer.toHexString(v); StringBuffer b=new StringBuffer(8);
        for(int i=s.length();i<8;i++) b.append('0'); b.append(s); return b.toString();
    }
    private static void anchor(FontMetrics fm, String s, int anchor, int[] xy){
        int x=xy[0], y=xy[1], total=fm.stringWidth(s);
        if((anchor&8)>0) x-=total;
        else if((anchor&1)>0) x-=total/2;
        if((anchor&32)>0) y-=fm.getDescent();
        else if((anchor&2)>0) y-=(fm.getDescent()+fm.getAscent())/2;
        else if((anchor&64)==0) y+=fm.getAscent();
        xy[0]=x; xy[1]=y;
    }
    public static void main(String[] a) throws Exception {
        if(a.length!=2) throw new IllegalArgumentException("font out");
        Font loaded=Font.createFont(Font.TRUETYPE_FONT,new File(a[0]));
        Font global=loaded.deriveFont(Font.PLAIN,12f);
        PrintWriter out=new PrintWriter(a[1],"UTF-8");
        out.println("# PINNED_JDK8_AWT_EXACT_MISANS MASK_EXPECTED");
        int ci=0;
        for(int zi=0;zi<POINTS.length;zi++) for(int si=0;si<STYLES.length;si++){
            Font f=global.deriveFont(STYLES[si],(float)POINTS[zi]);
            BufferedImage metricImage=new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
            Graphics2D mg=metricImage.createGraphics(); mg.setFont(f);
            FontMetrics fm=mg.getFontMetrics();
            for(int qi=0;qi<STRINGS.length;qi++) for(int ai=0;ai<ANCHORS.length;ai++){
                String s=STRINGS[qi]; int anchor=ANCHORS[ai];
                BufferedImage bi=new BufferedImage(W,H,BufferedImage.TYPE_INT_ARGB);
                Graphics2D g=bi.createGraphics();
                g.setColor(Color.WHITE); g.fillRect(0,0,W,H);
                g.setColor(Color.BLACK); g.setFont(f);
                int x=(anchor&1)!=0?W/2:24;
                int y=(anchor&2)!=0?H/2:((anchor&32)!=0?104:((anchor&64)!=0?72:20));
                int[] xy={x,y}; anchor(fm,s,anchor,xy);
                g.drawString(s,xy[0],xy[1]); g.dispose();
                int[] p=bi.getRGB(0,0,W,H,null,0,W);
                out.println(ci+"\t"+fm.getHeight()+"\t"+POINTS[zi]+"\t"+fm.stringWidth(s)+
                    "\t"+fm.charWidth('A')+"\t"+fm.charWidth('\u4e2d')+"\t"+inkCount(p)+
                    "\t"+hex(hash1(p))+"\t"+hex(hash2(p)));
                ci++;
            }
            mg.dispose();
        }
        out.close();
        if(ci!=360) throw new RuntimeException("case count "+ci);
        System.out.println("P2B_EXERCISER_JDK8_EXPECTED_CASES="+ci);
        System.out.println("P2B_EXERCISER_JDK8_EXPECTED=PASS");
    }
}
JAVA

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -d "$BUILD/host" "$BUILD/P2BExpectedGenerator.java"
"$JAVA8/bin/java" -Djava.awt.headless=true -cp "$BUILD/host" P2BExpectedGenerator "$FONT" "$EXPECTED"
[ "$(grep -vc '^#' "$EXPECTED")" -eq 360 ] || fail "JDK8 expected row count"
EXPECTED_SHA="$(sha256sum "$EXPECTED" | awk '{print $1}')"
echo P2B_EXERCISER_EXPECTED_TABLE_SHA256="$EXPECTED_SHA"

"$JAVA8/bin/javac" -encoding UTF-8 -source 1.6 -target 1.6 \
  -bootclasspath "$JAVA8/jre/lib/rt.jar" -classpath "$PLATFORM" \
  -d "$BUILD/classes" "$SRC"

cat > "$BUILD/MANIFEST.MF" <<'EOF_MANIFEST'
Manifest-Version: 1.0
MIDlet-Name: RG35XX P2B Font Text Exerciser
MIDlet-Version: 1.0.0
MIDlet-Vendor: RG35XX Platform Reconstruction
MIDlet-1: RG35XX P2B Font Text Exerciser,,RG35XXP2BFontTextExerciser
MicroEdition-Configuration: CLDC-1.0
MicroEdition-Profile: MIDP-2.0
EOF_MANIFEST

rm -f "$JAROUT"
"$JAVA8/bin/jar" cfm "$JAROUT" "$BUILD/MANIFEST.MF" -C "$BUILD/classes" . -C "$RES" p2b

python3 - "$JAROUT" <<'PY'
import sys,zipfile
jar=sys.argv[1]
required={
 'RG35XXP2BFontTextExerciser.class',
 'RG35XXP2BFontTextExerciser$P2BCanvas.class',
 'META-INF/MANIFEST.MF',
 'p2b/expected.tsv',
}
majors=set()
with zipfile.ZipFile(jar) as z:
    names=set(z.namelist()); missing=required-names
    if missing: raise SystemExit('P2B_EXERCISER_JAR_GATE_FAIL missing='+repr(sorted(missing)))
    classes=sorted(n for n in names if n.endswith('.class'))
    expected_classes=['RG35XXP2BFontTextExerciser$P2BCanvas.class','RG35XXP2BFontTextExerciser.class']
    if classes!=expected_classes: raise SystemExit('P2B_EXERCISER_JAR_GATE_FAIL classes='+repr(classes))
    blob=b''.join(z.read(n) for n in classes)
    for marker in (b'P2B_EXERCISER_BOOT=PASS',b'P2B_EXERCISER_RESULT=',b'P2B_EXERCISER_CASE_COUNT=',b'P2B_EXERCISER_EXPECTED_TABLE=PASS'):
        if marker not in blob: raise SystemExit('P2B_EXERCISER_MARKER_GATE_FAIL '+repr(marker))
    for forbidden in (b'RG35XXCore2D',b'java/awt',b'fontRasterNative'):
        if forbidden in blob: raise SystemExit('P2B_EXERCISER_OWNER_BYPASS_FORBIDDEN '+repr(forbidden))
    for n in classes:
        b=z.read(n)
        if b[:4]!=b'\xca\xfe\xba\xbe': raise SystemExit('bad class magic '+n)
        major=int.from_bytes(b[6:8],'big'); majors.add(major)
        if major>50: raise SystemExit('P2B_EXERCISER_JAVA6_FAIL %s major=%d'%(n,major))
print('P2B_EXERCISER_CLASS_MAJORS='+','.join(map(str,sorted(majors))))
print('P2B_EXERCISER_JAVA6_GATE=PASS')
print('P2B_EXERCISER_PUBLIC_MIDP_ONLY=YES')
print('P2B_EXERCISER_DIRECT_BACKEND_CALL=NO')
PY

EX_SHA="$(sha256sum "$JAROUT" | awk '{print $1}')"
cat > "$IDENTITY" <<EOF_ID
PROJECT=RG35XX-AWEIGIT-R1
MODULE=P2B_FONT_TEXT
ARTIFACT=RG35XX-Platform-Exerciser-P2B-FontText.jar
SOURCE=tests/p2b/exerciser/RG35XXP2BFontTextExerciser.java
CANONICAL_EXPECTED_SOURCE=PINNED_JDK8_AWT
EXPECTED_FONT_SHA256=$FONT_SHA
EXPECTED_FONT_SIZE=$FONT_SIZE
EXPECTED_TABLE_SHA256=$EXPECTED_SHA
METRIC_AND_RASTER_CASE_COUNT=360
SIZE_SET=SMALL,MEDIUM,LARGE
STYLE_SET=PLAIN,BOLD,ITALIC,BOLD_ITALIC,UNDERLINED
STRING_SET=ASCII,VIETNAMESE,CJK,COMBINING,ARABIC_LIGATURE
ANCHOR_SET=TOP_LEFT,BASELINE_LEFT,BOTTOM_LEFT,VCENTER_HCENTER
PUBLIC_MIDP_FONT_API=YES
PUBLIC_MIDP_GRAPHICS_API=YES
PUBLIC_MIDP_IMAGE_GETRGB=YES
DIRECT_RG35XXCORE2D_CALL=NO
COMMERCIAL_GAME_CONTENT=NO
GAME_SPECIFIC_CODE=NO
A9_PARENT=NO
EXERCISER_SHA256=$EX_SHA
P2B_PHYSICAL_TEST=NOT_TESTED
DEVICE_PASS=NO
STABLE=NO
EOF_ID
echo "P2B_EXERCISER_SHA256=$EX_SHA"
echo P2B_EXERCISER_BUILD=PASS
cat "$IDENTITY"
