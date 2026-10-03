import java.awt.Font;
import java.awt.font.FontRenderContext;
import java.awt.font.TextLayout;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import org.recompile.rg35xx.p2b.jdk8.font.BidiUtils;
import org.recompile.rg35xx.p2b.jdk8.font.ScriptRun;
import org.recompile.rg35xx.p2b.jdk8.text.Bidi;

/**
 * Audit-only field-by-field differential for the generic TextLayout fast-path
 * planner. The local side is composed only from the already source-derived JDK8
 * Bidi, BidiUtils and ScriptRun primitives. It does not shape or rasterize and
 * is not production/runtime code.
 */
public final class RG35XXP2BJdkTextPlannerDifferential {
    private static final String[] FIXED = new String[] {
        "ABC xyz 123",
        "Tie\u0302\u0301ng Vie\u0323\u0302t",
        "سلام",
        "שלום",
        "नमस्ते",
        "ภาษาไทย",
        "漢かなカナ",
        "A(Б)Γ",
        "abc שלום 123",
        "שלום abc",
        "abc العربية 123 עברית",
        "123 אבג 456 العربية XYZ",
        "(abc) [שלום] <سلام>",
        "(A[שלום]ب)",
        "\u202Aabc שלום 123\u202C",
        "\u202BABC 123 שלום\u202C",
        "\u202EABC 123\u202C",
        "\u200Fשלום\u200EABC",
        "A\u200Dسلام",
        "A\u200Cسلام",
        "A\uD800\uDF48B",
        "A\uD83D\uDE00שלום",
        "A\u0301 Б\u0301 α\u0301 नमस्ते",
        "Latin العربية Devanagari नमस्ते Hebrew שלום 123"
    };

    private static final class RunRec {
        int start, limit, script, engineFlags;
        public String toString() {
            return start + ":" + limit + ":" + script + ":" + engineFlags;
        }
    }

    private static final class CompRec {
        int start, length, level, flags;
        List runs = new ArrayList();
        public String toString() {
            return start + ":" + length + ":" + level + ":" + flags + ":" + runs;
        }
    }

    private static final class Plan {
        boolean lineLtr;
        byte[] levels;
        int[] l2v;
        int[] componentVisualOrder;
        List components = new ArrayList();
        public String toString() {
            return "lineLtr=" + lineLtr + " levels=" + bytes(levels) +
                   " l2v=" + ints(l2v) + " order=" + ints(componentVisualOrder) +
                   " comps=" + components;
        }
    }

    private static Field findField(Class c, String name) throws Exception {
        for (Class k=c; k!=null; k=k.getSuperclass()) {
            try {
                Field f=k.getDeclaredField(name); f.setAccessible(true); return f;
            } catch (NoSuchFieldException e) { }
        }
        throw new NoSuchFieldException(c.getName()+"."+name);
    }

    private static Method findMethod(Class c, String name, Class[] sig) throws Exception {
        for (Class k=c; k!=null; k=k.getSuperclass()) {
            try {
                Method m=k.getDeclaredMethod(name,sig); m.setAccessible(true); return m;
            } catch (NoSuchMethodException e) { }
        }
        throw new NoSuchMethodException(c.getName()+"."+name);
    }

    private static String bytes(byte[] a) {
        if(a==null) return "-";
        StringBuffer b=new StringBuffer();
        for(int i=0;i<a.length;i++){if(i!=0)b.append(',');b.append(a[i]&0xff);} return b.toString();
    }

    private static String ints(int[] a) {
        if(a==null) return "-";
        StringBuffer b=new StringBuffer();
        for(int i=0;i<a.length;i++){if(i!=0)b.append(',');b.append(a[i]);} return b.toString();
    }

    private static int engineFlags(char[] chars, int start, int limit) {
        for(int i=start;i<limit;i++) {
            int ch=chars[i];
            if(Character.isHighSurrogate((char)ch) && i<limit-1 && Character.isLowSurrogate(chars[i+1])) {
                ch=Character.toCodePoint((char)ch,chars[++i]);
            }
            int gc=Character.getType(ch);
            if(gc==Character.NON_SPACING_MARK || gc==Character.ENCLOSING_MARK || gc==Character.COMBINING_SPACING_MARK) return 0x4;
        }
        return 0;
    }

    private static List localScriptRuns(char[] chars,int start,int count) {
        List out=new ArrayList();
        ScriptRun sr=new ScriptRun(chars,start,count);
        while(sr.next()) {
            RunRec r=new RunRec();
            r.start=sr.getScriptStart(); r.limit=sr.getScriptLimit(); r.script=sr.getScriptCode();
            r.engineFlags=engineFlags(chars,r.start,r.limit);
            out.add(r);
        }
        return out;
    }

    private static List refScriptRuns(char[] chars,int start,int count) throws Exception {
        Class sr=Class.forName("sun.font.ScriptRun");
        Constructor ctor=sr.getConstructor(new Class[]{char[].class,Integer.TYPE,Integer.TYPE});
        Object it=ctor.newInstance(new Object[]{chars,Integer.valueOf(start),Integer.valueOf(count)});
        Method next=sr.getMethod("next",new Class[0]);
        Method gs=sr.getMethod("getScriptStart",new Class[0]);
        Method gl=sr.getMethod("getScriptLimit",new Class[0]);
        Method gc=sr.getMethod("getScriptCode",new Class[0]);
        List out=new ArrayList();
        while(((Boolean)next.invoke(it,new Object[0])).booleanValue()) {
            RunRec r=new RunRec();
            r.start=((Integer)gs.invoke(it,new Object[0])).intValue();
            r.limit=((Integer)gl.invoke(it,new Object[0])).intValue();
            r.script=((Integer)gc.invoke(it,new Object[0])).intValue();
            r.engineFlags=engineFlags(chars,r.start,r.limit);
            out.add(r);
        }
        return out;
    }

    private static Plan reference(Font font, FontRenderContext frc, String text) throws Exception {
        char[] chars=text.toCharArray();
        TextLayout tl=new TextLayout(text,font,frc);
        Object line=findField(TextLayout.class,"textLine").get(tl);
        Object[] comps=(Object[])findField(line.getClass(),"fComponents").get(line);
        Plan p=new Plan();
        p.lineLtr=((Boolean)findField(line.getClass(),"fIsDirectionLTR").get(line)).booleanValue();
        p.levels=(byte[])findField(line.getClass(),"fCharLevels").get(line);
        p.l2v=(int[])findField(line.getClass(),"fCharLogicalOrder").get(line);
        p.componentVisualOrder=(int[])findField(line.getClass(),"fComponentVisualOrder").get(line);
        for(int i=0;i<comps.length;i++) {
            Object source=findField(comps[i].getClass(),"source").get(comps[i]);
            Method getStart=findMethod(source.getClass(),"getStart",new Class[0]);
            Method getLength=findMethod(source.getClass(),"getLength",new Class[0]);
            Method getFlags=findMethod(source.getClass(),"getLayoutFlags",new Class[0]);
            Method getLevel=findMethod(source.getClass(),"getBidiLevel",new Class[0]);
            CompRec c=new CompRec();
            c.start=((Integer)getStart.invoke(source,new Object[0])).intValue();
            c.length=((Integer)getLength.invoke(source,new Object[0])).intValue();
            c.flags=((Integer)getFlags.invoke(source,new Object[0])).intValue();
            c.level=((Integer)getLevel.invoke(source,new Object[0])).intValue();
            c.runs=refScriptRuns(chars,c.start,c.length);
            p.components.add(c);
        }
        return p;
    }

    private static int firstVisualChunk(int[] order,byte[] direction,int start,int limit) {
        if(order!=null && direction!=null) {
            byte dir=direction[start];
            while(++start<limit && direction[start]==dir) { }
            return start;
        }
        return limit;
    }

    private static Plan local(String text) {
        char[] chars=text.toCharArray();
        Plan p=new Plan();
        p.lineLtr=true;
        Bidi bidi=null;
        if(Bidi.requiresBidi(chars,0,chars.length)) {
            bidi=new Bidi(chars,0,null,0,chars.length,Bidi.DIRECTION_DEFAULT_LEFT_TO_RIGHT);
            if(!bidi.isLeftToRight()) {
                p.levels=BidiUtils.getLevels(bidi);
                int[] v2l=BidiUtils.createVisualToLogicalMap(p.levels);
                p.l2v=BidiUtils.createInverseMap(v2l);
                p.lineLtr=bidi.baseIsLeftToRight();
            }
        }

        int pos=0;
        if(chars.length>0) {
            do {
                int lim=firstVisualChunk(p.l2v,p.levels,pos,chars.length);
                CompRec c=new CompRec();
                c.start=pos; c.length=lim-pos;
                c.level=bidi==null?0:bidi.getLevelAt(pos);
                int linedir=(bidi==null || bidi.baseIsLeftToRight())?0:1;
                c.flags=0;
                if((c.level&1)!=0)c.flags|=1;
                if((linedir&1)!=0)c.flags|=8;
                c.runs=localScriptRuns(chars,c.start,c.length);
                p.components.add(c);
                pos=lim;
            } while(pos<chars.length);
        }

        if(p.l2v!=null && p.components.size()>1) {
            int[] values=new int[p.components.size()];
            int gStart=0;
            for(int i=0;i<values.length;i++) {
                values[i]=p.l2v[gStart];
                gStart+=((CompRec)p.components.get(i)).length;
            }
            p.componentVisualOrder=BidiUtils.createContiguousOrder(values);
            p.componentVisualOrder=BidiUtils.createInverseMap(p.componentVisualOrder);
        }
        return p;
    }

    private static boolean sameBytes(byte[] a,byte[] b) {
        if(a==b)return true;if(a==null||b==null||a.length!=b.length)return false;
        for(int i=0;i<a.length;i++)if(a[i]!=b[i])return false;return true;
    }
    private static boolean sameInts(int[] a,int[] b) {
        if(a==b)return true;if(a==null||b==null||a.length!=b.length)return false;
        for(int i=0;i<a.length;i++)if(a[i]!=b[i])return false;return true;
    }
    private static boolean sameRuns(List a,List b) {
        if(a.size()!=b.size())return false;
        for(int i=0;i<a.size();i++) {
            RunRec x=(RunRec)a.get(i),y=(RunRec)b.get(i);
            if(x.start!=y.start||x.limit!=y.limit||x.script!=y.script||x.engineFlags!=y.engineFlags)return false;
        }
        return true;
    }
    private static boolean samePlan(Plan a,Plan b) {
        if(a.lineLtr!=b.lineLtr||!sameBytes(a.levels,b.levels)||!sameInts(a.l2v,b.l2v)||!sameInts(a.componentVisualOrder,b.componentVisualOrder)||a.components.size()!=b.components.size())return false;
        for(int i=0;i<a.components.size();i++) {
            CompRec x=(CompRec)a.components.get(i),y=(CompRec)b.components.get(i);
            if(x.start!=y.start||x.length!=y.length||x.level!=y.level||x.flags!=y.flags||!sameRuns(x.runs,y.runs))return false;
        }
        return true;
    }

    private static int cases=0,mismatches=0,totalComponents=0,totalRuns=0,multiComponents=0,mixedBidi=0,rtlComponents=0,visualReordered=0,multiScript=0,combiningRuns=0;
    private static void check(Font font,FontRenderContext frc,String label,String text) throws Exception {
        Plan ref=reference(font,frc,text), loc=local(text); cases++;
        totalComponents+=loc.components.size(); if(loc.components.size()>1)multiComponents++;
        if(loc.componentVisualOrder!=null)visualReordered++;
        if(loc.levels!=null && loc.levels.length>0) {
            byte x=loc.levels[0]; boolean mixed=false;
            for(int i=1;i<loc.levels.length;i++)if(loc.levels[i]!=x){mixed=true;break;} if(mixed)mixedBidi++;
        }
        int caseRuns=0;
        for(int i=0;i<loc.components.size();i++) {
            CompRec c=(CompRec)loc.components.get(i); if((c.flags&1)!=0)rtlComponents++;
            caseRuns+=c.runs.size(); totalRuns+=c.runs.size();
            for(int j=0;j<c.runs.size();j++)if((((RunRec)c.runs.get(j)).engineFlags&4)!=0)combiningRuns++;
        }
        if(caseRuns>1)multiScript++;
        if(!samePlan(ref,loc)) {
            mismatches++;
            if(mismatches<=12) {
                System.out.println("PLAN_MISMATCH="+label);
                System.out.println("REF="+ref);
                System.out.println("LOC="+loc);
            }
        }
    }

    private static int next(int x){return x*1103515245+12345;}

    public static void main(String[] args) throws Exception {
        if(args.length!=1)throw new IllegalArgumentException("usage: <font.ttf>");
        Font font=Font.createFont(Font.TRUETYPE_FONT,new java.io.File(args[0])).deriveFont(Font.PLAIN,14.0f);
        FontRenderContext frc=new FontRenderContext(null,false,false);

        for(int i=0;i<FIXED.length;i++)check(font,frc,"fixed-"+i,FIXED[i]);

        String[] tok=new String[]{
            "A","z","0","1"," ",".",",","\u0301","א","ש","ם","س","ل","م","ك","क","्","त","ग","า","ก","中","文","あ","ア","α","Я",
            "(",")","[","]","<",">","\u200C","\u200D","\u200E","\u200F","\u202A","\u202B","\u202C","\u202D","\u202E","\uD800\uDF48","\uD83D\uDE00"
        };
        int state=0x51a7c3d9;
        for(int q=0;q<2048;q++) {
            state=next(state);int parts=1+((state>>>1)&31);StringBuffer b=new StringBuffer();
            for(int j=0;j<parts;j++){state=next(state);b.append(tok[(state>>>1)%tok.length]);}
            check(font,frc,"rnd-"+q,b.toString());
        }

        System.out.println("P2B_TEXT_PLANNER_DIFF_CASES="+cases);
        System.out.println("P2B_TEXT_PLANNER_DIFF_TOTAL_COMPONENTS="+totalComponents);
        System.out.println("P2B_TEXT_PLANNER_DIFF_TOTAL_SCRIPT_RUNS="+totalRuns);
        System.out.println("P2B_TEXT_PLANNER_DIFF_MULTI_COMPONENT_CASES="+multiComponents);
        System.out.println("P2B_TEXT_PLANNER_DIFF_MIXED_BIDI_CASES="+mixedBidi);
        System.out.println("P2B_TEXT_PLANNER_DIFF_RTL_COMPONENTS="+rtlComponents);
        System.out.println("P2B_TEXT_PLANNER_DIFF_VISUAL_REORDERED_CASES="+visualReordered);
        System.out.println("P2B_TEXT_PLANNER_DIFF_MULTI_SCRIPT_CASES="+multiScript);
        System.out.println("P2B_TEXT_PLANNER_DIFF_COMBINING_RUNS="+combiningRuns);
        System.out.println("P2B_TEXT_PLANNER_DIFF_MISMATCH_COUNT="+mismatches);
        if(multiComponents<=0||mixedBidi<=0||rtlComponents<=0||visualReordered<=0||multiScript<=0||combiningRuns<=0)throw new RuntimeException("planner coverage incomplete");
        if(mismatches!=0)throw new RuntimeException("planner mismatch="+mismatches);
        System.out.println("P2B_TEXT_PLANNER_COMPONENT_PLAN_DIFFERENTIAL=PASS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
        System.out.println("P2B_DEVICE_PACKAGE=FORBIDDEN");
    }
}
