#!/usr/bin/env python3
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: stage-a7-platformplayer-java6-paths.py <repo-root>')

root = Path(sys.argv[1]).resolve()
rel = Path('build/a3/stage-src/org/recompile/mobile/PlatformPlayer.java')
path = root / rel
if not path.is_file():
    raise SystemExit('A7_PLATFORMPLAYER_JAVA6_STAGE_FAIL missing=' + str(rel))

text = path.read_text(encoding='utf-8')

imports = [
    'import java.nio.file.Files;\n',
    'import java.nio.file.Paths;\n',
]
for imp in imports:
    count = text.count(imp)
    if count != 1:
        raise SystemExit('A7_PLATFORMPLAYER_JAVA6_STAGE_FAIL import_drift=%r count=%d' % (imp.strip(), count))
    text = text.replace(imp, '', 1)

old = '\t\t\t\t\tFiles.createDirectories(Paths.get(rmsPath));'
new = ('\t\t\t\t\tFile rmsDir = new File(rmsPath);\n'
       '\t\t\t\t\tif (!rmsDir.isDirectory() && !rmsDir.mkdirs() && !rmsDir.isDirectory())\n'
       '\t\t\t\t\t{\n'
       '\t\t\t\t\t\tthrow new Exception("Cannot create media RMS directory: " + rmsPath);\n'
       '\t\t\t\t\t}')
count = text.count(old)
if count != 2:
    raise SystemExit('A7_PLATFORMPLAYER_JAVA6_STAGE_FAIL createDirectories_drift expected=2 found=%d' % count)
text = text.replace(old, new)

# Guard the intended compatibility scope: no active java.nio.file dependency may
# remain in PlatformPlayer, while both MIDI and WAV cache paths still use the
# same rmsPath variable and java.io.File-based directory semantics.
if 'java.nio.file.' in text or 'Files.createDirectories' in text or 'Paths.get(' in text:
    raise SystemExit('A7_PLATFORMPLAYER_JAVA6_STAGE_FAIL nio_reference_remains')
if text.count('Cannot create media RMS directory: ') != 2:
    raise SystemExit('A7_PLATFORMPLAYER_JAVA6_STAGE_FAIL replacement_count')
if text.count('String rmsPath = "./rms/"+Mobile.getPlatform().loader.suitename;') != 2:
    raise SystemExit('A7_PLATFORMPLAYER_JAVA6_STAGE_FAIL rms_path_semantic_drift')

path.write_text(text, encoding='utf-8')
print('A7_PLATFORMPLAYER_JAVA6_PATH_COMPAT=PASS')
print('A7_PLATFORMPLAYER_COMPAT_SCOPE=MEDIA_CACHE_DIRECTORY_CREATION_ONLY')
print('A7_PLATFORMPLAYER_COMPAT_IMPL=JAVA_IO_FILE_MKDIRS')
print('A7_PLATFORMPLAYER_PLAYER_STATE_MACHINE=UNCHANGED_BY_STAGE')
print('A7_PLATFORMPLAYER_CANONICAL_GITLINK_MUTATED=NO')
