import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;

import org.recompile.rg35xx.p2b.jdk8.text.Bidi;
import org.recompile.rg35xx.p2b.jdk8.font.BidiUtils;
import org.recompile.rg35xx.p2b.jdk8.script.ScriptRun;
import org.recompile.rg35xx.p2b.jdk8.mark.Jdk8MarkClassifier;
import org.recompile.rg35xx.p2b.jdk8.normalizer.UTF16;

/**
 * Audit-only local reconstruction of the JDK8 TextLayout fast-path planner.
 *
 * Inputs are exact JDK8 reference rows. This diagnostic consumes only UTF-16
 * input and independently rebuilds Bidi levels/maps, TextLine component
 * boundaries/order, TextLabelFactory layout flags, ScriptRun records and the
 * GlyphLayout EngineRecord canonical-substitution flag. It does not use AWT,
 * a font, renderer output, device code, or corpus-specific expected plans.
 */
public final class RG35XXP2BLocalComponentPlanDiagnostic {
    private static final class Component {
        int start;
        int limit;
        int level;
        int flags;
        String runs;
        Component(int s,int l,int lv,int f,String r) {
            start=s; limit=l; level=lv; flags=f; runs=r;
        }
    }

    private static char[] parseUtf16(String s) {
        if ((s.length() & 3) != 0) throw new IllegalArgumentException("bad UTF16HEX length");
        char[] out=new char[s.length()/4];
        for(int i=0;i<out.length;i++) out[i]=(char)Integer.parseInt(s.substring(i*4,i*4+4),16);
        return out;
    }

    private static String bytes(byte[] a) {
        if(a==null) return "-";
        StringBuffer b=new StringBuffer();
        for(int i=0;i<a.length;i++){ if(i!=0)b.append(','); b.append(a[i]&0xff); }
        return b.toString();
    }

    private static String ints(int[] a) {
        if(a==null) return "-";
        StringBuffer b=new StringBuffer();
        for(int i=0;i<a.length;i++){ if(i!=0)b.append(','); b.append(a[i]); }
        return b.toString();
    }

    private static int firstVisualChunk(int[] order, byte[] direction, int start, int limit) {
        // Exact source-extraction of JDK8 TextLine.firstVisualChunk fast-path rule.
        if(order!=null && direction!=null) {
            byte dir=direction[start];
            while(++start<limit && direction[start]==dir) { }
            return start;
        }
        return limit;
    }

    private static boolean engineMark(char[] chars,int start,int limit) {
        // Exact semantic dependency of JDK8 GlyphLayout.EngineRecord.init: Mn/Me/Mc.
        // Supplementary assembly uses the same source-derived JDK8 UTF16 closure as Bidi,
        // so this planner has no hidden dependency on the host/protected java.lang.Character data.
        for(int i=start;i<limit;i++) {
            int cp=chars[i];
            if(UTF16.isLeadSurrogate((char)cp) && i<limit-1 && UTF16.isTrailSurrogate(chars[i+1])) {
                cp=UTF16.charAt(chars,start,limit,i-start);
                i++;
            }
            if(Jdk8MarkClassifier.isEngineMark(cp)) return true;
        }
        return false;
    }

    private static String scriptRuns(char[] chars,int start,int count) {
        ScriptRun sr=new ScriptRun(chars,start,count);
        StringBuffer b=new StringBuffer();
        int n=0;
        while(sr.next()) {
            int s=sr.getScriptStart();
            int l=sr.getScriptLimit();
            int c=sr.getScriptCode();
            int e=engineMark(chars,s,l)?4:0;
            if(n++!=0)b.append('|');
            b.append(s).append(':').append(l).append(':').append(c).append(':').append(e);
        }
        return b.toString();
    }

    private static String serializeComponents(List comps) {
        StringBuffer b=new StringBuffer();
        for(int i=0;i<comps.size();i++) {
            Component c=(Component)comps.get(i);
            if(i!=0)b.append(';');
            b.append(i).append(':').append(c.start).append(':').append(c.limit-c.start)
             .append(':').append(c.level).append(':').append(c.flags).append(':').append(c.runs);
        }
        return b.toString();
    }

    private static String[] plan(char[] chars) {
        Bidi bidi=null;
        byte[] levels=null;
        int[] l2v=null;
        boolean lineLtr=true;

        if(Bidi.requiresBidi(chars,0,chars.length)) {
            bidi=new Bidi(chars,0,null,0,chars.length,Bidi.DIRECTION_DEFAULT_LEFT_TO_RIGHT);
            if(!bidi.isLeftToRight()) {
                levels=BidiUtils.getLevels(bidi);
                int[] v2l=BidiUtils.createVisualToLogicalMap(levels);
                l2v=BidiUtils.createInverseMap(v2l);
                lineLtr=bidi.baseIsLeftToRight();
            }
        }

        List comps=new ArrayList();
        int pos=0;
        while(pos<chars.length) {
            int limit=firstVisualChunk(l2v,levels,pos,chars.length);
            int level=bidi==null?0:bidi.getLevelAt(pos);
            int linedir=(bidi==null || bidi.baseIsLeftToRight())?0:1;
            int flags=0;
            if((level&1)!=0) flags|=1;
            if((linedir&1)!=0) flags|=8;
            comps.add(new Component(pos,limit,level,flags,scriptRuns(chars,pos,limit-pos)));
            pos=limit;
        }

        int[] order=null;
        if(l2v!=null && comps.size()>1) {
            int[] componentOrder=new int[comps.size()];
            for(int i=0;i<comps.size();i++) {
                Component c=(Component)comps.get(i);
                componentOrder[i]=l2v[c.start];
            }
            componentOrder=BidiUtils.createContiguousOrder(componentOrder);
            order=BidiUtils.createInverseMap(componentOrder);
        }

        return new String[]{lineLtr?"1":"0",bytes(levels),ints(l2v),ints(order),serializeComponents(comps)};
    }

    private static int countComponents(String s) {
        if(s.length()==0) return 0;
        int n=1; for(int i=0;i<s.length();i++) if(s.charAt(i)==';') n++;
        return n;
    }

    private static int countScriptRuns(String s) {
        if(s.length()==0) return 0;
        int n=0;
        String[] comps=s.split(";",-1);
        for(int i=0;i<comps.length;i++) {
            int p=0;
            for(int colon=0;colon<5;colon++) { p=comps[i].indexOf(':',p); if(p<0) throw new IllegalArgumentException("bad component"); p++; }
            String r=comps[i].substring(p);
            if(r.length()>0) { n++; for(int j=0;j<r.length();j++) if(r.charAt(j)=='|') n++; }
        }
        return n;
    }

    public static void main(String[] args) throws Exception {
        if(args.length!=1) throw new IllegalArgumentException("usage: <reference.tsv>");
        BufferedReader in=new BufferedReader(new FileReader(args[0]));
        String header=in.readLine();
        if(!"CASE\tID\tUTF16HEX\tLINE_LTR\tLEVELS\tCHAR_L2V\tCOMPONENT_VISUAL_ORDER\tCOMPONENTS".equals(header)) {
            throw new IllegalArgumentException("unexpected reference header");
        }

        int cases=0,totalComponents=0,totalScriptRuns=0;
        int mismatch=0,lineMismatch=0,levelsMismatch=0,l2vMismatch=0,orderMismatch=0,componentsMismatch=0;
        String line;
        while((line=in.readLine())!=null) {
            if(line.length()==0) continue;
            String[] c=line.split("\t",-1);
            if(c.length!=8) throw new IllegalArgumentException("bad reference columns="+c.length);
            char[] chars=parseUtf16(c[2]);
            String[] p=plan(chars);
            String[] ref=new String[]{c[3],c[4],c[5],c[6],c[7]};
            boolean bad=false;
            for(int i=0;i<5;i++) {
                if(!ref[i].equals(p[i])) {
                    bad=true;
                    if(i==0) lineMismatch++;
                    else if(i==1) levelsMismatch++;
                    else if(i==2) l2vMismatch++;
                    else if(i==3) orderMismatch++;
                    else componentsMismatch++;
                }
            }
            if(bad) {
                mismatch++;
                if(mismatch<=12) {
                    System.out.println("PLAN_MISMATCH case="+c[0]+" id="+c[1]);
                    System.out.println("REF_LINE="+ref[0]+" REF_LEVELS="+ref[1]+" REF_L2V="+ref[2]+" REF_ORDER="+ref[3]+" REF_COMPONENTS="+ref[4]);
                    System.out.println("LOC_LINE="+p[0]+" LOC_LEVELS="+p[1]+" LOC_L2V="+p[2]+" LOC_ORDER="+p[3]+" LOC_COMPONENTS="+p[4]);
                }
            }
            totalComponents+=countComponents(p[4]);
            totalScriptRuns+=countScriptRuns(p[4]);
            cases++;
        }
        in.close();

        System.out.println("P2B_LOCAL_COMPONENT_PLAN_BOOT=PASS");
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_CASES="+cases);
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_TOTAL_COMPONENTS="+totalComponents);
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_SCRIPT_RUNS="+totalScriptRuns);
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_LINE_MISMATCH_COUNT="+lineMismatch);
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_LEVELS_MISMATCH_COUNT="+levelsMismatch);
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_L2V_MISMATCH_COUNT="+l2vMismatch);
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_ORDER_MISMATCH_COUNT="+orderMismatch);
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_COMPONENTS_MISMATCH_COUNT="+componentsMismatch);
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_MISMATCH_COUNT="+mismatch);
        if(cases!=24 || totalComponents!=52 || totalScriptRuns!=65 || mismatch!=0) {
            throw new RuntimeException("local component plan differential failed");
        }
        System.out.println("P2B_LOCAL_COMPONENT_PLAN_DIFFERENTIAL=PASS");
        System.out.println("P2B_PLANNER_FULL_LAYOUT_PLAN=PASS_FOR_EXPANDED_CORPUS");
        System.out.println("P2B_RUNTIME_PATCH=FORBIDDEN");
        System.out.println("P2B_DEVICE_PACKAGE=FORBIDDEN");
    }
}
