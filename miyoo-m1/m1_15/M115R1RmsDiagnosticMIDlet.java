package org.recompile.mobile;
import javax.microedition.midlet.MIDlet;
import javax.microedition.rms.*;

public final class M115R1RmsDiagnosticMIDlet extends MIDlet {
 private static final String STORE="RG35XX_M115_R1";
 private static void out(String k,Object v){System.out.println("M1_15_R1_"+k+"="+String.valueOf(v));}
 private static boolean eq(byte[] a,byte[] b){if(a==null||b==null||a.length!=b.length)return false;for(int i=0;i<a.length;i++)if(a[i]!=b[i])return false;return true;}
 protected void startApp(){
  out("PRIMARY_VARIABLE","NONE_RMS_DIAGNOSTIC_ONLY");out("RMS_IMPLEMENTATION_CHANGE","NONE");
  RecordStore rs=null;
  try{
   try{RecordStore.deleteRecordStore(STORE);out("PREDELETE","PASS_OR_ABSENT");}catch(RecordStoreNotFoundException e){out("PREDELETE","ABSENT_EXPECTED");}
   byte[] a=new byte[]{0x52,0x47,0x35,0x58,0x58,0x11,0x22,0x33};
   byte[] b=new byte[]{0x52,0x47,0x35,0x58,0x58,0x44,0x55,0x66,0x77};
   rs=RecordStore.openRecordStore(STORE,true);out("OPEN_CREATE","PASS");
   int id=rs.addRecord(a,0,a.length);out("ADD_ID",new Integer(id));out("ADD_NUM_RECORDS",new Integer(rs.getNumRecords()));
   byte[] got=rs.getRecord(id);out("GET_AFTER_ADD",eq(a,got)?"PASS":"FAIL");
   rs.setRecord(id,b,0,b.length);got=rs.getRecord(id);out("GET_AFTER_SET",eq(b,got)?"PASS":"FAIL");
   rs.closeRecordStore();rs=null;out("CLOSE_1","PASS");
   rs=RecordStore.openRecordStore(STORE,false);out("REOPEN","PASS");out("REOPEN_NUM_RECORDS",new Integer(rs.getNumRecords()));got=rs.getRecord(id);out("REOPEN_DATA",eq(b,got)?"PASS":"FAIL");
   rs.closeRecordStore();rs=null;out("CLOSE_2","PASS");
   RecordStore.deleteRecordStore(STORE);out("DELETE","PASS");
   try{rs=RecordStore.openRecordStore(STORE,false);out("VERIFY_DELETE","FAIL_OPENED");rs.closeRecordStore();rs=null;}catch(RecordStoreNotFoundException e){out("VERIFY_DELETE","PASS_NOT_FOUND");}
   out("LIFECYCLE_GATE","PASS");System.exit(0);
  }catch(Throwable t){out("LIFECYCLE_GATE","FAIL");out("EXCEPTION",t.getClass().getName()+":"+t.getMessage());try{if(rs!=null)rs.closeRecordStore();}catch(Throwable x){}System.exit(2);}
 }
 protected void pauseApp(){}
 protected void destroyApp(boolean unconditional){}
}
