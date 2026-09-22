#!/bin/sh
OUT=/mnt/mmc/RG35XX-DP-R1-EVIDENCE
rm -rf "$OUT"; mkdir -p "$OUT"
for f in /mnt/mmc/RG35XX-DP-R1-*.txt; do [ -f "$f" ] && cp "$f" "$OUT/"; done
for f in /mnt/mmc/RG35XX-MIYOO-M1.14-R6-SCREENSHOT.bmp /mnt/mmc/RG35XX-MIYOO-M1.14-R6-LIVE-FRAME.txt; do [ -f "$f" ] && cp "$f" "$OUT/"; done
( cd /mnt/mmc && tar czf RG35XX-DP-R1-EVIDENCE.tar.gz RG35XX-DP-R1-EVIDENCE 2>/dev/null ) || true
sync
