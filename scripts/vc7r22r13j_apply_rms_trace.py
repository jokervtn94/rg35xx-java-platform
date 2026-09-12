#!/usr/bin/env python3
import pathlib,re,sys
if len(sys.argv)!=2:
    raise SystemExit('usage: vc7r22r13j_apply_rms_trace.py <RecordStore.java>')
p=pathlib.Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
orig=s

def once(old,new,label):
    global s
    n=s.count(old)
    if n!=1: raise SystemExit('R13J %s anchor count=%d'%(label,n))
    s=s.replace(old,new,1)

# Add sparse trace helper near class start.
once('public class RecordStore\n{','''public class RecordStore\n{\n\tprivate static int rg35xxR13JSeq = 0;\n\tprivate static synchronized void rg35xxR13JLog(String stage, String detail)\n\t{\n\t\trg35xxR13JSeq++;\n\t\tif(rg35xxR13JSeq <= 40 || (rg35xxR13JSeq % 120) == 0)\n\t\t{\n\t\t\tSystem.err.println("RG35XX-R13J-RMS: " + stage + " seq=" + rg35xxR13JSeq + " detail=" + detail + " thread=" + Thread.currentThread().getName());\n\t\t}\n\t}\n''','class helper')

# Constructor entry/ready.
once('''\tprivate RecordStore(String recordStoreName, boolean createIfNecessary, String vendorname, String suitename, int authmode, boolean writable, String password) throws RecordStoreException, RecordStoreNotFoundException, SecurityException\n\t{\n\t\tif(recordStoreName == null)''',
'''\tprivate RecordStore(String recordStoreName, boolean createIfNecessary, String vendorname, String suitename, int authmode, boolean writable, String password) throws RecordStoreException, RecordStoreNotFoundException, SecurityException\n\t{\n\t\trg35xxR13JLog("CTOR_BEGIN", String.valueOf(recordStoreName) + ":create=" + createIfNecessary);\n\t\tif(recordStoreName == null)''','ctor begin')
once('''\t\tthisStore = this;\n\t}''','''\t\tthisStore = this;\n\t\trg35xxR13JLog("CTOR_DONE", name + ":records=" + (records.size()-1) + ":nextid=" + nextid);\n\t}''','ctor done')

# Main openRecordStore overload used by most MIDlets.
once('''\tpublic static RecordStore openRecordStore(String recordStoreName, boolean createIfNecessary) throws RecordStoreException, RecordStoreNotFoundException, SecurityException\n\t{\n\t\tMobile.log''',
'''\tpublic static RecordStore openRecordStore(String recordStoreName, boolean createIfNecessary) throws RecordStoreException, RecordStoreNotFoundException, SecurityException\n\t{\n\t\trg35xxR13JLog("OPEN_A", String.valueOf(recordStoreName) + ":create=" + createIfNecessary);\n\t\tMobile.log''','open A')

# Read/write data operations.
once('''\tpublic int addRecord(byte[] data, int offset, int numBytes, int tag) throws RecordStoreException, RecordStoreFullException, SecurityException\n\t{\n\t\tMobile.log''',
'''\tpublic int addRecord(byte[] data, int offset, int numBytes, int tag) throws RecordStoreException, RecordStoreFullException, SecurityException\n\t{\n\t\trg35xxR13JLog("ADD_BEGIN", name + ":bytes=" + numBytes + ":nextid=" + nextid);\n\t\tMobile.log''','add begin')
once('''\t\t\treturn nextid-1; // Return the new record's id, not the next one's.''',
'''\t\t\trg35xxR13JLog("ADD_DONE", name + ":id=" + (nextid-1) + ":records=" + (records.size()-1));\n\t\t\treturn nextid-1; // Return the new record's id, not the next one's.''','add done')
once('''\tpublic byte[] getRecord(int recordId) throws InvalidRecordIDException, RecordStoreNotOpenException, RecordStoreException\n\t{\n\t\tMobile.log''',
'''\tpublic byte[] getRecord(int recordId) throws InvalidRecordIDException, RecordStoreNotOpenException, RecordStoreException\n\t{\n\t\trg35xxR13JLog("GET_BEGIN", name + ":id=" + recordId);\n\t\tMobile.log''','get begin')
once('''\t\treturn (t == null || t.length == 0) ? null : t.clone();''',
'''\t\trg35xxR13JLog("GET_DONE", name + ":id=" + recordId + ":bytes=" + (t == null ? -1 : t.length));\n\t\treturn (t == null || t.length == 0) ? null : t.clone();''','get done')

# Disk persistence boundaries.
once('''\tpublic void saveRecordStore()\n\t{\n\t\tfinal String ownerVersion''',
'''\tpublic void saveRecordStore()\n\t{\n\t\trg35xxR13JLog("SAVE_BEGIN", name + ":records=" + (records.size()-1));\n\t\tfinal String ownerVersion''','save begin')
# Place save done before method closes, using the catch block tail as a stable anchor.
once('''\t\tcatch (Exception e)\n\t\t{\n\t\t\tMobile.log(Mobile.LOG_ERROR, RecordStore.class.getPackage().getName() + "." + RecordStore.class.getSimpleName() + ": " + "> Couldn't save RecordStore " + name + " :" + e.getMessage());\n\t\t\te.printStackTrace();\n\t\t}\n\t}\n\n\tpublic void loadRecordStore''',
'''\t\tcatch (Exception e)\n\t\t{\n\t\t\tMobile.log(Mobile.LOG_ERROR, RecordStore.class.getPackage().getName() + "." + RecordStore.class.getSimpleName() + ": " + "> Couldn't save RecordStore " + name + " :" + e.getMessage());\n\t\t\te.printStackTrace();\n\t\t}\n\t\trg35xxR13JLog("SAVE_DONE", name + ":records=" + (records.size()-1));\n\t}\n\n\tpublic void loadRecordStore''','save done')
once('''\tpublic void loadRecordStore(boolean createIfNecessary) throws RecordStoreException, RecordStoreNotFoundException, SecurityException\n\t{\n\t\tfile = new File(rmsFile);''',
'''\tpublic void loadRecordStore(boolean createIfNecessary) throws RecordStoreException, RecordStoreNotFoundException, SecurityException\n\t{\n\t\trg35xxR13JLog("LOAD_BEGIN", name + ":create=" + createIfNecessary + ":file=" + rmsFile);\n\t\tfile = new File(rmsFile);''','load begin')

for tok in ('CTOR_BEGIN','CTOR_DONE','OPEN_A','ADD_BEGIN','ADD_DONE','GET_BEGIN','GET_DONE','SAVE_BEGIN','SAVE_DONE','LOAD_BEGIN'):
    if tok not in s: raise SystemExit('R13J marker missing '+tok)
if s==orig: raise SystemExit('R13J no mutation')
p.write_text(s,encoding='utf-8',newline='\n')
print('VC7R22-R1.3J_RMS_TRACE=PASS')
print('BEHAVIOR_CHANGE=NONE_TRACE_ONLY')
