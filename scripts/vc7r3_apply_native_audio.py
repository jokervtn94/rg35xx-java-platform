#!/usr/bin/env python3
import pathlib,sys
p=pathlib.Path(sys.argv[1]); s=p.read_text(encoding='utf-8'); orig=s
if 'RG35XX-VC7R3-AUDIO-NATIVE' in s: raise SystemExit('VC7R3 native audio already applied')
def once(old,new,label):
 global s
 n=s.count(old)
 if n!=1: raise SystemExit('VC7R3 NATIVE AUDIO FAIL: %s count=%d'%(label,n))
 s=s.replace(old,new,1)
once('#include <fcntl.h>\n#include <sys/wait.h>', '#include <fcntl.h>\n#include <pthread.h>\n#include <stdio.h>\n#include <sys/wait.h>', 'linux includes')
once('#include "rg35xx/golden/rg35xx_golden_video.h"\n', '#include "rg35xx/golden/rg35xx_golden_video.h"\n#include "rg35xx/rg35xx_audio_pipe.h"\n#include "rg35xx/rg35xx_media_runtime.h"\n#include "rg35xx/rg35xx_media_cache.h"\n#include "rg35xx/rg35xx_media_events.h"\n#include "rg35xx/rg35xx_media_event_queue.h"\n#include "rg35xx/rg35xx_mixer.h"\n', 'media includes')
once('#define NUM_ARGUMENTS 10\n', '#define NUM_ARGUMENTS 12\n', 'argv count')
old='''\tparams[0] = strdup("/mnt/mmc/CFW/java/bin/jamvm");
\tparams[1] = strdup(supported_encodings[characterEncoding]);
\tparams[2] = strdup("-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit");
\tparams[3] = strdup("-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment");
\tparams[4] = strdup("-Djava.awt.headless=true");
\tparams[5] = strdup("-jar");
\tparams[6] = strdup(freej2meapp);
\tparams[7] = strdup(resArg[0]);
\tparams[8] = strdup(resArg[1]);
\tparams[9] = NULL; // Null-terminate the array
'''
new='''\tparams[0] = strdup("/mnt/mmc/CFW/java/bin/jamvm");
\tparams[1] = strdup(supported_encodings[characterEncoding]);
\tparams[2] = strdup("-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit");
\tparams[3] = strdup("-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment");
\tparams[4] = strdup("-Djava.awt.headless=true");
\tparams[5] = strdup("-Dfreej2me.rg35xx=true");
\tparams[6] = strdup("-Dfreej2me.rg35xx.audio.fd=-1");
\tparams[7] = strdup("-jar");
\tparams[8] = strdup(freej2meapp);
\tparams[9] = strdup(resArg[0]);
\tparams[10] = strdup(resArg[1]);
\tparams[11] = NULL; // Null-terminate the array
'''
once(old,new,'Golden argv extension')
once('''int javaProcess;
int pRead[2];
int pWrite[2];
''','''int javaProcess;
int pRead[2];
int pWrite[2];
static struct rg35xx_audio_pipe rg35xx_java_audio_pipe = { -1, -1 };
static uint8_t *rg35xx_soundfont_bytes;
static size_t rg35xx_soundfont_size;
''','audio globals')
anchor='void retro_init(void)\n'
if s.count(anchor)!=1: raise SystemExit('VC7R3 NATIVE AUDIO FAIL: retro_init anchor')
helpers=r'''/* RG35XX-VC7R3-AUDIO-NATIVE */
#ifndef RG35XX_SOUNDFONT_PATH
#define RG35XX_SOUNDFONT_PATH "/mnt/mmc/BIOS/freej2me.sf2"
#endif
static void rg35xx_core_media_event(int event_type,uint32_t player_id,uint64_t media_time_us){if(event_type==RG35XX_MEDIA_EVENT_END_OF_MEDIA||event_type==RG35XX_MEDIA_EVENT_LOOPED)rg35xx_media_event_queue_push((uint8_t)event_type,player_id,media_time_us);}
static void rg35xx_release_soundfont_bytes(void){if(rg35xx_soundfont_bytes)free(rg35xx_soundfont_bytes);rg35xx_soundfont_bytes=NULL;rg35xx_soundfont_size=0;}
static int rg35xx_load_soundfont_bytes(void){FILE*f=fopen(RG35XX_SOUNDFONT_PATH,"rb");long z;size_t n;rg35xx_release_soundfont_bytes();if(!f){log_fn(RETRO_LOG_WARN,"RG35XX VC7R3 SoundFont unavailable; MIDI disabled.\n");return 0;}if(fseek(f,0,SEEK_END)!=0||(z=ftell(f))<=0||fseek(f,0,SEEK_SET)!=0){fclose(f);return 0;}rg35xx_soundfont_bytes=(uint8_t*)malloc((size_t)z);if(!rg35xx_soundfont_bytes){fclose(f);return 0;}n=fread(rg35xx_soundfont_bytes,1,(size_t)z,f);fclose(f);if(n!=(size_t)z){rg35xx_release_soundfont_bytes();return 0;}rg35xx_soundfont_size=n;return 1;}
static void rg35xx_send_media_event(const struct rg35xx_media_event_record*e){unsigned char q[18];uint64_t t=e->media_time_us;q[0]=14;q[1]=0;q[2]=0;q[3]=0;q[4]=13;q[5]=e->event_type;q[6]=(e->player_id>>24)&255;q[7]=(e->player_id>>16)&255;q[8]=(e->player_id>>8)&255;q[9]=e->player_id&255;q[10]=(t>>56)&255;q[11]=(t>>48)&255;q[12]=(t>>40)&255;q[13]=(t>>32)&255;q[14]=(t>>24)&255;q[15]=(t>>16)&255;q[16]=(t>>8)&255;q[17]=t&255;write_to_pipe(pWrite[1],q,sizeof(q));}
#define RG35XX_AUDIO_FRAMES_PER_RUN 735u
static int16_t rg35xx_audio_run_buffer[RG35XX_AUDIO_FRAMES_PER_RUN*2u];
static void rg35xx_pump_media_audio(void){int drained=rg35xx_audio_pipe_drain(&rg35xx_java_audio_pipe);size_t frames;if(drained<0&&rg35xx_java_audio_pipe.read_fd>=0)log_fn(RETRO_LOG_WARN,"RG35XX VC7R3 audio pipe drain failed.\n");frames=rg35xx_mixer_render(rg35xx_audio_run_buffer,RG35XX_AUDIO_FRAMES_PER_RUN);if(AudioBatch&&soundEnabled&&frames>0)AudioBatch(rg35xx_audio_run_buffer,frames);{struct rg35xx_media_event_record e;while(rg35xx_media_event_queue_pop(&e))rg35xx_send_media_event(&e);}}
static void rg35xx_native_media_init(void){rg35xx_media_cache_reset();rg35xx_media_event_queue_reset();rg35xx_mixer_init(rg35xx_core_media_event);if(rg35xx_load_soundfont_bytes()&&!rg35xx_media_runtime_init(rg35xx_soundfont_bytes,rg35xx_soundfont_size))log_fn(RETRO_LOG_WARN,"RG35XX VC7R3 MIDI runtime init failed; PCM remains available.\n");}
static void rg35xx_native_media_shutdown(void){rg35xx_audio_pipe_close(&rg35xx_java_audio_pipe);rg35xx_mixer_reset();rg35xx_media_event_queue_reset();rg35xx_media_cache_reset();rg35xx_media_runtime_shutdown();rg35xx_release_soundfont_bytes();}

'''
s=s.replace(anchor,helpers+anchor,1)
once('void retro_init(void)\n{\n','void retro_init(void)\n{\n#ifdef __linux__\n\trg35xx_native_media_init();\n#endif\n','retro init')
once('void retro_run(void)\n{\n','void retro_run(void)\n{\n#ifdef __linux__\n\trg35xx_pump_media_audio();\n#endif\n','retro_run entry pump')
needle='\tpid = fork();\n'
if s.count(needle)!=1: raise SystemExit('VC7R3 NATIVE AUDIO FAIL: fork anchor')
pre=r'''\t/* VC7R3 dedicated Java->native media FD; stdout remains video IPC. */
\trg35xx_audio_pipe_init(&rg35xx_java_audio_pipe);
\tif(rg35xx_audio_pipe_create(&rg35xx_java_audio_pipe))
\t{
\t\tint afd=rg35xx_audio_pipe_child_fd(&rg35xx_java_audio_pipe);char prop[64];
\t\tif(afd>=3){snprintf(prop,sizeof(prop),"-Dfreej2me.rg35xx.audio.fd=%d",afd);free(params[6]);params[6]=strdup(prop);}else rg35xx_audio_pipe_close(&rg35xx_java_audio_pipe);
\t}

'''
s=s.replace(needle,pre+needle,1)
once('''\tif(pid==0) /* child */
\t{

\t\tdup2(pWrite[0], fd_stdin);''','''\tif(pid==0) /* child */
\t{
\t\tif(rg35xx_java_audio_pipe.write_fd >= 0) rg35xx_audio_pipe_child_after_fork(&rg35xx_java_audio_pipe);

\t\tdup2(pWrite[0], fd_stdin);''','child fd')
# Parent formatting differs between historical/upstream revisions. The first close
# of the child stdout write-end is the stable ownership point after fork.
once('\t\tclose(pRead[1]);\n','\t\tif(rg35xx_java_audio_pipe.read_fd >= 0) rg35xx_audio_pipe_parent_after_fork(&rg35xx_java_audio_pipe);\n\t\tclose(pRead[1]);\n','parent fd close anchor')
once('''void retro_deinit(void)
{
\trg35xx_golden_video_deinit();''','''void retro_deinit(void)
{
#ifdef __linux__
\trg35xx_native_media_shutdown();
#endif
\trg35xx_golden_video_deinit();''','deinit')
for req in ('RG35XX-VC7R3-AUDIO-NATIVE','-Dfreej2me.rg35xx=true','-Dfreej2me.rg35xx.audio.fd=%d','rg35xx_pump_media_audio();','AudioBatch(rg35xx_audio_run_buffer,frames)','rg35xx_golden_video_present(','RETRO_PIXEL_FORMAT_RGB565'):
 if req not in s: raise SystemExit('VC7R3 NATIVE AUDIO FAIL missing '+req)
if s==orig: raise SystemExit('VC7R3 NATIVE AUDIO FAIL no mutation')
p.write_text(s,encoding='utf-8',newline='\n');print('VC7R3 NATIVE AUDIO OVERLAY=PASS')
