#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 6:
    raise SystemExit('usage: vc7r22r22_apply_filebacked_midi.py RG35XXNativePlayer.java RG35XXAudioTransport.java RG35XXAudioProtocol.java rg35xx_audio_protocol.h rg35xx_audio_dispatch.c')

jp, jt, jproto, nproto, ndisp = [pathlib.Path(x) for x in sys.argv[1:]]

for p in (jp, jt, jproto, nproto, ndisp):
    if not p.is_file():
        raise SystemExit('missing source: '+str(p))

def read(p):
    return p.read_text().replace('\r\n','\n').replace('\r','\n')

def write(p,s):
    p.write_text(s)

# Java protocol: add one opcode only.
s=read(jproto)
old='    public static final int OP_RESET          = 10;\n'
new=old+'    public static final int OP_REGISTER_MIDI_FILE = 11;\n'
if old not in s or 'OP_REGISTER_MIDI_FILE' in s:
    raise SystemExit('Java protocol anchor mismatch/already patched')
s=s.replace(old,new,1)
write(jproto,s)

# Java transport: small UTF-8 path command; no media blob copy.
s=read(jt)
anchor='    public static synchronized boolean registerMidi(int playerId, byte[] midi)\n    {\n        return send(RG35XXAudioProtocol.OP_REGISTER_MIDI, playerId, midi);\n    }\n'
insert=anchor+'''\n    /** R2.2: register an SD-backed MIDI path instead of sending the whole blob. */\n    public static synchronized boolean registerMidiFile(int playerId, String path)\n    {\n        if(path == null || path.length() == 0) return false;\n        try\n        {\n            byte[] payload = path.getBytes("UTF-8");\n            if(payload.length == 0 || payload.length > 512) return false;\n            return send(RG35XXAudioProtocol.OP_REGISTER_MIDI_FILE, playerId, payload);\n        }\n        catch(java.io.UnsupportedEncodingException e)\n        {\n            return false;\n        }\n    }\n'''
if anchor not in s or 'registerMidiFile' in s:
    raise SystemExit('Java transport anchor mismatch/already patched')
s=s.replace(anchor,insert,1)
write(jt,s)

# Java player: MIDI stream -> file in 4 KiB chunks; tone/PCM unchanged.
s=read(jp)
s=s.replace('import java.io.InputStream;\n', 'import java.io.InputStream;\nimport java.io.File;\nimport java.io.FileOutputStream;\n',1)
s=s.replace('    private byte[] media;\n', '    private byte[] media;\n    private File midiFile;\n',1)
old='''        entry = RG35XXMediaRegistry.create(contentType);\n        entry.setEventListener(this);\n        media = readAll(stream);\n'''
new='''        entry = RG35XXMediaRegistry.create(contentType);\n        entry.setEventListener(this);\n        if(entry.mediaType == RG35XXMediaRegistry.TYPE_MIDI)\n        {\n            try\n            {\n                midiFile = cacheMidiToFile(stream, entry.playerId);\n                media = null;\n                System.err.println("RG35XX-AUDIO-R2.2: MIDI file-backed path=" + midiFile.getPath());\n            }\n            catch(IOException e)\n            {\n                midiFile = null;\n                media = readAll(stream);\n                System.err.println("RG35XX-AUDIO-R2.2: MIDI file cache failed; inline fallback");\n            }\n        }\n        else\n            media = readAll(stream);\n'''
if old not in s:
    raise SystemExit('NativePlayer constructor anchor mismatch')
s=s.replace(old,new,1)
old='''        if(state >= PREFETCHED)\n            throw new IllegalStateException("cannot replace MIDI after prefetch");\n        media = midi;\n'''
new='''        if(state >= PREFETCHED)\n            throw new IllegalStateException("cannot replace MIDI after prefetch");\n        if(midiFile != null)\n        {\n            try { midiFile.delete(); } catch(Exception ignored) { }\n            midiFile = null;\n        }\n        media = midi;\n'''
if old not in s:
    raise SystemExit('NativePlayer setMidi anchor mismatch')
s=s.replace(old,new,1)
old='''        if(entry.mediaType == RG35XXMediaRegistry.TYPE_MIDI ||\n           entry.mediaType == RG35XXMediaRegistry.TYPE_TONE)\n            ok = media != null && media.length >= 4 &&\n                 RG35XXAudioTransport.registerMidi(entry.playerId, media);\n'''
new='''        if(entry.mediaType == RG35XXMediaRegistry.TYPE_MIDI)\n        {\n            if(midiFile != null)\n                ok = RG35XXAudioTransport.registerMidiFile(entry.playerId, midiFile.getPath());\n            else\n                ok = media != null && media.length >= 4 &&\n                     RG35XXAudioTransport.registerMidi(entry.playerId, media);\n        }\n        else if(entry.mediaType == RG35XXMediaRegistry.TYPE_TONE)\n            ok = media != null && media.length >= 4 &&\n                 RG35XXAudioTransport.registerMidi(entry.playerId, media);\n'''
if old not in s:
    raise SystemExit('NativePlayer prefetch anchor mismatch')
s=s.replace(old,new,1)
old='''        RG35XXMediaRegistry.release(entry.playerId);\n        media = null;\n        state = CLOSED;\n'''
new='''        RG35XXMediaRegistry.release(entry.playerId);\n        media = null;\n        if(midiFile != null)\n        {\n            try { midiFile.delete(); } catch(Exception ignored) { }\n            midiFile = null;\n        }\n        state = CLOSED;\n'''
if old not in s:
    raise SystemExit('NativePlayer close anchor mismatch')
s=s.replace(old,new,1)
anchor='''    private static byte[] readAll(InputStream in) throws IOException\n    {\n'''
helper='''    private static File cacheMidiToFile(InputStream in, int playerId) throws IOException\n    {\n        if(in == null) throw new IOException("null MIDI stream");\n        File dir = new File("/mnt/mmc/CFW/java/cache/freej2me-media");\n        if(!dir.exists() && !dir.mkdirs() && !dir.isDirectory())\n            throw new IOException("cannot create MIDI cache dir");\n        File dst = new File(dir, "player-" + playerId + ".mid");\n        FileOutputStream out = new FileOutputStream(dst, false);\n        boolean ok = false;\n        try\n        {\n            byte[] buf = new byte[4096];\n            int n;\n            while((n = in.read(buf)) != -1) out.write(buf, 0, n);\n            out.flush();\n            ok = dst.length() >= 4;\n        }\n        finally\n        {\n            try { out.close(); } catch(IOException ignored) { }\n            if(!ok) try { dst.delete(); } catch(Exception ignored) { }\n        }\n        if(!ok) throw new IOException("empty/short MIDI cache file");\n        return dst;\n    }\n\n'''+anchor
if anchor not in s or 'cacheMidiToFile' in s:
    raise SystemExit('NativePlayer helper anchor mismatch/already patched')
s=s.replace(anchor,helper,1)
write(jp,s)

# Native protocol: opcode 11, payload is UTF-8 path only.
s=read(nproto)
old='    RG35XX_AUDIO_RESET          = 10\n'
new='    RG35XX_AUDIO_RESET          = 10,\n    RG35XX_AUDIO_REGISTER_MIDI_FILE = 11\n'
if old not in s or 'REGISTER_MIDI_FILE' in s:
    raise SystemExit('native protocol anchor mismatch/already patched')
s=s.replace(old,new,1)
write(nproto,s)

# Native dispatcher: bounded path validation + file load; existing cache/mixer untouched.
s=read(ndisp)
s=s.replace('#include <stddef.h>\n', '#include <stddef.h>\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\n',1)
helper='''\nstatic int rg35xx_audio_register_midi_file(uint32_t player_id, const uint8_t *payload, uint32_t payload_size)\n{\n    char path[513];\n    FILE *f;\n    long size;\n    uint8_t *buf;\n    size_t got;\n    int ok;\n    static const char prefix[] = "/mnt/mmc/CFW/java/cache/freej2me-media/";\n\n    if(!payload || payload_size == 0 || payload_size > 512) return 0;\n    memcpy(path, payload, payload_size);\n    path[payload_size] = '\\0';\n    if(memchr(path, '\\0', payload_size) != NULL) return 0;\n    if(strncmp(path, prefix, sizeof(prefix)-1) != 0) return 0;\n    if(strstr(path, "..") != NULL) return 0;\n\n    f = fopen(path, "rb");\n    if(!f) return 0;\n    if(fseek(f, 0, SEEK_END) != 0) { fclose(f); return 0; }\n    size = ftell(f);\n    if(size < 4 || size > (16L * 1024L * 1024L)) { fclose(f); return 0; }\n    if(fseek(f, 0, SEEK_SET) != 0) { fclose(f); return 0; }\n    buf = (uint8_t *)malloc((size_t)size);\n    if(!buf) { fclose(f); return 0; }\n    got = fread(buf, 1, (size_t)size, f);\n    fclose(f);\n    if(got != (size_t)size) { free(buf); return 0; }\n    if(buf[0] != 'M' || buf[1] != 'T' || buf[2] != 'h' || buf[3] != 'd') { free(buf); return 0; }\n    ok = rg35xx_media_cache_register(player_id, RG35XX_MEDIA_MIDI, buf, (size_t)size, 0, 0);\n    free(buf);\n    if(ok) fprintf(stderr, "RG35XX-AUDIO-R2.2: native MIDI file registered bytes=%ld\\n", size);\n    return ok;\n}\n'''
anchor='int rg35xx_audio_dispatch(const struct rg35xx_audio_header *h,\n'
if anchor not in s or 'rg35xx_audio_register_midi_file' in s:
    raise SystemExit('native dispatch helper anchor mismatch/already patched')
s=s.replace(anchor,helper+'\n'+anchor,1)
old='''        case RG35XX_AUDIO_REGISTER_PCM16:\n            if(h->payload_size < 8) return 0;\n'''
new='''        case RG35XX_AUDIO_REGISTER_MIDI_FILE:\n            return rg35xx_audio_register_midi_file(h->player_id, payload, h->payload_size);\n        case RG35XX_AUDIO_REGISTER_PCM16:\n            if(h->payload_size < 8) return 0;\n'''
if old not in s:
    raise SystemExit('native dispatch switch anchor mismatch')
s=s.replace(old,new,1)
write(ndisp,s)

print('R2.2 FILE_BACKED_MIDI=PASS')
print('R2.2 PRIMARY_DELTA=MIDI_BLOB_PIPE_TO_FILE_PATH_COMMAND')
print('R2.2 TONE_PCM=UNCHANGED')
