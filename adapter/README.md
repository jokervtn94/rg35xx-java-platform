# RG35XX adapter

Only original-RG35XX-specific integration belongs here.

Locked device contracts:
- video: SDL1/fbcon, physical 640x480 LCD
- input: /dev/input/js0 using the device-proven mapping
- runtime: protected JamVM L + protected glibj.zip
- filesystem/launcher/font glue: RG35XX-specific only
- audio: HOLD until non-media CORE INTEGRATION passes

Do not copy Aweigit SDL2 frontend assumptions into this adapter. Do not replay DP Java patches here. Reuse historical native adapter code only after source/hash review and record `origin -> purpose -> source hash -> previous device evidence -> new hash`.
