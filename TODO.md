# Ideas / later

## Audio reactivity
- Web Audio input (line-in from the mixer via a USB audio interface, or the mic) turned into a
  few smoothed signals per frame: bass level, overall energy, beat pulse. Pass them as uniforms;
  each scene uses them subtly (glow breathing, comet speed, hexagon pop on the kick).
- Needs auto-gain (rolling peak) and kick detection on the 40–120 Hz band rising sharply.
- Alternative sources:
  - **beatsense** project, once it's on the network.
  - WLED's audio-reactive sync broadcast. Browsers can't receive UDP, so this needs a small bridge.

## Projection mapping around the ceiling's wood panel
- Mark the panel as a polygon in ceiling space, using an editor like the keystone one.
- Easy part: mask the panel (dark or a solid colour) and give its outline a glow.
- Harder part: scenes that flow around it, for example by pushing scene coordinates away from the
  panel using its distance field, or by having lattice scenes treat it like Hex Gate's opening.

## WLED UDP sync
- Original dream: sync timing and effects from WLED, not just the palette. Needs a UDP→WebSocket bridge.

## Drive the real LED wall from the shaders
- Render the scenes (especially LED Wall) and send the colours to the physical wall, so it can show
  the same patterns as the digital twin instead of being limited to WLED's built-in effects.
- Needs a map of every LED's position on the wall (WLED supports 2D LED maps), then sample the
  shader at those points each frame.
- Transport: WLED accepts real-time pixel data (DDP / E1.31 over UDP, which needs a small bridge
  since browsers can't send UDP), or possibly per-LED colours over its WebSocket/JSON API at a
  lower frame rate. Check what's fast enough for the wall's LED count.
- Resolution: 7 strips × 49 LEDs (~35 mm pitch, ~7 LEDs per triangle along a strip). Plenty along
  the strips, coarse across them, and each LED lights both the triangle above and the one below.
  Sample the shader averaged over the area each LED lights, not at a single point, and prefer
  effects with soft, large features across the strips (ripple, plasma, scanner, sweeps).
  Option: a "wall-accurate" LED Wall mode that only shows what the real strip layout can show.
