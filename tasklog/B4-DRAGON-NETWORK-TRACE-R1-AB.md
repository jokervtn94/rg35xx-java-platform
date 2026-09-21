# B4-DRAGON-NETWORK-TRACE-R1-AB

Status: SOURCE-CREATED / BUILD-PENDING / DEVICE-TRACE-PENDING / STABLE=NO

Primary variable:
BOUNDED_NETWORK_DEPENDENCY_OBSERVABILITY_ONLY

## Current evidence

B4-DRAGON-DISPLAY-TRACE-R1 established on device:
- Dragon Mania remains visually frozen at the Gameloft startup logo;
- Display event processing remains alive;
- Canvas paint callbacks continue and return;
- repaint flushes continue;
- serviceRepaints/paintLock has no sampled deadlock;
- input is received, queued, dispatched and delivered;
- no media request is reached;
- RMS exception storm is absent.

Therefore the visible freeze is a game-state/dependency stall, not a Display/Canvas/render/input deadlock.

## Network candidate

Pinned FreeJ2ME routes http/https/socket through:
Connector -> HttpConnectionImpl

Current pinned behavior includes:
- network branch object construction;
- HTTP connect stub;
- HTTP response code stub returning 200;
- openInputStream returning null;
- openOutputStream returning null.

A game can therefore remain alive/rendering while waiting on or mishandling a network-dependent startup state without a Display deadlock.

## Historical trace source

Reuse retained trace-only script:
scripts/vc7r22r13i_apply_network_dependency_trace.py

It adds bounded/transition diagnostics only and changes no network semantics.

## Trace scope

- Connector.open begin
- network protocol branch
- connection construction/done
- HttpConnectionImpl constructor
- connect
- response code stub
- null input stream request
- null output stream request

Existing media and Display/Canvas traces remain present as controls.

## Device test

Precondition runtime:
c6f2c8c71fdb120dac1b8193952d0839dc4cd6877ba8c2e120f606cfb087faab

Run ONLY:
dragon-mania-s40v6

At Gameloft logo:
- wait 20-30 seconds;
- press one normal action key once;
- wait 5 seconds;
- exit normally if possible;
- do not launch another Java game;
- collect immediately.

Interpretation:
- any RG35XX-R13I-NET record before/while logo is frozen => network dependency is active and next checkpoint can localize exact stub behavior;
- zero network trace while display/game paint stays alive => network is deprioritized and the next dependency trace moves deeper into game state/thread/timing/resource startup.

No network behavior change.
No RMS behavior change.
No display behavior change.
No media behavior change.
No native core change.

BUILD-PASS is not DEVICE-PASS.
STABLE=NO.
