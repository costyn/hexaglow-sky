# Hexaglow Sky

Slow, psy-trance-style geometric visuals to project on the ceiling above a hexagon-lattice
LED wall, using the same color palettes as WLED. Pure WebGL2 shaders, runs in any modern
browser — with live palette sync from your WLED controller.

## Quick start (no install)

Download `hexaglow-sky.html` from the [latest release](https://github.com/costyn/hexaglow-sky/releases/latest),
open it in Chrome, drag the window to the projector and press **F** for fullscreen.
Press **K** to correct for an angled projector, **W** to sync palettes with WLED, **H** for all keys.

A laptop or desktop from the last ~6–8 years is plenty. A Raspberry Pi 3 is not (no WebGL2).

## Run from source

```bash
npm install
npm run dev        # http://localhost:5173 (also reachable from other machines on the LAN)
```

`npm run build:single` produces one self-contained `dist/index.html` that runs straight from
disk (double-click), which is what the releases contain.

## Keys

| Key | Action |
|---|---|
| Space / → / ← | next / previous scene |
| 1–9, 0 | pick scene 1–10 (the rest via ←/→) |
| A | auto-cycle scenes + palettes on/off |
| P or ] / [ | next / previous WLED palette |
| ↑ / ↓ | speed |
| + / − | brightness |
| B | blackout (fades) |
| K | keystone calibration (see below) |
| X / Y | mirror horizontally / vertically (ceiling/rear projection) |
| L | bloom glow on/off |
| W | WLED IP for palette sync |
| F | fullscreen · H help |

Settings persist in the browser. URL params: `?wled=192.168.1.50&scene=2&speed=0.8&scale=0.75`
(`scale` lowers render resolution on weak machines).

## Keystone (angled projector)

Press **K**. A test grid with a circle and hexagon appears, plus four corner handles. Drag
the handles (or Tab + arrow keys, Shift for bigger steps) until the squares look square and
the circle looks round *on the ceiling*. `+`/`−` change the pattern size, **R** resets,
**K**/Esc saves.

Unlike projector keystone, this doesn't shrink the picture: every projector pixel is mapped
into ceiling space and the pattern is drawn there, so the whole frame stays lit and only
the outer outline of the image stays trapezoid-shaped.

## Scenes

1. **Lattice Bloom** – the booth wall's triangle grid with hexagons blooming out in waves
2. **Chevron Cascade** – mirrored slanted bars forming chevrons/diamonds (mockup ceiling)
3. **Sacred Tunnel** – nested triangles/hexagons/hexagrams zooming outward
4. **Triangle Drift** – scattered triangles fading in/out around a hexagon cluster
5. **Kaleido Lattice** – 6-fold kaleidoscope over a moving triangle lattice
6. **Hexagram Mandala** – counter-rotating stars with orbiting hexagons
7. **Hex Gate** – Lattice Bloom with a big hexagonal opening in the middle, like the real wall
8. **Octagrams** – by whisky_shusuky ([Shadertoy](https://www.shadertoy.com/view/tlVGDt)), recoloured with the WLED palette
9. **Shader Art** – by kishimisu ([Shadertoy](https://www.shadertoy.com/view/mtyGWy)), with its own colours
10. **Lattice Current** – comets of light race along the channels between the triangles, popping hexagons open at the vertices they pass
11. **The Universe Within** – by Martijn Steinrucken aka BigWings, recoloured with the WLED palette
12. **Voronoi Distances** – by Inigo Quilez ([Shadertoy](https://www.shadertoy.com/view/ldl3W8), MIT), recoloured with the WLED palette
13. **Moiré Lattice** – two lattices, one behind the other; their slight twist makes a giant hexagonal moiré, with hexagons blooming where they line up
14. **Hextile** – from Shadertoy ([dtSXWV](https://www.shadertoy.com/view/dtSXWV)), slowed down, its moiré builds up and winds back down

## WLED palette sync

Press **W** and enter the WLED controller's IP. The page connects to WLED's WebSocket
(`ws://<ip>/ws`) and follows the main segment's palette, crossfading with WLED's transition
time. While connected, auto palette cycling is off. Palettes 2–5 (color-based) are built from
the segment's colors. Note WLED allows only a few WebSocket clients at once.

## Palettes

`src/wledPalettes.ts` is generated from WLED's `wled00/palettes.cpp` (v0.16, copy in
`scripts/`). To refresh: replace `scripts/wled-palettes.cpp` and run `npm run palettes`.

## Credits

- Color palettes from [WLED](https://github.com/wled/WLED) (`wled00/palettes.cpp`, EUPL-1.2),
  which includes palettes from [FastLED](https://github.com/FastLED/FastLED) (MIT) and
  [cpt-city](http://seaviewsensing.com/pub/cpt-city/).
- *Octagrams* (whisky_shusuky), *Shader Art* (kishimisu), *The Universe Within*
  (Martijn Steinrucken) and *Hextile* are from Shadertoy and are CC BY-NC-SA 3.0: non-commercial use only.
  *Voronoi Distances* is by Inigo Quilez under the MIT license.
- Signed-distance functions for triangles and hexagons after [Inigo Quilez](https://iquilezles.org/articles/distfunctions2d/).

## License

MIT — see [LICENSE](LICENSE). The bundled copy of WLED's palette source
(`scripts/wled-palettes.cpp`) remains under WLED's EUPL-1.2 license.
