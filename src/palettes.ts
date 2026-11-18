import { WLED_PALETTES, WLED_PALETTE_NAMES, type PaletteDef } from './wledPalettes';

/** A palette rendered to 256 RGB entries (floats 0..1), like WLED's 256-step lookup. */
export type Palette = { id: number; name: string; lut: Float32Array };

const SIZE = 256;

function buildLut(def: PaletteDef): Float32Array {
  const lut = new Float32Array(SIZE * 3);
  const s = def.stops;
  for (let i = 0; i < SIZE; i++) {
    let r: number, g: number, b: number;
    if (def.type === 'fl16') {
      // FastLED 16-entry palette: linear blend between entries, wrapping like ColorFromPalette
      const idx = Math.floor(i / 16), f = (i % 16) / 16;
      const a = s[idx], c = s[(idx + 1) % 16];
      r = a[1] + (c[1] - a[1]) * f; g = a[2] + (c[2] - a[2]) * f; b = a[3] + (c[3] - a[3]) * f;
    } else {
      let k = 0;
      while (k < s.length - 2 && s[k + 1][0] < i) k++;
      const a = s[k], c = s[Math.min(k + 1, s.length - 1)];
      const span = c[0] - a[0];
      const f = span > 0 ? Math.min(1, Math.max(0, (i - a[0]) / span)) : 0;
      r = a[1] + (c[1] - a[1]) * f; g = a[2] + (c[2] - a[2]) * f; b = a[3] + (c[3] - a[3]) * f;
    }
    lut[i * 3] = r / 255; lut[i * 3 + 1] = g / 255; lut[i * 3 + 2] = b / 255;
  }
  return lut;
}

const cache = new Map<number, Palette>();

export function getPalette(id: number): Palette | undefined {
  if (cache.has(id)) return cache.get(id);
  const def = WLED_PALETTES[id];
  if (!def) return undefined;
  const p = { id, name: def.name, lut: buildLut(def) };
  cache.set(id, p);
  return p;
}

/** Build a palette from WLED segment colors (for palettes 2–5, which depend on the segment's colors). */
export function paletteFromColors(id: number, cols: number[][]): Palette {
  const c = cols.filter((x) => x && x.length >= 3 && x[0] + x[1] + x[2] > 0);
  const c1 = c[0] ?? [255, 160, 0];
  const c2 = c[1] ?? c1.map((v) => v * 0.3);
  const c3 = c[2] ?? c1;
  let stops: number[][];
  switch (id) {
    case 2: stops = [[0, ...c1], [255, ...c1]]; break;
    case 3: stops = [[0, ...c1], [127, ...c2], [255, ...c1]]; break;
    case 4: stops = [[0, ...c3], [127, ...c2], [255, ...c1]]; break;
    default: stops = [[0, ...c1], [85, ...c1], [86, ...c2], [170, ...c2], [171, ...c3], [255, ...c3]];
  }
  return { id, name: WLED_PALETTE_NAMES[id] ?? `#${id}`, lut: buildLut({ name: '', type: 'grad', stops }) };
}

export function paletteName(id: number): string {
  return WLED_PALETTE_NAMES[id] ?? `Custom ${id}`;
}

/**
 * Palettes the auto-cycler picks from: weighted toward the ones used on the LED wall's presets
 * (Analogous, Fire, Lava, Rainbow, Red Flash...) plus other psy-friendly high-contrast ones.
 */
export const CURATED: number[] = [
  18, 18, 18, 35, 35, 8, 11, 66, 16, 6, 7, 23, 24, 36, 57, 64, 13, 40, 41, 44, 50, 51, 54, 56, 58, 59, 60, 62, 63, 70,
];

export const ALL_IDS: number[] = Object.keys(WLED_PALETTES).map(Number).sort((a, b) => a - b);

/** Map a WLED "Default" (0) or random-cycle (1) palette to something sensible. */
export function resolveWledId(id: number): number {
  if (id === 0) return 11; // most effects default to rainbow
  if (id === 1) return 6; // random cycle -> party
  return id;
}
