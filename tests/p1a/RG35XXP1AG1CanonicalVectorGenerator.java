package org.recompile.rg35xx.p1a;

/** Runs the shared P1A-G1 vectors through the non-Raw canonical/AWT path. */
public final class RG35XXP1AG1CanonicalVectorGenerator {
    private RG35XXP1AG1CanonicalVectorGenerator() { }

    public static void main(String[] args) {
        System.clearProperty("rg35xx.raw2d");
        for (int i = 0; i < RG35XXP1AG1Vectors.count(); i++) {
            int sum = RG35XXP1AG1Vectors.run(i);
            System.out.println(RG35XXP1AG1Vectors.NAMES[i] + "=" + Integer.toString(sum));
        }
        System.out.println("P1A_G1_CANONICAL_VECTOR_GENERATION=PASS");
    }
}
