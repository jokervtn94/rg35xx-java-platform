#!/usr/bin/env python3
import pathlib,sys
if len(sys.argv)!=3:
    raise SystemExit('usage: vc7r22r13i_apply_network_dependency_trace.py <Connector.java> <HttpConnectionImpl.java>')
cp=pathlib.Path(sys.argv[1]); hp=pathlib.Path(sys.argv[2])
C=cp.read_text(encoding='utf-8'); H=hp.read_text(encoding='utf-8')
orig=(C,H)

def once(s,old,new,label):
    n=s.count(old)
    if n!=1: raise SystemExit('R13I %s anchor count=%d'%(label,n))
    return s.replace(old,new,1)

C=once(C,
'''\tprivate static OutputStream output = null;''',
'''\tprivate static OutputStream output = null;\n\n\tprivate static int rg35xxR13INetSeq = 0;\n\tprivate static synchronized int rg35xxR13INext() { return ++rg35xxR13INetSeq; }\n\tprivate static void rg35xxR13ILog(String stage, int seq, String name, int aux)\n\t{\n\t\tSystem.err.println("RG35XX-R13I-NET stage="+stage+" seq="+seq+" aux="+aux+" thread="+Thread.currentThread().getName()+" name="+name);\n\t}''','connector helper')

C=once(C,
'''\tpublic static Connection open(String name, int mode, boolean timeouts) throws IOException\n\t{''',
'''\tpublic static Connection open(String name, int mode, boolean timeouts) throws IOException\n\t{\n\t\tint rg35xxR13ISeq = rg35xxR13INext();\n\t\trg35xxR13ILog("CONNECTOR_OPEN_BEGIN", rg35xxR13ISeq, name, mode);''','connector open begin')

# Log the exact protocol branch without changing the selected implementation.
C=once(C,
'''\t\tif (name.startsWith("http://") || name.startsWith("https://") || name.startsWith("socket://")) { return new HttpConnectionImpl(name); }''',
'''\t\tif (name.startsWith("http://") || name.startsWith("https://") || name.startsWith("socket://"))\n\t\t{\n\t\t\trg35xxR13ILog("CONNECTOR_NETWORK_BRANCH", rg35xxR13ISeq, name, name.startsWith("socket://") ? 2 : 1);\n\t\t\tConnection rg35xxR13IConn = new HttpConnectionImpl(name);\n\t\t\trg35xxR13ILog("CONNECTOR_OPEN_DONE", rg35xxR13ISeq, name, 1);\n\t\t\treturn rg35xxR13IConn;\n\t\t}''','network branch')

H=once(H,
'''\tMap<String, String> requestProperty = new HashMap<String, String>();\n\tprivate String url, requestMethod;''',
'''\tMap<String, String> requestProperty = new HashMap<String, String>();\n\tprivate String url, requestMethod;\n\tprivate static int rg35xxR13ISeq = 0;\n\tprivate static synchronized int rg35xxR13INext() { return ++rg35xxR13ISeq; }\n\tprivate void rg35xxR13ILog(String stage, int aux)\n\t{\n\t\tSystem.err.println("RG35XX-R13I-NET stage="+stage+" seq="+rg35xxR13INext()+" aux="+aux+" thread="+Thread.currentThread().getName()+" url="+url);\n\t}''','http helper')

H=once(H,
'''\tpublic HttpConnectionImpl(String url) { this.url = url; }''',
'''\tpublic HttpConnectionImpl(String url) { this.url = url; rg35xxR13ILog("HTTP_CTOR", 0); }''','http ctor')
H=once(H,
'''\tpublic void connect() throws java.io.IOException { Mobile.log(Mobile.LOG_WARNING, HttpConnectionImpl.class.getPackage().getName() + "." + HttpConnectionImpl.class.getSimpleName() + ": " + "Http Connection requested: "+ this.url); }''',
'''\tpublic void connect() throws java.io.IOException { rg35xxR13ILog("HTTP_CONNECT", 0); Mobile.log(Mobile.LOG_WARNING, HttpConnectionImpl.class.getPackage().getName() + "." + HttpConnectionImpl.class.getSimpleName() + ": " + "Http Connection requested: "+ this.url); }''','http connect')
H=once(H,
'''\tpublic int getResponseCode() { return 200; }''',
'''\tpublic int getResponseCode() { rg35xxR13ILog("HTTP_RESPONSE_CODE_STUB", 200); return 200; }''','response code')
H=once(H,
'''\tpublic InputStream openInputStream() throws UnsupportedEncodingException { return null; }''',
'''\tpublic InputStream openInputStream() throws UnsupportedEncodingException { rg35xxR13ILog("HTTP_INPUT_STREAM_NULL", 0); return null; }''','input null')
H=once(H,
'''\tpublic OutputStream openOutputStream() { return null; }''',
'''\tpublic OutputStream openOutputStream() { rg35xxR13ILog("HTTP_OUTPUT_STREAM_NULL", 0); return null; }''','output null')

for tok in ('CONNECTOR_OPEN_BEGIN','CONNECTOR_NETWORK_BRANCH','CONNECTOR_OPEN_DONE'):
    if tok not in C: raise SystemExit('R13I Connector marker missing '+tok)
for tok in ('HTTP_CTOR','HTTP_CONNECT','HTTP_RESPONSE_CODE_STUB','HTTP_INPUT_STREAM_NULL','HTTP_OUTPUT_STREAM_NULL'):
    if tok not in H: raise SystemExit('R13I Http marker missing '+tok)
if (C,H)==orig: raise SystemExit('R13I no mutation')
cp.write_text(C,encoding='utf-8',newline='\n'); hp.write_text(H,encoding='utf-8',newline='\n')
print('VC7R22-R1.3I_NETWORK_DEPENDENCY_TRACE=PASS')
print('BEHAVIOR_CHANGE=NONE_TRACE_ONLY')
