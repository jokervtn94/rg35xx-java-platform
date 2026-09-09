#!/usr/bin/env python3
"""B4 early native observability overlay for the verified clean RG35XX core.

Applies after vc0_vc3_assemble.sh/G1 overlay. It must not change video, media,
resolution, Java runtime or compatibility behavior. It only records native
lifecycle checkpoints using direct append/write/fsync so evidence exists even
when Java never reaches its own logging path.
"""
import pathlib
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: b4_apply_early_native_log.py <freej2me_libretro.c>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s


def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("B4 EARLY LOG FAIL: %s marker count=%d" % (label, n))
    s = s.replace(old, new, 1)

marker = 'float normal_throttle_rate = DEFAULT_FPS;\n'
helper = r'''

#define RG35XX_B4_EARLY_LOG "/mnt/mmc/freej2me-vc3-early.log"

static void rg35xx_b4_log(const char *fmt, ...)
{
#ifdef __linux__
    char line[768];
    int fd;
    int n;
    va_list ap;
    va_start(ap, fmt);
    n = vsnprintf(line, sizeof(line), fmt, ap);
    va_end(ap);
    if(n < 0) return;
    if(n >= (int)sizeof(line)) n = (int)sizeof(line) - 1;
    if(n == 0 || line[n - 1] != '\n')
    {
        if(n < (int)sizeof(line) - 1) line[n++] = '\n';
    }
    fd = open(RG35XX_B4_EARLY_LOG, O_WRONLY | O_CREAT | O_APPEND, 0644);
    if(fd < 0) return;
    (void)write(fd, line, (size_t)n);
    (void)fsync(fd);
    close(fd);
#else
    (void)fmt;
#endif
}
'''
once(marker, marker + helper, "early logger helper")

once('void retro_init(void)\n{\n\t/* init buffers, structs */', 'void retro_init(void)\n{\n\trg35xx_b4_log("B4 CORE_INIT pid=%ld", (long)getpid());\n\t/* init buffers, structs */', "retro_init entry")
once('\tif (!freej2me_present(freej2mePath))\n\t{', '\trg35xx_b4_log("B4 RUNTIME_PATH path=%s", freej2mePath);\n\tif (!freej2me_present(freej2mePath))\n\t{\n\t\trg35xx_b4_log("B4 RUNTIME_MISSING path=%s errno=%d", freej2mePath, errno);', "runtime path checkpoint")
once('\tbooted = javaOpen(params[0], params);\n', '\trg35xx_b4_log("B4 JAVA_OPEN_BEGIN cmd=%s", params[0]);\n\tbooted = javaOpen(params[0], params);\n\trg35xx_b4_log("B4 JAVA_OPEN_END booted=%d pid=%d", booted ? 1 : 0, javaProcess);\n', "javaOpen caller checkpoint")
once('bool retro_load_game(const struct retro_game_info *info)\n{\n\tint len = 0;', 'bool retro_load_game(const struct retro_game_info *info)\n{\n\tint len = 0;\n\trg35xx_b4_log("B4 LOAD_GAME_ENTER info=%p path=%s", (void*)info, (info && info->path) ? info->path : "<null>");', "retro_load_game entry")
once('#ifdef __linux__\n\trealpath(info->path, romPath);', '#ifdef __linux__\n\tif(realpath(info->path, romPath) == NULL)\n\t{\n\t\trg35xx_b4_log("B4 GAME_REALPATH_FAIL path=%s errno=%d", info->path, errno);\n\t\tromPath[0] = \'\\0\';\n\t}\n\telse rg35xx_b4_log("B4 GAME_PATH path=%s", romPath);', "game realpath checkpoint")
once('\twrite_to_pipe(pWrite[1], loadevent, 5);\n\twrite_to_pipe(pWrite[1], (unsigned char*) romPath, len);', '\trg35xx_b4_log("B4 IPC_LOAD_BEGIN len=%d", len);\n\twrite_to_pipe(pWrite[1], loadevent, 5);\n\twrite_to_pipe(pWrite[1], (unsigned char*) romPath, len);\n\trg35xx_b4_log("B4 IPC_LOAD_SENT len=%d", len);', "LOAD IPC checkpoint")
once('\twrite_to_pipe(pWrite[1], startupevent, 5);\n\n\tif(!rg35xx_golden_video_init(', '\trg35xx_b4_log("B4 IPC_RUN_BEGIN");\n\twrite_to_pipe(pWrite[1], startupevent, 5);\n\trg35xx_b4_log("B4 IPC_RUN_SENT");\n\n\tif(!rg35xx_golden_video_init(', "RUN IPC checkpoint")
once('bool javaOpen(char *cmd, char **params)\n{\n\tif(!restarting)', 'bool javaOpen(char *cmd, char **params)\n{\n\trg35xx_b4_log("B4 JAVAOPEN_ENTER cmd=%s", cmd ? cmd : "<null>");\n\tif(!restarting)', "javaOpen entry")

# errno is meaningful only when the corresponding syscall fails. Do not log
# stale errno values on successful pipe/fork calls.
once('\tpipe(pRead); /* 0: pRead, 1: pWrite */\n\tpipe(pWrite);\n\n\tpid = fork();', '\t{\n\t\tint rc_read;\n\t\tint err_read = 0;\n\t\tint rc_write;\n\t\tint err_write = 0;\n\t\terrno = 0;\n\t\trc_read = pipe(pRead);\n\t\tif(rc_read != 0) err_read = errno;\n\t\terrno = 0;\n\t\trc_write = pipe(pWrite);\n\t\tif(rc_write != 0) err_write = errno;\n\t\trg35xx_b4_log("B4 PIPE_CREATE read_rc=%d read_errno=%d write_rc=%d write_errno=%d", rc_read, err_read, rc_write, err_write);\n\t\tif(rc_read != 0 || rc_write != 0) return false;\n\t}\n\n\trg35xx_b4_log("B4 FORK_BEGIN");\n\terrno = 0;\n\tpid = fork();\n\t{\n\t\tint fork_errno = (pid < 0) ? errno : 0;\n\t\trg35xx_b4_log("B4 FORK_RESULT pid=%d errno=%d", pid, fork_errno);\n\t}', "pipe/fork checkpoint")

once('\t\tchdir(systemPath);\n\n\t\texecv(cmd, params);\n\n\t\t/* execv failure! */\n\t\t_exit(127);', '\t\trg35xx_b4_log("B4 CHILD_PRE_EXEC pid=%ld cmd=%s system=%s", (long)getpid(), cmd, systemPath ? systemPath : "<null>");\n\t\tif(chdir(systemPath) != 0) rg35xx_b4_log("B4 CHILD_CHDIR_FAIL errno=%d", errno);\n\n\t\texecv(cmd, params);\n\n\t\t/* execv failure! */\n\t\trg35xx_b4_log("B4 CHILD_EXEC_FAIL errno=%d", errno);\n\t\t_exit(127);', "child exec checkpoint")
once('\tif(pid>0) /* parent */\n\t{\n\t\tclose(pRead[1]);', '\tif(pid>0) /* parent */\n\t{\n\t\trg35xx_b4_log("B4 PARENT_CHILD_STARTED child_pid=%d", pid);\n\t\tclose(pRead[1]);', "parent child checkpoint")
once('\telse\n\t{\n\t\tlog_fn(RETRO_LOG_INFO, "Core and Java app started! Initializing game data... \\n");\n\t\treturn true;\n\t}', '\telse\n\t{\n\t\trg35xx_b4_log("B4 JAVA_READY pid=%d status=%d token=%d", javaProcess, status, t);\n\t\tlog_fn(RETRO_LOG_INFO, "Core and Java app started! Initializing game data... \\n");\n\t\treturn true;\n\t}', "Java READY checkpoint")
once('void retro_deinit(void)\n{\n\trg35xx_golden_video_deinit();', 'void retro_deinit(void)\n{\n\trg35xx_b4_log("B4 CORE_DEINIT pid=%ld java_pid=%d", (long)getpid(), javaProcess);\n\trg35xx_golden_video_deinit();', "deinit checkpoint")

required = ('RG35XX_B4_EARLY_LOG', 'B4 CORE_INIT', 'B4 RUNTIME_PATH', 'B4 JAVA_OPEN_BEGIN', 'B4 LOAD_GAME_ENTER', 'B4 GAME_PATH', 'B4 IPC_LOAD_SENT', 'B4 IPC_RUN_SENT', 'B4 PIPE_CREATE', 'B4 FORK_RESULT', 'B4 CHILD_PRE_EXEC', 'B4 CHILD_EXEC_FAIL', 'B4 PARENT_CHILD_STARTED', 'B4 JAVA_READY', 'B4 CORE_DEINIT')
for token in required:
    if token not in s:
        raise SystemExit("B4 EARLY LOG FAIL: required marker missing: " + token)
for forbidden in ('RG35XX-PNG-COMPAT', 'rg35xxStripPngICCP', 'RG35XX-CV:', 'RG35XX-MediaWarmup'):
    if forbidden in s:
        raise SystemExit("B4 EARLY LOG FAIL: unadmitted feature present: " + forbidden)
if s == orig:
    raise SystemExit("B4 EARLY LOG FAIL: no mutation")
p.write_text(s, encoding="utf-8", newline="\n")
print("B4 EARLY NATIVE LOG PASS:", p)
