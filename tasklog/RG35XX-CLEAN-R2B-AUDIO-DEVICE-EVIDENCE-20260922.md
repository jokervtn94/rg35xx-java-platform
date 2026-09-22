# RG35XX Clean R2B Audio — Real Device Evidence 2026-09-22

Evidence archive: `RG35XX-R2B-AUDIO-EVIDENCE-20260922-143113.zip`

## Installed identities

- R2B runtime aliases: `202714a2509b9c7e62accc925f24cea3d0d1b1d47d3699b015bf8605da3ae929`
- R2B reconstructed core: `54803dfbbea9ed73fdc519f7f7441df79abcc135838b7b8e37e8a04fa6547d51`
- SoundFont: `c5378b62028c920cb11e4803327983fee2f2cdff5dc89c708e39da417e51c854`
- JamVM L: `eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`
- glibj: `d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea`

Installer result: PASS.

## User physical-device report

- Audio: audible.
- Game freeze/stall: still present.
- Transparent/background image defect: still present.

## Java evidence

Collector summary:
- `GETSEQUENCER_ERRORS=0`
- `CLIP_ERRORS=0`
- `MEDIAWARMUP=0`
- `DEV_SND_SEQ=0`

Direct recount of Java log:
- `NoSuchMethodError: getSequencer = 0`
- `LineUnavailableException = 0`
- `AbstractGraphics2D.renderScanline = 23`
- `NullPointerException = 23`
- `Zone.combineWithSubGlyph = 0`
- `RG35XX-R2A-IMAGE-NORMALIZE = 24`
- `RG35XX-B4-FRAME-BIND = 48`
- `mismatch=true = 0`
- ImageIO read/null failures = 0

The 23 renderScanline/NPE failures are in the NinjaSchool session and match the known exact-R2A GNU AWT font path. R2B deliberately did not include R2C-FONT, so this is an inherited known font blocker, not evidence that native audio failed.

## Native/early evidence

Four game sessions reached:
`CORE_INIT -> JAVA_READY -> LOAD_GAME -> IPC_RUN_SENT -> FIRST_FRAME_PUBLISH`.

Three sessions reached `CORE_DEINIT`:
- Dragon Mania
- Real Football 2015
- NinjaSchool1

The final KDTT session reached first frame but no `CORE_DEINIT` appears in collected early log.

No `freej2me-core.log` was present in the evidence archive, so worker/ring callback markers cannot be independently confirmed from this evidence set.

## Classification

### Audio
The device report plus Java evidence proves that the target-native route removed the prior desktop JavaSound failure boundary and produced audible sound.

- AUDIO_RESULT = DEVICE-EVIDENCE
- `getSequencer` regression = absent
- JavaSound Clip failure = absent
- eager media boot regression = absent
- R2B AUDIO DEVICE-PASS = NO

DEVICE-PASS is not assigned because:
1. the acceptance criteria included responsive real games while audio is active;
2. the final KDTT session did not cleanly deinitialize in collected evidence;
3. native worker/ring markers were not captured.

### Freeze
- FREEZE = FAIL / unresolved overall.
- NinjaSchool has a directly observed inherited font/AWT crash path.
- KDTT final-session hang point is not localized by the current evidence.

### Transparency/background
- TRANSPARENCY = FAIL / unchanged as expected.
- R2B intentionally preserves R2A image/transparency behavior.
- The correct next independent checkpoint for this symptom remains R2D-TRANSPARENCY.

## Comparison with R2C-FONT evidence

R2C-FONT real-device evidence previously showed:
- `R2D_FONT_READY=3`
- `ZONE_AIOOBE=0`
- `RENDER_SCANLINE_NPE=0`
- `GETSEQUENCER_ERRORS=2`

R2B now shows the inverse:
- audio JavaSound errors removed;
- R2A font renderScanline failures returned.

This is expected from the one-primary-variable A/B policy and confirms that Font and Audio are independent blockers.

## Next action

1. Restore R2B to exact R2A using its rollback script.
2. Verify exact R2A identities.
3. Test R2D-TRANSPARENCY independently against the visible white-background defect.
4. Do not combine R2C + R2B + R2D until each subsystem has independent device evidence and an explicit consolidation checkpoint is defined.
5. Keep screenshot capture and KDTT hang localization separate.

## Status

- R2B BUILD-PASS=YES
- R2B AUDIO=DEVICE-EVIDENCE
- R2B DEVICE-PASS=NO
- TRANSPARENCY=FAIL
- FREEZE=FAIL
- STABLE=NO
