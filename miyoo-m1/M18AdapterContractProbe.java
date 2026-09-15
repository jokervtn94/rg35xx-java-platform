package org.recompile.mobile;

/** Build-time contract probe only; real MIDP callback validation remains a device gate. */
public final class M18AdapterContractProbe {
    private static void expect(int c, int key, String name) {
        int got=M18SemanticKeyAdapter.toMidpKey(c);
        if(got!=key) throw new RuntimeException(name+" expected="+key+" got="+got);
        System.out.println("M1_8_MAP_"+name+"="+got);
    }
    public static void main(String[] args) {
        expect(0,Mobile.KEY_NUM2,"UP"); expect(1,Mobile.KEY_NUM8,"DOWN");
        expect(2,Mobile.KEY_NUM4,"LEFT"); expect(3,Mobile.KEY_NUM6,"RIGHT");
        expect(4,Mobile.KEY_NUM5,"A"); expect(5,Mobile.KEY_NUM0,"B");
        expect(6,Mobile.KEY_NUM7,"X"); expect(7,Mobile.KEY_NUM9,"Y");
        expect(8,Mobile.NOKIA_SOFT1,"START"); expect(9,Mobile.NOKIA_SOFT2,"SELECT");
        expect(10,Mobile.KEY_STAR,"L"); expect(11,Mobile.KEY_POUND,"R");
        System.out.println("M1_8_ADAPTER_CONTRACT=PASS");
    }
}
