import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.Graphics2D;
import java.awt.font.FontRenderContext;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import java.io.File;

/** Audit-only probe for the exact default JDK8/AWT scaler context used by
 * the P2B reference diagnostics. No production ownership. */
public final class RG35XXP2BJdkScalerContextDiagnostic {
    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            throw new IllegalArgumentException("usage: <font.ttf>");
        }
        Font root = Font.createFont(Font.TRUETYPE_FONT, new File(args[0]))
                        .deriveFont(Font.PLAIN, 12f);
        BufferedImage bi = new BufferedImage(8, 8, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = bi.createGraphics();
        g.setFont(root);
        FontMetrics fm = g.getFontMetrics();
        FontRenderContext frc = fm.getFontRenderContext();
        AffineTransform tx = frc.getTransform();

        System.out.println("P2B_JDK_SCALER_CONTEXT_BOOT=PASS");
        System.out.println("P2B_JDK_SCALER_CONTEXT_AA=" + frc.isAntiAliased());
        System.out.println("P2B_JDK_SCALER_CONTEXT_FM=" + frc.usesFractionalMetrics());
        System.out.println("P2B_JDK_SCALER_CONTEXT_TX=" +
                tx.getScaleX() + "," + tx.getShearY() + "," +
                tx.getShearX() + "," + tx.getScaleY());
        System.out.println("P2B_JDK_SCALER_CONTEXT_FONT_STYLE=" + root.getStyle());
        System.out.println("P2B_JDK_SCALER_CONTEXT_FONT_SIZE=" + root.getSize());
        g.dispose();
        System.out.println("P2B_JDK_SCALER_CONTEXT_RESULT=PASS");
    }
}
