# RG35XX FreeJ2ME Port — LOCKED ENGINEERING RULER v1

Status: LOCKED
Date: 2026-10-01
Project: Port FreeJ2ME to original RG35XX
Repository: jokervtn94/rg35xx-java-platform

This document is the highest-priority project ruler for all future chats.
If any later task, assumption, remembered build, old branch, test candidate, or assistant proposal conflicts with this ruler, THIS RULER WINS.

---

## 0. PROJECT GOAL

Port the proven Aweigit FreeJ2ME Miyoo implementation to the original RG35XX with the smallest RG35XX-specific boundary adaptations possible.

The goal is NOT:
- to redesign FreeJ2ME;
- to create a new J2ME runtime;
- to fix every game by adding game-specific behavior;
- to repeatedly patch whichever primitive the current game happens to touch;
- to optimize by speculation.

The goal IS:

canonical Aweigit behavior
-> original RG35XX hardware contract
-> smallest required boundary adapters
-> regression against already proven real-game behavior
-> physical original-RG35XX acceptance
-> stable promotion

---

## 1. AUTHORITY ORDER — MUST NEVER BE REVERSED

When deciding what code or behavior is correct, use this exact order:

1. Pinned canonical Aweigit source/behavior.
2. Measured original-RG35XX hardware/runtime contract.
3. Previously accepted original-RG35XX physical DEVICE-PASS evidence.
4. Exact current real-game evidence with filename + SHA256 + logs + physical observation.
5. Controlled diagnostic experiments.
6. New implementation ideas only as a last resort after 1-5 cannot provide the required behavior.

Never allow item 5 or 6 to override items 1-3 merely because a current test game fails.

---

## 2. LOCKED CANONICAL PINS

Canonical upstream:
- repository: aweigit/freej2me-miyoomini
- commit: ca11dfe8ea1cc273d92460f9a83bbf192023fa63

Protected runtime:
- JamVM SHA256:
  eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34
- glibj SHA256:
  d7abe888d2980329434c30f18c0eec124be1f02284bf9ed28e88d7242a1f2bea

Stable branch:
- rg35xx-aweigit-r1-stable
- stable reset/base SHA:
  e7b0860310fd5204e1d1f2d01c992002b8660df2

Accepted A8 physical platform identity:
- freej2me-rg35xx.jar:
  057567d454ac94d4d1d08ad8fc84ef22515c00418d28057aa70e74b4042d336c
- librg35xx_input.so:
  69a8aeb3940bfbc234f3a562a7ae4bcaea10b50f8a8f2c38ad229a5430930f6d
- librg35xx_video.so:
  c6687c0a43b24b425af0727c928afb5414da811ecbcbbe3538928470abe8bd0d
- libaudio.so:
  4522157846c33c150a85c50b4bed6f68351f1c62d54b8cd7805cbb97c5727644
- audio-prime PCM:
  8c30691e755abd6791ac75887b56e20f1a56266b2eb0286bfb4007b98f7d7a7e

Canonical A8 restore package:
- RG35XX-A8-CANONICAL-RESTORE-R2.zip
- SHA256:
  4dc31da132708106683d1ec671a2f2817dc14d33f84551b854d0d2aa35cd3db3

These identities may not be silently replaced by a rebuilt "equivalent" artifact.

---

## 3. GOLDEN ORIGINAL-RG35XX DEVICE CONTRACT

A8 is the GOLDEN RG35XX baseline.

Accepted physical real-game regression:

### Vua Cướp Biển
- display: PASS
- input: PASS
- gameplay: PASS
- no hang: PASS

### God of War
- display: PASS
- input: PASS
- gameplay: PASS
- no hang: PASS
- audio: PASS

Accepted protected behavior also includes:
- Raw2D graphics chain already proven by accepted A4/A5/A6 work;
- PNG/alpha;
- drawRegion;
- ClipTranslate;
- input lifecycle;
- PERF-A1 presenter;
- RMS;
- Java 6 media compatibility;
- SDL1_mixer bridge;
- RG35XX audio-route prime.

A candidate that fixes a new game but breaks any golden behavior is REJECTED.

---

## 4. HARD PROHIBITIONS

The assistant MUST NOT:

1. Use a failing compatibility game as the architecture driver for the whole runtime.
2. Enter a loop of:
   game error -> micro-fix -> new error -> micro-fix -> repeat.
3. Invent a replacement rendering/media/input algorithm merely because the current game exposes a missing path.
4. Optimize a suspected hot path without direct profiling/evidence and a canonical/known-good reference.
5. Treat exit code 0, API return PASS, or absence of Java exception as DEVICE-PASS.
6. Treat MIDI_LOAD=PASS / MIDI_PLAY=PASS / WAV_PLAY=PASS as proof that audio is physically audible.
7. Merge trace instrumentation into stable.
8. Use DP/VC/Golden/old experimental branches as production parents.
9. Use any A9 experimental branch as the parent of a new chat unless this ruler is explicitly revised by the user.
10. Promote a candidate before Vua Cướp Biển + God of War parent regression is physically revalidated.
11. Change multiple subsystems in one candidate unless reconstructing an already-proven exact parent.
12. Add game-name-specific hacks to the production runtime.
13. Suppress MIDlet lifecycle calls such as notifyDestroyed() to hide a failure.
14. Add vendor API stubs (RIM/Nokia/Siemens/Motorola etc.) without exact compatibility justification and scope.
15. Assume an installer layout from filenames alone. Runtime identity must be hash-gated; layout differences must not create false failures.
16. Claim a performance improvement from code inspection alone. It requires same-device measurable evidence.
17. Continue a rejected experiment just because CI passed.
18. Replace physical observation with automated PASS.
19. silently rebuild/repackage a commercial JAR and compare it as if it were the exact original input.
20. Ask the user to repeat evidence already present in the current task package/logs.

If a requested next action would violate these rules, STOP that action and return to the ruler.

---

## 5. REQUIRED FAILURE WORKFLOW

For every new real-game failure, follow exactly:

### Step A — Identity
Record:
- exact game filename;
- exact game SHA256;
- exact platform SHA256;
- JamVM/glibj SHA256;
- native input/video/audio SHA256;
- device = original RG35XX.

If identity is unknown, classification is NEEDS_REPRO. Do not patch.

### Step B — Reproduce against GOLDEN
First determine whether the failure exists on exact accepted A8.

### Step C — Compare canonical behavior
Before writing a fix:
- locate the exact relevant Aweigit implementation;
- determine what behavior is canonical;
- identify what RG35XX boundary differs.

### Step D — Assign failure owner
Allowed owner classes include:
- GAME/JAR_PROFILE
- VENDOR_API
- CANONICAL_FREEJ2ME
- RG35XX_GRAPHICS_BOUNDARY
- RG35XX_INPUT_BOUNDARY
- RG35XX_AUDIO_BOUNDARY
- RG35XX_FILESYSTEM/RMS_BOUNDARY
- PERFORMANCE_OWNER_UNRESOLVED
- LIFECYCLE_OWNER_UNRESOLVED

No runtime change while owner remains UNRESOLVED unless the change is trace-only.

### Step E — Smallest adapter delta
Only after owner is known:
- adapt the RG35XX boundary;
- preserve canonical semantics;
- change one owner/scope at a time;
- add a scope gate.

### Step F — Parent regressions
Before device promotion:
- automated regression gates;
- Vua Cướp Biển physical regression;
- God of War physical regression.

### Step G — Device acceptance
Physical original-RG35XX observation is mandatory.

### Step H — Promotion
Only when all required gates pass:
- DEVICE-PASS=YES
- parent regressions preserved
- protected hashes preserved
- then and only then may stable promotion be considered.

---

## 6. STATUS VOCABULARY — USE ONLY THESE TERMS

PASS
FAIL
PARTIAL
NOT_TESTED
NEEDS_REPRO
REJECTED
ARCHIVED_DIAGNOSTIC

Never use "stable", "fixed", "working", or "passed" without identifying the exact scope.

Examples:
- GRAPHICS_MENU=PASS
- GAMEPLAY=FAIL
- AUDIO_TECHNICAL=PASS
- AUDIO_AUDIBLE_DEVICE=FAIL
- DEVICE-PASS=NO

---

## 7. COMPATIBILITY CORPUS RULE

Priority order:

Tier 0 — Golden parent regression
1. Vua Cướp Biển
2. God of War

Tier 1 — Compatibility candidates
- A8-COMP-01 etc.
- A8-COMP-02 Asphalt 4 etc.

A Tier-1 failure NEVER authorizes breaking or redesigning Tier-0 behavior.

One failing game never justifies a platform generation change by itself.

---

## 8. CURRENT RESET STATUS — 2026-10-01

### A8
GOLDEN BASELINE.
Only accepted production parent.

### A8-COMP-01 Asphalt Nitro BlackBerry
Exact JAR SHA256:
b1ced935017042c4b69491ab2d34209200a178d52bd247d77cf4e598134571ff

Classification:
- RESULT=FAIL
- FAILURE_OWNER=GAME/JAR_PROFILE_VENDOR_API_BLACKBERRY_RIM
- A8_RUNTIME_REGRESSION=NO
- PLATFORM_CHANGE=NOT_JUSTIFIED

### A8-COMP-02 Asphalt 4
Exact JAR:
Asphalt_4_-_Elite_Racing_240x320-1.0-646694-mobiles24.jar

SHA256:
b25c855e5b04364e1e5ec36f06f32750f73a9e4a6ef1545a9dbe2b973a6e284b

Useful evidence retained:
- menu/display/input can run on A8;
- gameplay transition on A8 leads to the game's hidden clean-exit path;
- diagnostic analysis exposed a swallowed Java exception;
- exact hidden exception identified:
  NullPointerException at org.recompile.mobile.PlatformGraphics.fillTriangle();
- an experimental Raw2D fillTriangle path allowed gameplay to start.

But A9 experiments also showed:
- missing early splash/background images;
- poor gameplay performance/input responsiveness;
- incomplete physically audible audio;
- unstable/variable exit behavior;
- speculative performance candidates did not solve the problem.

Therefore:
- A9 IS NOT A NEW BASELINE.
- No A9 artifact may be used as parent for new work.
- A9 evidence is diagnostic knowledge only.

### PR status after reset
- PR #16: CLOSED, ARCHIVED_DIAGNOSTIC, unmerged.
- PR #17: CLOSED, ARCHIVED_EXPERIMENT, unmerged.
- PR #18: CLOSED, REJECTED, unmerged.

---

## 9. WHAT THE NEXT CHAT MUST DO FIRST

The first technical action in a new chat is NOT to build another Asphalt fix.

The new chat must:

1. Load/read this LOCKED RULER.
2. Confirm the canonical pins and A8 golden identities.
3. Treat A8 as the only production parent.
4. Build an inventory/map:
   canonical Aweigit subsystem
   <-> RG35XX boundary adapter
   <-> already proven DEVICE-PASS evidence.
5. Identify any divergence between the current A8 implementation and the canonical Miyoo behavior as a PLATFORM CONTRACT issue.
6. Only after the platform contract is mapped may COMP-02 be revisited.

Preferred first deliverable:
"RG35XX PLATFORM CONTRACT / GOLDEN RECONSTRUCTION MAP"

It should cover:
- startup/lifecycle;
- Canvas/GameCanvas;
- graphics primitives;
- image create/decode/drawRegion/alpha;
- framebuffer/presenter/scaling;
- input;
- RMS/filesystem;
- media/audio;
- shutdown/exit;
- performance/timing.

For each subsystem list:
- canonical Aweigit owner;
- RG35XX adapter;
- physical evidence;
- status;
- protected files/hashes;
- known limitations.

No new runtime patch is allowed while this map is incomplete unless fixing a reproducible regression in the golden parent itself.

---

## 10. NEW-CHAT BEHAVIOR RULES FOR THE ASSISTANT

When the user says "tiếp tục":
- continue the next approved step in this ruler;
- do not open an unrelated experimental branch;
- do not invent another optimization.

Before proposing any code modification, the assistant must explicitly be able to answer:
1. What exact evidence requires the change?
2. What is canonical Aweigit behavior?
3. What exact RG35XX boundary differs?
4. What is the failure owner?
5. What exact class/file scope changes?
6. What parent regressions protect against recurrence?
7. What physical-device observation will accept/reject the candidate?

If any answer is missing, do diagnostics/documentation only.

---

## 11. PROMOTION RULE

A candidate can become production only if ALL are true:

- canonical pin preserved;
- JamVM/glibj preserved;
- protected native identities preserved unless that native is the proven failure owner;
- exact candidate scope documented;
- CI gates PASS;
- Vua Cướp Biển physical regression PASS;
- God of War physical regression PASS;
- target failure physical test PASS;
- no new regression observed;
- normal exit verified where applicable;
- audible audio verified where applicable;
- DEVICE-PASS=YES.

Anything less remains experimental.

---

## 12. FINAL LOCK

The project must prefer a slower, evidence-driven reconstruction over repeated local fixes.

The mandatory engineering order is:

CANONICAL BEHAVIOR
-> RG35XX DEVICE CONTRACT
-> GOLDEN PHYSICAL EVIDENCE
-> FAILURE OWNER
-> SMALLEST ADAPTER DELTA
-> PARENT REGRESSION
-> PHYSICAL ACCEPTANCE
-> STABLE PROMOTION

Never reverse this order.
