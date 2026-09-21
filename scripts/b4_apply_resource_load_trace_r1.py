#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 3:
    raise SystemExit("usage: b4_apply_resource_load_trace_r1.py <MIDletLoader.java> <PlatformImage.java>")

loader = pathlib.Path(sys.argv[1])
image = pathlib.Path(sys.argv[2])
ls = loader.read_text(encoding="utf-8")
ps = image.read_text(encoding="utf-8")
orig_l, orig_p = ls, ps

if "RG35XX-B4-RESOURCE-TRACE" in ls or "RG35XX-B4-IMAGE-DECODE" in ps:
    raise SystemExit("B4 RESOURCE TRACE R1 FAIL already applied")

def once(text, old, new, label):
    n = text.count(old)
    if n != 1:
        raise SystemExit("B4 RESOURCE TRACE R1 FAIL %s count=%d" % (label, n))
    return text.replace(old, new, 1)

# MIDletLoader: bounded resource stream observability. No path-resolution,
# read-loop, return-type or fallback semantics are changed.
class_anchor = "public class MIDletLoader extends URLClassLoader\n{\n"
loader_helpers = """public class MIDletLoader extends URLClassLoader
{
\tprivate static int rg35xxB4ResourceSeq = 0;

\tprivate static int rg35xxB4ResourceNextSeq()
\t{
\t\treturn ++rg35xxB4ResourceSeq;
\t}

\tprivate static boolean rg35xxB4ResourceLog(int seq)
\t{
\t\treturn seq <= 128 || (seq > 0 && (seq & (seq - 1)) == 0);
\t}

\tprivate static String rg35xxB4ThreadName()
\t{
\t\tThread t = Thread.currentThread();
\t\treturn t == null ? "null" : t.getName();
\t}

"""
ls = once(ls, class_anchor, loader_helpers, "MIDletLoader helper insertion")

stream_entry = """\tpublic InputStream getMIDletResourceAsStream(String resource)
\t{
\t\tMobile.log(Mobile.LOG_DEBUG, MIDletLoader.class.getPackage().getName() + "." + MIDletLoader.class.getSimpleName() + ": " + "Get Resource As Stream: "+resource + " path:" + className[selectedMidlet]);
"""
stream_new = """\tpublic InputStream getMIDletResourceAsStream(String resource)
\t{
\t\tfinal int rg35xxSeq = rg35xxB4ResourceNextSeq();
\t\tfinal long rg35xxStart = System.currentTimeMillis();
\t\tfinal boolean rg35xxLog = rg35xxB4ResourceLog(rg35xxSeq);
\t\tfinal String rg35xxOriginal = resource;
\t\tif(rg35xxLog)
\t\t{
\t\t\tSystem.err.println("RG35XX-B4-RESOURCE-TRACE stage=STREAM_BEGIN seq=" + rg35xxSeq
\t\t\t\t+ " thread=" + rg35xxB4ThreadName() + " resource=" + rg35xxOriginal);
\t\t}
\t\tMobile.log(Mobile.LOG_DEBUG, MIDletLoader.class.getPackage().getName() + "." + MIDletLoader.class.getSimpleName() + ": " + "Get Resource As Stream: "+resource + " path:" + className[selectedMidlet]);
"""
ls = once(ls, stream_entry, stream_new, "resource stream entry")

stream_return = """\t\t\tif(!isSiemens) { return new ByteArrayInputStream(buffer.toByteArray()); }
\t\t\telse { return new SiemensInputStream(buffer.toByteArray()); }
\t\t}
\t\tcatch (Exception e)
\t\t{
\t\t\treturn super.getResourceAsStream(resource);
\t\t}
"""
stream_return_new = """\t\t\tbyte[] rg35xxBytes = buffer.toByteArray();
\t\t\tif(rg35xxLog)
\t\t\t{
\t\t\t\tSystem.err.println("RG35XX-B4-RESOURCE-TRACE stage=STREAM_END seq=" + rg35xxSeq
\t\t\t\t\t+ " thread=" + rg35xxB4ThreadName() + " resource=" + rg35xxOriginal
\t\t\t\t\t+ " resolved=" + resource + " bytes=" + rg35xxBytes.length
\t\t\t\t\t+ " elapsedMs=" + (System.currentTimeMillis() - rg35xxStart));
\t\t\t}
\t\t\tif(!isSiemens) { return new ByteArrayInputStream(rg35xxBytes); }
\t\t\telse { return new SiemensInputStream(rg35xxBytes); }
\t\t}
\t\tcatch (Exception e)
\t\t{
\t\t\tif(rg35xxLog)
\t\t\t{
\t\t\t\tSystem.err.println("RG35XX-B4-RESOURCE-TRACE stage=STREAM_FALLBACK seq=" + rg35xxSeq
\t\t\t\t\t+ " thread=" + rg35xxB4ThreadName() + " resource=" + rg35xxOriginal
\t\t\t\t\t+ " resolved=" + resource + " error=" + e.getClass().getName()
\t\t\t\t\t+ " elapsedMs=" + (System.currentTimeMillis() - rg35xxStart));
\t\t\t}
\t\t\treturn super.getResourceAsStream(resource);
\t\t}
"""
ls = once(ls, stream_return, stream_return_new, "resource stream return")

bytes_entry = """\tpublic byte[] getMIDletResourceAsByteArray(String resource)
\t{
\t\tMobile.log(Mobile.LOG_DEBUG, MIDletLoader.class.getPackage().getName() + "." + MIDletLoader.class.getSimpleName() + ": " + "Get Resource as Byte Array: "+resource);
"""
bytes_new = """\tpublic byte[] getMIDletResourceAsByteArray(String resource)
\t{
\t\tfinal int rg35xxSeq = rg35xxB4ResourceNextSeq();
\t\tfinal long rg35xxStart = System.currentTimeMillis();
\t\tfinal boolean rg35xxLog = rg35xxB4ResourceLog(rg35xxSeq);
\t\tfinal String rg35xxOriginal = resource;
\t\tif(rg35xxLog)
\t\t{
\t\t\tSystem.err.println("RG35XX-B4-RESOURCE-TRACE stage=BYTES_BEGIN seq=" + rg35xxSeq
\t\t\t\t+ " thread=" + rg35xxB4ThreadName() + " resource=" + rg35xxOriginal);
\t\t}
\t\tMobile.log(Mobile.LOG_DEBUG, MIDletLoader.class.getPackage().getName() + "." + MIDletLoader.class.getSimpleName() + ": " + "Get Resource as Byte Array: "+resource);
"""
ls = once(ls, bytes_entry, bytes_new, "resource bytes entry")

bytes_return = """\t\t\treturn buffer.toByteArray();
\t\t}
\t\tcatch (Exception e)
\t\t{
\t\t\tMobile.log(Mobile.LOG_ERROR, MIDletLoader.class.getPackage().getName() + "." + MIDletLoader.class.getSimpleName() + ": " + resource + " Not Found");
\t\t\treturn new byte[0];
\t\t}
"""
bytes_return_new = """\t\t\tbyte[] rg35xxBytes = buffer.toByteArray();
\t\t\tif(rg35xxLog)
\t\t\t{
\t\t\t\tSystem.err.println("RG35XX-B4-RESOURCE-TRACE stage=BYTES_END seq=" + rg35xxSeq
\t\t\t\t\t+ " thread=" + rg35xxB4ThreadName() + " resource=" + rg35xxOriginal
\t\t\t\t\t+ " resolved=" + resource + " bytes=" + rg35xxBytes.length
\t\t\t\t\t+ " elapsedMs=" + (System.currentTimeMillis() - rg35xxStart));
\t\t\t}
\t\t\treturn rg35xxBytes;
\t\t}
\t\tcatch (Exception e)
\t\t{
\t\t\tif(rg35xxLog)
\t\t\t{
\t\t\t\tSystem.err.println("RG35XX-B4-RESOURCE-TRACE stage=BYTES_FAIL seq=" + rg35xxSeq
\t\t\t\t\t+ " thread=" + rg35xxB4ThreadName() + " resource=" + rg35xxOriginal
\t\t\t\t\t+ " resolved=" + resource + " error=" + e.getClass().getName()
\t\t\t\t\t+ " elapsedMs=" + (System.currentTimeMillis() - rg35xxStart));
\t\t\t}
\t\t\tMobile.log(Mobile.LOG_ERROR, MIDletLoader.class.getPackage().getName() + "." + MIDletLoader.class.getSimpleName() + ": " + resource + " Not Found");
\t\t\treturn new byte[0];
\t\t}
"""
ls = once(ls, bytes_return, bytes_return_new, "resource bytes return")

# PlatformImage: observe each actual ImageIO boundary. The VC6 iCCP sanitizer
# remains the decode input owner; this patch only times begin/end around it.
image_anchor = "\tpublic PlatformImage() { }\n"
image_helpers = """\tprivate static int rg35xxB4DecodeSeq = 0;

\tprivate static int rg35xxB4DecodeNextSeq()
\t{
\t\treturn ++rg35xxB4DecodeSeq;
\t}

\tprivate static boolean rg35xxB4DecodeLog(int seq)
\t{
\t\treturn seq <= 128 || (seq > 0 && (seq & (seq - 1)) == 0);
\t}

\tprivate static String rg35xxB4DecodeThread()
\t{
\t\tThread t = Thread.currentThread();
\t\treturn t == null ? "null" : t.getName();
\t}

"""
ps = once(ps, image_anchor, image_helpers + image_anchor, "PlatformImage helper insertion")

resource_sig = """\tpublic PlatformImage(String name) throws IOException
\t{
\t\t// Create Image from resource name
\t\t
\t\tBufferedImage image;
"""
resource_sig_new = """\tpublic PlatformImage(String name) throws IOException
\t{
\t\t// Create Image from resource name
\t\tfinal int rg35xxSeq = rg35xxB4DecodeNextSeq();
\t\tfinal long rg35xxStart = System.currentTimeMillis();
\t\tfinal boolean rg35xxLog = rg35xxB4DecodeLog(rg35xxSeq);
\t\tif(rg35xxLog)
\t\t{
\t\t\tSystem.err.println("RG35XX-B4-IMAGE-DECODE stage=NAME_BEGIN seq=" + rg35xxSeq
\t\t\t\t+ " thread=" + rg35xxB4DecodeThread() + " name=" + name);
\t\t}
\t\t
\t\tBufferedImage image;
"""
ps = once(ps, resource_sig, resource_sig_new, "PlatformImage name entry")

resource_end = """\t\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();
\t\t}
\t}

\tpublic PlatformImage(InputStream stream) throws IOException
"""
resource_end_new = """\t\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();
\t\t\tif(rg35xxLog)
\t\t\t{
\t\t\t\tSystem.err.println("RG35XX-B4-IMAGE-DECODE stage=NAME_END seq=" + rg35xxSeq
\t\t\t\t\t+ " thread=" + rg35xxB4DecodeThread() + " name=" + name
\t\t\t\t\t+ " size=" + canvas.getWidth() + "x" + canvas.getHeight()
\t\t\t\t\t+ " elapsedMs=" + (System.currentTimeMillis() - rg35xxStart));
\t\t\t}
\t\t}
\t}

\tpublic PlatformImage(InputStream stream) throws IOException
"""
ps = once(ps, resource_end, resource_end_new, "PlatformImage name end")

stream_sig = """\tpublic PlatformImage(InputStream stream) throws IOException
\t{
\t\t// Create Image from InputStream
\t\tMobile.log(Mobile.LOG_DEBUG, PlatformImage.class.getPackage().getName() + "." + PlatformImage.class.getSimpleName() + ": " + "Image From Stream");
"""
stream_sig_new = """\tpublic PlatformImage(InputStream stream) throws IOException
\t{
\t\t// Create Image from InputStream
\t\tfinal int rg35xxSeq = rg35xxB4DecodeNextSeq();
\t\tfinal long rg35xxStart = System.currentTimeMillis();
\t\tfinal boolean rg35xxLog = rg35xxB4DecodeLog(rg35xxSeq);
\t\tif(rg35xxLog)
\t\t{
\t\t\tSystem.err.println("RG35XX-B4-IMAGE-DECODE stage=STREAM_BEGIN seq=" + rg35xxSeq
\t\t\t\t+ " thread=" + rg35xxB4DecodeThread());
\t\t}
\t\tMobile.log(Mobile.LOG_DEBUG, PlatformImage.class.getPackage().getName() + "." + PlatformImage.class.getSimpleName() + ": " + "Image From Stream");
"""
ps = once(ps, stream_sig, stream_sig_new, "PlatformImage stream entry")

stream_end = """\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();
\t}

\tpublic PlatformImage(Image source)
"""
stream_end_new = """\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();
\t\tif(rg35xxLog)
\t\t{
\t\t\tSystem.err.println("RG35XX-B4-IMAGE-DECODE stage=STREAM_END seq=" + rg35xxSeq
\t\t\t\t+ " thread=" + rg35xxB4DecodeThread()
\t\t\t\t+ " size=" + canvas.getWidth() + "x" + canvas.getHeight()
\t\t\t\t+ " elapsedMs=" + (System.currentTimeMillis() - rg35xxStart));
\t\t}
\t}

\tpublic PlatformImage(Image source)
"""
ps = once(ps, stream_end, stream_end_new, "PlatformImage stream end")

bytes_sig = """\tpublic PlatformImage(byte[] imageData, int imageOffset, int imageLength, boolean mutable) // DoJa also uses this one, creates mutable images like DirectGraphics
\t{
\t\t// Create Image from Byte Array Range (Data is PNG, JPG, etc.)
\t\tInputStream stream = new ByteArrayInputStream(imageData, imageOffset, imageLength);
"""
bytes_sig_new = """\tpublic PlatformImage(byte[] imageData, int imageOffset, int imageLength, boolean mutable) // DoJa also uses this one, creates mutable images like DirectGraphics
\t{
\t\t// Create Image from Byte Array Range (Data is PNG, JPG, etc.)
\t\tfinal int rg35xxSeq = rg35xxB4DecodeNextSeq();
\t\tfinal long rg35xxStart = System.currentTimeMillis();
\t\tfinal boolean rg35xxLog = rg35xxB4DecodeLog(rg35xxSeq);
\t\tif(rg35xxLog)
\t\t{
\t\t\tSystem.err.println("RG35XX-B4-IMAGE-DECODE stage=BYTES_BEGIN seq=" + rg35xxSeq
\t\t\t\t+ " thread=" + rg35xxB4DecodeThread() + " offset=" + imageOffset
\t\t\t\t+ " length=" + imageLength + " mutable=" + mutable);
\t\t}
\t\tInputStream stream = new ByteArrayInputStream(imageData, imageOffset, imageLength);
"""
ps = once(ps, bytes_sig, bytes_sig_new, "PlatformImage bytes entry")

bytes_end = """\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();
\t\tisMutable = mutable;
\t}

\tpublic PlatformImage(int[] rgb, int Width, int Height, boolean processAlpha)
"""
bytes_end_new = """\t\tdataBuffer = ((DataBufferInt) canvas.getRaster().getDataBuffer()).getData();
\t\tisMutable = mutable;
\t\tif(rg35xxLog)
\t\t{
\t\t\tSystem.err.println("RG35XX-B4-IMAGE-DECODE stage=BYTES_END seq=" + rg35xxSeq
\t\t\t\t+ " thread=" + rg35xxB4DecodeThread() + " length=" + imageLength
\t\t\t\t+ " size=" + canvas.getWidth() + "x" + canvas.getHeight()
\t\t\t\t+ " elapsedMs=" + (System.currentTimeMillis() - rg35xxStart));
\t\t}
\t}

\tpublic PlatformImage(int[] rgb, int Width, int Height, boolean processAlpha)
"""
ps = once(ps, bytes_end, bytes_end_new, "PlatformImage bytes end")

required = [
    "RG35XX-B4-RESOURCE-TRACE stage=STREAM_BEGIN",
    "RG35XX-B4-RESOURCE-TRACE stage=STREAM_END",
    "RG35XX-B4-RESOURCE-TRACE stage=BYTES_BEGIN",
    "RG35XX-B4-RESOURCE-TRACE stage=BYTES_END",
    "RG35XX-B4-IMAGE-DECODE stage=NAME_BEGIN",
    "RG35XX-B4-IMAGE-DECODE stage=NAME_END",
    "RG35XX-B4-IMAGE-DECODE stage=STREAM_BEGIN",
    "RG35XX-B4-IMAGE-DECODE stage=STREAM_END",
    "RG35XX-B4-IMAGE-DECODE stage=BYTES_BEGIN",
    "RG35XX-B4-IMAGE-DECODE stage=BYTES_END",
    "seq <= 128 || (seq > 0 && (seq & (seq - 1)) == 0)",
]
blob = ls + ps
for token in required:
    if token not in blob:
        raise SystemExit("B4 RESOURCE TRACE R1 FAIL missing token: " + token)

if ls == orig_l or ps == orig_p:
    raise SystemExit("B4 RESOURCE TRACE R1 FAIL no mutation")

loader.write_text(ls, encoding="utf-8", newline="\n")
image.write_text(ps, encoding="utf-8", newline="\n")
print("B4_DRAGON_RESOURCE_LOAD_TRACE_R1_PATCH=PASS")
print("PRIMARY_VARIABLE=BOUNDED_RESOURCE_AND_IMAGE_DECODE_OBSERVABILITY_ONLY")
print("LOG_POLICY=FIRST_128_AND_POWER_OF_TWO")
print("BEHAVIOR_CHANGE=NONE")
