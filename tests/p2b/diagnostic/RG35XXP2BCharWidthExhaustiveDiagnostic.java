import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.BufferedOutputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;

/** Diagnostic only. Emits the pinned JDK8/AWT charWidth/canDisplay table for
 * every UTF-16 code unit at MIDP sizes 12/14/16, and proves whether styles
 * change layout width. */
public final class RG35XXP2BCharWidthExhaustiveDiagnostic {
    public static void main(String[] args) throws Exception {
        if (args.length != 2) throw new IllegalArgumentException("usage: <font.ttf> <out.bin>");
        Font root = Font.createFont(Font.TRUETYPE_FONT, new File(args[0])).deriveFont(Font.PLAIN, 12f);
        int[] sizes = new int[] {12,14,16};
        DataOutputStream out = new DataOutputStream(new BufferedOutputStream(new FileOutputStream(args[1])));
        long styleMismatch = 0;
        long styleCases = 0;
        long displayCount = 0;
        System.out.println("P2B_JDK_CHARWIDTH_BOOT=PASS");
        for (int zi=0; zi<sizes.length; zi++) {
            int size = sizes[zi];
            Font[] fonts = new Font[8];
            FontMetrics[] fm = new FontMetrics[8];
            Graphics2D[] gs = new Graphics2D[8];
            for (int style=0; style<8; style++) {
                fonts[style] = root.deriveFont(style, (float)size);
                BufferedImage bi = new BufferedImage(1,1,BufferedImage.TYPE_INT_ARGB);
                gs[style] = bi.createGraphics();
                gs[style].setFont(fonts[style]);
                fm[style] = gs[style].getFontMetrics();
            }
            long sizeMismatch = 0;
            for (int cp=0; cp<=0xffff; cp++) {
                char ch = (char)cp;
                int width = fm[0].charWidth(ch);
                boolean display = fonts[0].canDisplay(ch);
                if (width < -32768 || width > 32767) throw new IllegalStateException("width out of range cp="+cp+" width="+width);
                out.writeShort(width);
                out.writeByte(display ? 1 : 0);
                if (display) displayCount++;
                for (int style=1; style<8; style++) {
                    styleCases++;
                    if (fm[style].charWidth(ch) != width) {
                        styleMismatch++;
                        sizeMismatch++;
                    }
                }
            }
            for (int style=0; style<8; style++) gs[style].dispose();
            System.out.println("P2B_JDK_CHARWIDTH_SIZE="+size+" STYLE_WIDTH_MISMATCHES="+sizeMismatch);
        }
        out.close();
        System.out.println("P2B_JDK_CHARWIDTH_TABLE_CASES="+(65536L*3L));
        System.out.println("P2B_JDK_CHARWIDTH_DISPLAYABLE_COUNT="+displayCount);
        System.out.println("P2B_JDK_CHARWIDTH_STYLE_COMPARE_CASES="+styleCases);
        System.out.println("P2B_JDK_CHARWIDTH_STYLE_MISMATCHES="+styleMismatch);
        System.out.println("P2B_JDK_CHARWIDTH_RESULT=PASS");
    }
}
