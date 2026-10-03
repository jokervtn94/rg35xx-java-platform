# P1A G2D-5 Arc Fuzz Failure Classification

Status: DIAGNOSTIC ONLY / NO RUNTIME CHANGE

CI run: 36960591721
Head analyzed: 5e3880816fb3086e66609ac7e45cc889142db334
Strict matrix: 37 fixed + 320 deterministic fuzz
Result: 37/37 fixed PASS, 27/320 fuzz FAIL

## Deterministic fuzz mapping

The gate uses seed `0x35AA2D5L` and alternates operation by index:

- even `FUZZ_i` -> `drawArc`
- odd `FUZZ_i` -> `fillArc`

Failing indices:

`7,19,47,53,67,68,75,77,89,125,127,148,157,161,167,179,181,192,203,205,208,215,241,245,259,316,319`

Classification:

- `fillArc`: 22 failures
- `drawArc`: 5 failures

## drawArc failure pattern

Failing drawArc indices:

`68,148,192,208,316`

All five are boundary/clipping cases after translation and/or explicit clip:

- 68: translated arc extends below framebuffer
- 148: translated arc extends above framebuffer
- 192: translated + explicit 1-pixel-high clip
- 208: translated arc extends through right/bottom framebuffer edge
- 316: translated arc extends through left/bottom framebuffer edge

Conclusion:

`drawArc` core ArcIterator + cubic-extrema geometry is now supported by all fixed cases. Remaining draw failures are owned by the incomplete JDK8 ProcessPath draw clipping/endpoint path, not by ArcIterator geometry.

Do not change ArcIterator or cubic extrema splitting again without contrary evidence.

## fillArc failure pattern

Failing fillArc indices:

`7,19,47,53,67,75,77,89,125,127,157,161,167,179,181,203,205,215,241,245,259,319`

Broad classification:

- 12 partial-offscreen ordinary geometry
- 5 fully in-bounds ordinary geometry
- 2 fully in-bounds thin geometry (`w<=2` or `h<=2`)
- 2 partial-offscreen thin geometry
- 1 partial-offscreen explicit-clip geometry

Important consequence:

The current `fillArc` integer ellipse/parameter-sector shortcut is NOT canonical-equivalent in general. Failures are not limited to clipping. Because several failures are fully in-bounds, further boundary-only patching would be incorrect.

The shortcut must remain REJECTED until replaced with the actual JDK8 fill path behavior (Arc2D.PIE -> shape fill -> ProcessPath/shape pipeline as characterized for this runtime) or another implementation that proves exact differential equivalence over the strict matrix.

## Locked next split

G2D must now be treated as two independent host work units:

1. `G2D-DRAW-CLIP`: preserve accepted drawArc geometry; implement the missing canonical ProcessPath clipping/endpoint behavior only.
2. `G2D-FILL-CANONICAL`: reject the lattice-sector approximation as the final implementation and reproduce canonical fill raster behavior.

No physical test is authorized.
No other graphics module is opened.
No Core2D/audio/input/video/RMS/JamVM/glibj change is authorized.
