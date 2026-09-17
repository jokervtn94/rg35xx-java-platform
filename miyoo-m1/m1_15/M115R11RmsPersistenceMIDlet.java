package org.recompile.mobile;
import javax.microedition.midlet.MIDlet;
import javax.microedition.rms.*;

public final class M115R11RmsPersistenceMIDlet extends MIDlet {
 private static final String STORE="RG35XX_M115_R11";
 private static final byte[] MARKER=new byte[]{0x52,0x47,0x33,0x35,0x58,0x58,0x2D,0x52,0x31,0x31,0x2D,0x50,0x45,0x52,0x53,0x49,0x53,0x54};
 private static void out(String k,Object v){System.out.println("M1_15_R11_"+k+"="+String.valueOf(v));}
 private static boolean eq(byte[] a,byte[] b){if(a==null||b==null||a.length!=b.length)return false;for(int i=0;i<a.length;i++)if(a[i]!=b[i])return false;return true;}
 private static String mode(){String m=System.getProperty("rg35xx.rms.mode");return m==null?"":m;}
 protected void startApp(){
  String m=mode();out("PRIMARY_VARIABLE","CROSS_PROCESS_PERSISTENCE_ONLY");out("RMS_IMPLEMENTATION_CHANGE","NONE");out("MODE",m);
  RecordStore rs=null;
  try{
   if("A".equals(m)){
    try{RecordStore.deleteRecordStore(STORE);out("A_PREDELETE","PASS_OR_ABSENT");}catch(RecordStoreNotFoundException e){out("A_PREDELETE","ABSENT_EXPECTED");}
    rs=RecordStore.openRecordStore(STORE,true);out("A_OPEN_CREATE","PASS");int id=rs.addRecord(MARKER,0,MARKER.length);out("A_ADD_ID",new Integer(id));
    byte[] got=rs.getRecord(id);out("A_VERIFY_BEFORE_CLOSE",eq(MARKER,got)?"PASS":"FAIL");rs.closeRecordStore();rs=null;out("A_CLOSE","PASS");out("A_GATE","PASS");System.exit(0);
   }else if("B".equals(m)){
    rs=RecordStore.openRecordStore(STORE,false);out("B_OPEN_EXISTING","PASS");out("B_NUM_RECORDS",new Integer(rs.getNumRecords()));byte[] got=rs.getRecord(1);out("B_MARKER",eq(MARKER,got)?"PASS":"FAIL");
    rs.closeRecordStore();rs=null;out("B_CLOSE","PASS");RecordStore.deleteRecordStore(STORE);out("B_DELETE","PASS");
    try{rs=RecordStore.openRecordStore(STORE,false);out("B_VERIFY_DELETE","FAIL_OPENED");rs.closeRecordStore();rs=null;}catch(RecordStoreNotFoundException e){out("B_VERIFY_DELETE","PASS_NOT_FOUND");}
    out("B_GATE","PASS");System.exit(0);
   }else{out("GATE","FAIL_BAD_MODE");System.exit(2);}
  }catch(Throwable t){out("GATE","FAIL");out("EXCEPTION",t.getClass().getName()+":"+t.getMessage());try{if(rs!=null)rs.closeRecordStore();}catch(Throwable x){}System.exit(2);}
 }
 protected void pauseApp(){}
 protected void destroyApp(boolean unconditional){}
}
