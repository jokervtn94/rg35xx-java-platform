#!/usr/bin/env python3
import pathlib, sys
base = pathlib.Path(__file__).with_name('vc7r22r22_apply_filebacked_midi.py')
s = base.read_text()
old = "if anchor not in s or 'cacheMidiToFile' in s:\n    raise SystemExit('NativePlayer helper anchor mismatch/already patched')"
new = "if anchor not in s or 'private static File cacheMidiToFile(' in s:\n    raise SystemExit('NativePlayer helper anchor mismatch/already patched')"
if old not in s:
    raise SystemExit('R2.2 v2 wrapper: expected v1 guard not found')
s = s.replace(old, new, 1)
code = compile(s, str(base), 'exec')
exec(code, {'__name__':'__main__','__file__':str(base)})
