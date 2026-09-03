/*
 * RG35XX TinySoundFont/TinyMidiLoader implementation owner.
 *
 * Dependency versions are pinned by docs/RC1-TML-TSF-DEPENDENCY-GATE.md.
 * The vendored upstream headers are expected to provide their implementation
 * exactly once through this translation unit. Keep rg35xx_tsf_worker.c as the
 * RG35XX playback/timing owner; do not define TSF_IMPLEMENTATION or
 * TML_IMPLEMENTATION anywhere else in the native tree.
 *
 * File I/O is intentionally disabled: RG35XX media ownership loads both MIDI
 * and SoundFont data from memory, so the synth layer never invents a device
 * filesystem path.
 */
#define TSF_NO_STDIO
#define TML_NO_STDIO
#define TSF_IMPLEMENTATION
#include "tsf.h"
#define TML_IMPLEMENTATION
#include "tml.h"
