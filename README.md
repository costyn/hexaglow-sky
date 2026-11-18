# HexaGlow Ceiling Projection

Slow, psy-trance-style geometric visuals for the ceiling above the DJ booth, using the
same color palettes as the WLED LED wall. Pure WebGL2 shaders, runs in any modern browser.

## Run

```bash
npm install
npm run dev        # http://localhost:5173 (also reachable from other machines on the LAN)
```

For a gig: `npm run build` and serve `dist/` (or just keep `npm run dev` running), open it
full-screen on the projector output (press **F**).

## Keys

| Key | Action |
|---|---|
| Space / → / ← | next / previous scene |
| 1–6 | pick scene |
| A | auto-cycle scenes + palettes on/off |
| P or ] / [ | next / previous WLED palette |
| ↑ / ↓ | speed |
| + / − | brightness |
| B | blackout (fades) |
| X / Y | mirror horizontally / vertically (ceiling/rear projection) |
| L | bloom glow on/off |
| W | WLED IP for palette sync |
| F | fullscreen · H help |

Settings persist in the browser. URL params: `?wled=192.168.1.50&scene=2&speed=0.8&scale=0.75`
(`scale` lowers render resolution on weak machines).

## Scenes

1. **Lattice Bloom** – the booth wall's triangle grid with hexagons blooming out in waves
2. **Chevron Cascade** – mirrored slanted bars forming chevrons/diamonds (mockup ceiling)
3. **Sacred Tunnel** – nested triangles/hexagons/hexagrams zooming outward
4. **Triangle Drift** – scattered triangles fading in/out around a hexagon cluster
5. **Kaleido Lattice** – 6-fold kaleidoscope over a moving triangle lattice
6. **Hexagram Mandala** – counter-rotating stars with orbiting hexagons

## WLED palette sync

Press **W** and enter the WLED controller's IP. The page connects to WLED's WebSocket
(`ws://<ip>/ws`) and follows the main segment's palette, crossfading with WLED's transition
time. While connected, auto palette cycling is off. Palettes 2–5 (color-based) are built from
the segment's colors. Note WLED allows only a few WebSocket clients at once.

## Palettes

`src/wledPalettes.ts` is generated from WLED's `wled00/palettes.cpp` (v0.16, copy in
`scripts/`). To refresh: replace `scripts/wled-palettes.cpp` and run `npm run palettes`.
