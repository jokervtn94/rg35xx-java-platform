#!/usr/bin/env python3
import pathlib,sys
lib=pathlib.Path(sys.argv[1]); pp=pathlib.Path(sys.argv[2]); mgr=pathlib.Path(sys.argv[3])
s=lib.read_text(encoding='utf-8')
if 'RG35XX-VC7R3-MEDIA-EVENT' in s: raise SystemExit('VC7R3 java media event already applied')
# import IOException
anchor='import java.io.File;\n'
if s.count(anchor)!=1: raise SystemExit('VC7R3 JAVA EVENT FAIL import anchor')
s=s.replace(anchor,anchor+'import java.io.IOException;\n',1)
# allocate fixed event buffer next to main receive buffer initialization point used by pinned source
anchor='\t\t\tbyte[] buffer = new byte[code];\n'
if s.count(anchor)<1:
    # fallback: declare near loop body before switch by exact control header allocation
    anchor='\t\t\tbyte[] buffer;\n'
# robust field-local declaration: place after method opening unique initialization of bytesRead
needle='\t\t\tint bytesRead = 0;\n'
if s.count(needle)!=1: raise SystemExit('VC7R3 JAVA EVENT FAIL bytesRead anchor count=%d'%s.count(needle))
s=s.replace(needle,needle+'\t\t\tfinal byte[] rg35xxMediaEvent = new byte[13];\n',1)
# insert case14 before case15
case15='\t\t\t\t\t\t\tcase 15: // Libretro core requested a new frame.\n'
if s.count(case15)!=1: raise SystemExit('VC7R3 JAVA EVENT FAIL case15 anchor count=%d'%s.count(case15))
case14='''\t\t\t\t\t\t\tcase 14: // RG35XX-VC7R3-MEDIA-EVENT native LOOPED / END_OF_MEDIA
\t\t\t\t\t\t\t\tif(code != 13) { throw new IOException("Invalid RG35XX media event length: " + code); }
\t\t\t\t\t\t\t\tbytesRead = 0;
\t\t\t\t\t\t\t\twhile(bytesRead < rg35xxMediaEvent.length)
\t\t\t\t\t\t\t\t{
\t\t\t\t\t\t\t\t\tint n = System.in.read(rg35xxMediaEvent, bytesRead, rg35xxMediaEvent.length - bytesRead);
\t\t\t\t\t\t\t\t\tif(n < 0) { return; }
\t\t\t\t\t\t\t\t\tbytesRead += n;
\t\t\t\t\t\t\t\t}
\t\t\t\t\t\t\t\tint eventType = rg35xxMediaEvent[0] & 0xFF;
\t\t\t\t\t\t\t\tint playerId = ((rg35xxMediaEvent[1]&0xFF)<<24)|((rg35xxMediaEvent[2]&0xFF)<<16)|((rg35xxMediaEvent[3]&0xFF)<<8)|(rg35xxMediaEvent[4]&0xFF);
\t\t\t\t\t\t\t\tlong mediaTimeUs = 0L;
\t\t\t\t\t\t\t\tfor(int i=5;i<13;i++) mediaTimeUs=(mediaTimeUs<<8)|(long)(rg35xxMediaEvent[i]&0xFF);
\t\t\t\t\t\t\t\tif(playerId>0 && (eventType==org.recompile.mobile.RG35XXMediaRegistry.EVENT_END_OF_MEDIA || eventType==org.recompile.mobile.RG35XXMediaRegistry.EVENT_LOOPED))
\t\t\t\t\t\t\t\t\torg.recompile.mobile.RG35XXMediaRegistry.enqueueNativeEvent(playerId,eventType,mediaTimeUs);
\t\t\t\t\t\t\t\tbreak;

'''
s=s.replace(case15,case14+case15,1)
# drain events during frame/update cadence
update='\t\t\t\t\t\t\t\tlastCoreUpdateTime = System.currentTimeMillis();\n'
if s.count(update)!=1: raise SystemExit('VC7R3 JAVA EVENT FAIL update anchor')
s=s.replace(update,update+'\t\t\t\t\t\t\t\torg.recompile.mobile.RG35XXMediaRegistry.drainNativeEvents();\n',1)
lib.write_text(s,encoding='utf-8',newline='\n')
# PlatformPlayer: initialize inherited FD only when a game actually asks for media.
t=pp.read_text(encoding='utf-8')
needle='\t\tif(RG35XXPlatformProfile.isActive() && Mobile.sound != false)\n\t\t{\n'
if t.count(needle)!=1: raise SystemExit('VC7R3 JAVA EVENT FAIL PlatformPlayer target branch')
t=t.replace(needle,needle+'\t\t\tRG35XXAudioBootstrap.initialize(); // VC7R3 lazy media bootstrap\n',1)
# device locator constructor target branch from 0019 also requires lazy bootstrap.
needle2='\t\tif(RG35XXPlatformProfile.isActive())\n\t\t{\n\t\t\tlisteners = new Vector<PlayerListener>();\n'
if t.count(needle2)!=1: raise SystemExit('VC7R3 JAVA EVENT FAIL locator branch')
t=t.replace(needle2,'\t\tif(RG35XXPlatformProfile.isActive())\n\t\t{\n\t\t\tRG35XXAudioBootstrap.initialize(); // VC7R3 lazy media bootstrap\n\t\t\tlisteners = new Vector<PlayerListener>();\n',1)
pp.write_text(t,encoding='utf-8',newline='\n')
# Manager.playTone target branch: initialize transport lazily before NativePlayer prefetch.
t=mgr.read_text(encoding='utf-8')
needle3='\t\tif(RG35XXPlatformProfile.isActive())\n\t\t{\n\t\t\tfinal int effectiveDuration = duration < 50 ? 50 : duration;\n'
if t.count(needle3)!=1: raise SystemExit('VC7R3 JAVA EVENT FAIL playTone branch')
t=t.replace(needle3,'\t\tif(RG35XXPlatformProfile.isActive())\n\t\t{\n\t\t\torg.recompile.mobile.RG35XXAudioBootstrap.initialize(); // VC7R3 lazy media bootstrap\n\t\t\tfinal int effectiveDuration = duration < 50 ? 50 : duration;\n',1)
mgr.write_text(t,encoding='utf-8',newline='\n')
print('VC7R3 JAVA MEDIA EVENT/LAZY BOOTSTRAP=PASS')
