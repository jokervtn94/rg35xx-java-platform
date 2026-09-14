#!/usr/bin/env python3
"""Remove historical per-frame RG35XX-JAVA-DIAG writes from Golden transport.

Error diagnostics are preserved. This runs on the pristine G1 transport before
any VC7R diagnostic probe is admitted.
"""
from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: from_zero_cleanup_transport_logs.py <RG35XXGoldenFrameTransport.java>')

p=Path(sys.argv[1])
s=p.read_text(encoding='utf-8')
lines=s.splitlines(True)
out=[]
removed=0
i=0
while i < len(lines):
    line=lines[i]
    if 'System.err.println(' in line:
        stmt=line
        j=i
        while ');' not in stmt and j+1 < len(lines):
            j += 1
            stmt += lines[j]
        if 'RG35XX-JAVA-DIAG:' in stmt:
            removed += 1
            i=j+1
            continue
    out.append(line)
    i += 1
s=''.join(out)

# Required fault logs stay available.
for req in ('RG35XX-VIDEO JAVA worker error', 'RG35XX-VIDEO JAVA control-frame error'):
    if req not in s:
        raise SystemExit('FROM_ZERO LOG CLEAN FAIL required error log lost: '+req)

# Fail closed if any executable JAVA-DIAG println remains.
lines=s.splitlines(True); i=0
while i < len(lines):
    if 'System.err.println(' in lines[i]:
        stmt=lines[i]; j=i
        while ');' not in stmt and j+1 < len(lines):
            j+=1; stmt+=lines[j]
        if 'RG35XX-JAVA-DIAG:' in stmt:
            raise SystemExit('FROM_ZERO LOG CLEAN FAIL executable JAVA-DIAG survived')
        i=j+1; continue
    i+=1

p.write_text(s, encoding='utf-8', newline='\n')
print('FROM_ZERO_TRANSPORT_LOG_CLEAN=PASS')
print('REMOVED_JAVA_DIAG_WRITES=%d' % removed)
print('ERROR_DIAGNOSTICS=PRESERVED')
