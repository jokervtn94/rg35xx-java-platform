#!/usr/bin/env python3
"""CV: boot FreeJ2ME at the JAR's logical resolution on RG35XX.

This transform runs after the Golden G1 native overlay.  It fixes the lifecycle
mistake proven by device logs: JamVM/MobilePlatform was started in retro_init()
at the core-option resolution (240x320), while the actual JAR path is only known
later in retro_load_game().  Resizing after Java boot leaves Canvas/Display and
frame transport state split across old/new LCD objects.

CV therefore:
  * defers javaOpen() from retro_init() to retro_load_game();
  * resolves an explicit WxH token from the JAR filename before javaOpen();
  * passes that WxH as the original Libretro constructor arguments;
  * locks screenRes to that boot resolution for subsequent option updates.

The transform is fail-closed against the pinned FreeJ2ME source shape used by
scripts/golden_g1_assemble.sh.  It intentionally does not guess a resolution
when the filename has no explicit WxH token; in that case core-option resolution
remains the fallback.
"""

import pathlib
import re
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: cv_apply_boot_resolution.py <src/libretro/freej2me_libretro.c>")

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
orig = s


def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit("CV BOOT RESOLUTION FAIL: %s marker count=%d" % (label, n))
    s = s.replace(old, new, 1)


def replace_function(source, signature, replacement):
    start = source.find(signature)
    if start < 0:
        raise SystemExit("CV BOOT RESOLUTION FAIL: function not found: " + signature)
    brace = source.find("{", start)
    if brace < 0:
        raise SystemExit("CV BOOT RESOLUTION FAIL: opening brace not found: " + signature)
    depth = 0
    i = brace
    while i < len(source):
        c = source[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return source[:start] + replacement.rstrip() + source[i + 1:]
        i += 1
    raise SystemExit("CV BOOT RESOLUTION FAIL: unterminated function: " + signature)


# ---------------------------------------------------------------------------
# Resolution lock state.  It must be visible to check_variables(), because
# check_variables() normally re-reads the 240x320 core option and immediately
# sends it back to Java after a game is loaded.
# ---------------------------------------------------------------------------
state_marker = "float normal_throttle_rate = DEFAULT_FPS;\n"
state = r'''

/* CV: per-game boot resolution.  Once Java is launched for a JAR, every later
 * config update must retain the same LCD size for the lifetime of that JVM. */
static bool rg35xx_cv_resolution_locked = false;
static unsigned long rg35xx_cv_width = 0;
static unsigned long rg35xx_cv_height = 0;
'''
once(state_marker, state_marker + state, "CV resolution state")

# Force any post-boot FJ2ME_LR_OPTS update to preserve the dimensions used to
# construct MobilePlatform.  This is deliberately inserted after all option
# reads and immediately before the options_update string is generated.
opts_marker = "\t/* Prepare a string to pass those core options to the Java app */\n"
opts_lock = r'''
	/* CV: do not let a later core-option refresh resize a live Java platform. */
	if (rg35xx_cv_resolution_locked)
	{
		screenRes[0] = rg35xx_cv_width;
		screenRes[1] = rg35xx_cv_height;
	}

'''
once(opts_marker, opts_lock + opts_marker, "lock config resolution")

# ---------------------------------------------------------------------------
# Helpers inserted immediately before retro_init().
# ---------------------------------------------------------------------------
retro_init_sig = "void retro_init(void)\n"
if s.count(retro_init_sig) != 1:
    raise SystemExit("CV BOOT RESOLUTION FAIL: retro_init signature count=%d" % s.count(retro_init_sig))

helpers = r'''
/* CV: accept only an explicit filename token such as 240x320, 320x240,
 * 352x416 or 360x640.  Values outside the Golden 800x800 transport contract
 * are rejected.  This avoids treating unrelated model/version numbers as a
 * display size. */
static bool rg35xx_cv_resolution_from_path(const char *path,
                                           unsigned long *out_w,
                                           unsigned long *out_h)
{
	const char *name;
	const char *p;
	if(!path || !out_w || !out_h) return false;
	name = strrchr(path, '/');
	name = name ? name + 1 : path;

	for(p = name; *p; ++p)
	{
		char *endw;
		char *endh;
		unsigned long w;
		unsigned long h;
		if(*p < '0' || *p > '9') continue;
		if(p > name && p[-1] >= '0' && p[-1] <= '9') continue;

		w = strtoul(p, &endw, 10);
		if(endw == p || (*endw != 'x' && *endw != 'X')) continue;
		h = strtoul(endw + 1, &endh, 10);
		if(endh == endw + 1) continue;
		if(*endh >= '0' && *endh <= '9') continue;
		if(w < 96 || h < 96 || w > 800 || h > 800) continue;

		*out_w = w;
		*out_h = h;
		return true;
	}
	return false;
}

static bool rg35xx_cv_launch_java(const char *rom_path)
{
	char resArg[2][4];
	unsigned long detected_w = 0;
	unsigned long detected_h = 0;

	/* Read the user's non-resolution options first while the resolution lock is
	 * still open.  No pipe write occurs because booted is false. */
	check_variables();

	if(rg35xx_cv_resolution_from_path(rom_path, &detected_w, &detected_h))
	{
		rg35xx_cv_width = detected_w;
		rg35xx_cv_height = detected_h;
		log_fn(RETRO_LOG_INFO, "RG35XX-CV: boot resolution filename=%lux%lu.\\n",
		       rg35xx_cv_width, rg35xx_cv_height);
	}
	else
	{
		rg35xx_cv_width = screenRes[0];
		rg35xx_cv_height = screenRes[1];
		log_fn(RETRO_LOG_INFO, "RG35XX-CV: no filename resolution; fallback=%lux%lu.\\n",
		       rg35xx_cv_width, rg35xx_cv_height);
	}

	screenRes[0] = rg35xx_cv_width;
	screenRes[1] = rg35xx_cv_height;
	rg35xx_cv_resolution_locked = true;

	sprintf(resArg[0], "%lu", rg35xx_cv_width);
	sprintf(resArg[1], "%lu", rg35xx_cv_height);

	params = (char**)malloc(sizeof(char*) * NUM_ARGUMENTS);
	if(!params) return false;
#ifdef __linux__
	params[0] = strdup("/mnt/mmc/CFW/java/bin/jamvm");
	params[1] = strdup(supported_encodings[characterEncoding]);
	params[2] = strdup("-Dawt.toolkit=gnu.java.awt.peer.headless.HeadlessToolkit");
	params[3] = strdup("-Djava.awt.graphicsenv=gnu.java.awt.peer.headless.HeadlessGraphicsEnvironment");
	params[4] = strdup("-Djava.awt.headless=true");
	params[5] = strdup("-jar");
	params[6] = strdup(freej2meapp);
	params[7] = strdup(resArg[0]);
	params[8] = strdup(resArg[1]);
	params[9] = NULL;
#elif _WIN32
	/* CV is an RG35XX/Linux architecture phase. */
	free(params);
	params = NULL;
	return false;
#endif

	log_fn(RETRO_LOG_INFO, "RG35XX-CV: launching Java at %lux%lu before MIDlet load.\\n",
	       rg35xx_cv_width, rg35xx_cv_height);
	booted = javaOpen(params[0], params);

	if(params)
	{
		int i;
		for(i = 0; params[i] != NULL; ++i) free(params[i]);
		free(params);
		params = NULL;
	}

	if(!booted)
	{
		rg35xx_cv_resolution_locked = false;
		Environ(RETRO_ENVIRONMENT_SET_MESSAGE_EXT, (void*)&messages[COULD_NOT_START_MSG]);
		return false;
	}
	return true;
}

'''
s = s.replace(retro_init_sig, helpers + retro_init_sig, 1)

# ---------------------------------------------------------------------------
# retro_init now prepares the core/system path only.  Crucially it does NOT
# construct JamVM/MobilePlatform before the JAR path is known.
# ---------------------------------------------------------------------------
new_retro_init = r'''void retro_init(void)
{
	/* init buffers, structs */
	memset(frame, 0, frameSize);
	memset(frameBuffer, 0, frameBufferSize);

	rg35xx_cv_resolution_locked = false;
	rg35xx_cv_width = 0;
	rg35xx_cv_height = 0;
	booted = false;

	/* Establish core-option defaults, but defer Java startup until load_game. */
	check_variables();

	if (restarting) { log_fn(RETRO_LOG_INFO, "Restarting FreeJ2ME-Plus.\\n"); }
	else
	{
		log_fn(RETRO_LOG_INFO, "Setting up FreeJ2ME-Plus' System Path.\\n");
		Environ(RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY, &systemPath);
	}

	/* Validate the runtime JAR now, without launching it. */
	{
		char *freej2mePath = malloc(sizeof(char) * PIPE_MAX_LEN);
		if(!freej2mePath) return;
		snprintf(freej2mePath, sizeof(char) * PIPE_MAX_LEN, "%s/%s", systemPath, freej2meapp);
		if (!freej2me_present(freej2mePath))
		{
			free(freej2mePath);
			Environ(RETRO_ENVIRONMENT_SET_MESSAGE_EXT, (void*)&messages[SYSTEM_NOT_FOUND_MSG]);
			log_fn(RETRO_LOG_ERROR, "Error: %s does not exist in the system dir.\\n", freej2meapp);
			return;
		}
		free(freej2mePath);
	}

	/* Input interfaces do not depend on the Java process. */
	{
		struct retro_keyboard_callback kb = { Keyboard };
		Environ(RETRO_ENVIRONMENT_SET_KEYBOARD_CALLBACK, &kb);
	}
	if (Environ(RETRO_ENVIRONMENT_GET_RUMBLE_INTERFACE, &rumble))
		log_fn(RETRO_LOG_INFO, "Rumble environment supported.\\n");
	else
		log_fn(RETRO_LOG_INFO, "Rumble environment not supported.\\n");

	log_fn(RETRO_LOG_INFO, "RG35XX-CV: core ready; Java launch deferred to retro_load_game.\\n");
	Environ(RETRO_ENVIRONMENT_SET_MESSAGE_EXT, (void*)&messages[CORE_HAS_LOADED_MSG]);
}'''
s = replace_function(s, "void retro_init(void)", new_retro_init)

# ---------------------------------------------------------------------------
# Launch Java as the first load_game action, while the actual JAR path is
# available.  Everything after that retains upstream/Golden ordering.
# ---------------------------------------------------------------------------
load_sig = "bool retro_load_game(const struct retro_game_info *info)"
start = s.find(load_sig)
if start < 0:
    raise SystemExit("CV BOOT RESOLUTION FAIL: retro_load_game missing")
brace = s.find("{", start)
insert = r'''
	/* CV lifecycle barrier: MobilePlatform is constructed only now, with the
	 * resolution selected for this exact JAR. */
	if(!booted && !rg35xx_cv_launch_java(info->path)) return false;

'''
s = s[:brace + 1] + "\n" + insert + s[brace + 1:]

# Guardrails.
required = (
    "RG35XX-CV: core ready; Java launch deferred to retro_load_game",
    "rg35xx_cv_launch_java(info->path)",
    "rg35xx_cv_resolution_from_path",
    "rg35xx_cv_resolution_locked",
    "screenRes[0] = rg35xx_cv_width",
    "params[7] = strdup(resArg[0])",
    "params[8] = strdup(resArg[1])",
)
for token in required:
    if token not in s:
        raise SystemExit("CV BOOT RESOLUTION FAIL: required token missing: " + token)

# javaOpen must now be owned only by the CV helper, not retro_init.
if s.count("booted = javaOpen(params[0], params);") != 1:
    raise SystemExit("CV BOOT RESOLUTION FAIL: javaOpen ownership count=%d" %
                     s.count("booted = javaOpen(params[0], params);"))

if s == orig:
    raise SystemExit("CV BOOT RESOLUTION FAIL: no mutation")

p.write_text(s, encoding="utf-8", newline="\n")
print("CV BOOT RESOLUTION PASS:", p)
