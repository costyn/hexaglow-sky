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
