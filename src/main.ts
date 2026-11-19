import { Program, createTarget, deleteTarget, type Target } from './gl';
import { BLUR_FS, COMPOSITE_FS, DOWNSAMPLE_FS, DOWNSAMPLE_MIX_FS } from './post';
import { ALL_IDS, CURATED, getPalette, paletteFromColors, paletteName, resolveWledId, type Palette } from './palettes';
import { WledSync } from './wled';
import common from './shaders/common.glsl?raw';
import latticeBloom from './shaders/latticeBloom.glsl?raw';
import chevronCascade from './shaders/chevronCascade.glsl?raw';
import sacredTunnel from './shaders/sacredTunnel.glsl?raw';
import triangleDrift from './shaders/triangleDrift.glsl?raw';
import kaleidoLattice from './shaders/kaleidoLattice.glsl?raw';
import hexagramMandala from './shaders/hexagramMandala.glsl?raw';
import calibration from './shaders/calibration.glsl?raw';
import { DEFAULT_QUAD, KeystoneEditor, warpMatrix, type Quad } from './keystone';

const SCENES = [
  { name: 'Lattice Bloom', src: latticeBloom },
  { name: 'Chevron Cascade', src: chevronCascade },
  { name: 'Sacred Tunnel', src: sacredTunnel },
  { name: 'Triangle Drift', src: triangleDrift },
  { name: 'Kaleido Lattice', src: kaleidoLattice },
  { name: 'Hexagram Mandala', src: hexagramMandala },
];

// ---------- settings (persisted) ----------
const DEFAULTS = {
  speed: 1, bright: 1, bloom: true, flipX: false, flipY: false, auto: true,
  sceneSecs: 50, sceneFade: 7, paletteSecs: 90, paletteFade: 8, wled: '', renderScale: 1,
  quad: DEFAULT_QUAD.map((p) => [...p]) as Quad, zoom: 1,
};
type Settings = typeof DEFAULTS;
const settings: Settings = { ...DEFAULTS, ...JSON.parse(localStorage.getItem('ceiling-settings') || '{}') };
const params = new URLSearchParams(location.search);
if (params.has('wled')) settings.wled = params.get('wled')!;
if (params.has('speed')) settings.speed = +params.get('speed')!;
if (params.has('scale')) settings.renderScale = +params.get('scale')!;
const save = () => localStorage.setItem('ceiling-settings', JSON.stringify(settings));

// ---------- GL setup ----------
const canvas = document.getElementById('c') as HTMLCanvasElement;
const gl = canvas.getContext('webgl2', { antialias: false, alpha: false, powerPreference: 'high-performance' })!;
if (!gl) throw new Error('WebGL2 not available');
const hdr = !!gl.getExtension('EXT_color_buffer_float');
gl.getExtension('OES_texture_float_linear');

// Every scene is evaluated in "ceiling space": projector pixel -> keystone homography -> p.
const sceneFS = (src: string) => `#version 300 es
precision highp float;
out vec4 outColor;
uniform mat3 uWarp;
uniform vec2 uFlip;
uniform float uZoom;
${common}
${src}
void main() {
  vec3 h = uWarp * vec3(gl_FragCoord.xy / uRes, 1.0);
  if (h.z <= 1e-5) { outColor = vec4(0.0, 0.0, 0.0, 1.0); return; } // beyond the horizon
  vec2 p = h.xy / h.z;
  p = mix(p, -p, uFlip) * uZoom;
  vec2 fw = fwidth(p);
  PX = max(0.70710678 * length(fw), 1e-6);
  vec3 col = scene(p, uTime) * (1.0 - smoothstep(4.0, 8.0, length(p)));
  outColor = vec4(max(col, 0.0), 1.0);
}`;
const sceneProgs = SCENES.map((s) => new Program(gl, sceneFS(s.src), s.name));
const calibProg = new Program(gl, sceneFS(calibration), 'calibration');
const downMix = new Program(gl, DOWNSAMPLE_MIX_FS, 'downsample-mix');
const down = new Program(gl, DOWNSAMPLE_FS, 'downsample');
const blur = new Program(gl, BLUR_FS, 'blur');
const composite = new Program(gl, COMPOSITE_FS, 'composite');

const paletteTex = (() => {
  const t = gl.createTexture()!;
  gl.bindTexture(gl.TEXTURE_2D, t);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, 256, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  return t;
})();

let W = 0, H = 0;
let sceneA: Target, sceneB: Target, b1: Target, b1t: Target, b2: Target, b2t: Target;
function resize() {
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const w = Math.round(canvas.clientWidth * dpr), h = Math.round(canvas.clientHeight * dpr);
  // cap total pixels around 1080p for steady frame rates
  const cap = Math.min(1, Math.sqrt((1920 * 1200) / (w * h))) * settings.renderScale;
  const nw = Math.max(2, Math.round(w * cap)), nh = Math.max(2, Math.round(h * cap));
  if (nw === W && nh === H) return;
  W = nw; H = nh;
  canvas.width = W; canvas.height = H;
  [sceneA, sceneB, b1, b1t, b2, b2t].forEach((t) => deleteTarget(gl, t));
  sceneA = createTarget(gl, W, H, hdr);
  sceneB = createTarget(gl, W, H, hdr);
  const w1 = Math.ceil(W / 4), h1 = Math.ceil(H / 4);
  b1 = createTarget(gl, w1, h1, hdr); b1t = createTarget(gl, w1, h1, hdr);
  const w2 = Math.ceil(w1 / 4), h2 = Math.ceil(h1 / 4);
  b2 = createTarget(gl, w2, h2, hdr); b2t = createTarget(gl, w2, h2, hdr);
}
window.addEventListener('resize', resize);
resize();

// ---------- palette state (crossfades on the CPU, like WLED's palette blending) ----------
const palNow = new Float32Array(256 * 3);
let palFrom = new Float32Array(256 * 3);
let palTo: Palette;
let palT = 1, palDur = 1;
let palIdx = 0; // index into ALL_IDS for manual stepping
const palBytes = new Uint8Array(256 * 4);

function setPalette(p: Palette, fadeSecs: number) {
  palFrom = palNow.slice();
  palTo = p;
  palT = 0;
  palDur = Math.max(0.01, fadeSecs);
  const i = ALL_IDS.indexOf(p.id);
  if (i >= 0) palIdx = i;
  show(`palette  ${p.id} · ${p.name}`);
}
function updatePalette(dt: number) {
  if (palT >= 1 && palBytes[3] === 255) return;
  palT = Math.min(1, palT + dt / palDur);
  const e = palT * palT * (3 - 2 * palT);
  for (let i = 0; i < 256 * 3; i++) palNow[i] = palFrom[i] + (palTo.lut[i] - palFrom[i]) * e;
  for (let i = 0; i < 256; i++) {
    palBytes[i * 4] = palNow[i * 3] * 255;
    palBytes[i * 4 + 1] = palNow[i * 3 + 1] * 255;
    palBytes[i * 4 + 2] = palNow[i * 3 + 2] * 255;
    palBytes[i * 4 + 3] = 255;
  }
  gl.bindTexture(gl.TEXTURE_2D, paletteTex);
  gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 256, 1, gl.RGBA, gl.UNSIGNED_BYTE, palBytes);
}
const randomPalette = () => {
  let id: number;
  do id = CURATED[Math.floor(Math.random() * CURATED.length)];
  while (palTo && id === palTo.id);
  return getPalette(id)!;
};
{
  const first = getPalette(18)!; // Analogous: the blue→red of the booth
  palNow.set(first.lut);
  palTo = first;
  palT = 0; palDur = 0.01;
}

// ---------- scene state ----------
let cur = Number(params.get('scene') ?? Math.floor(Math.random() * SCENES.length)) % SCENES.length;
let next = -1;
let curSeed = Math.random() * 10, nextSeed = 0;
let sceneT = 0, mixT = 0;
function goScene(i: number) {
  i = ((i % SCENES.length) + SCENES.length) % SCENES.length;
  if (next >= 0) { cur = next; curSeed = nextSeed; } // finish any running fade
  if (i === cur) return;
  next = i; nextSeed = Math.random() * 10; mixT = 0; sceneT = 0;
  show(`scene  ${i + 1} · ${SCENES[i].name}`);
}

// ---------- WLED sync ----------
const wled = new WledSync(
  (e) => {
    const id = resolveWledId(e.pal);
    const p = id >= 2 && id <= 5 ? paletteFromColors(id, e.cols) : getPalette(id);
    if (p) setPalette(p, Math.max(e.transitionMs / 1000, 1.5));
    else show(`WLED palette ${e.pal} (${paletteName(e.pal)}) not available here`);
  },
  (s, host) => show(`WLED ${host}: ${s}`),
);
if (settings.wled) wled.connect(settings.wled);
const wledActive = () => wled.status !== 'off';

// ---------- HUD ----------
const hud = document.getElementById('hud')!;
const help = document.getElementById('help')!;
let hudTimer = 0;
function show(msg: string) {
  hud.textContent = msg;
  hud.classList.add('show');
  clearTimeout(hudTimer);
  hudTimer = window.setTimeout(() => { if (!keystone.active) hud.classList.remove('show'); }, 3500);
}
let idleTimer = 0;
window.addEventListener('mousemove', () => {
  document.body.classList.remove('idle');
  clearTimeout(idleTimer);
  idleTimer = window.setTimeout(() => document.body.classList.add('idle'), 2000);
});

// ---------- controls ----------
let blackout = false, master = 1;
const keystone = new KeystoneEditor(settings.quad, save);
const KEYSTONE_HELP = 'KEYSTONE  drag the 4 corners until squares look square & the circle round on the ceiling\n'
  + 'Tab: next corner · arrows: nudge (Shift = more) · +/−: pattern size · R: reset · K/Esc/Enter: done';
function keystoneKeys(e: KeyboardEvent): boolean {
  const k = e.key, step = e.shiftKey ? 0.01 : 0.002;
  if (k === 'k' || k === 'Escape' || k === 'Enter') { keystone.toggle(false); show('keystone saved'); }
  else if (k === 'Tab') { e.preventDefault(); keystone.selected = (keystone.selected + 1) % 4; keystone.render(); }
  else if (k === 'ArrowLeft') keystone.nudge(-step, 0);
  else if (k === 'ArrowRight') keystone.nudge(step, 0);
  else if (k === 'ArrowUp') keystone.nudge(0, step);
  else if (k === 'ArrowDown') keystone.nudge(0, -step);
  else if (k === '+' || k === '=') settings.zoom = Math.max(0.3, settings.zoom / 1.05);
  else if (k === '-' || k === '_') settings.zoom = Math.min(3, settings.zoom * 1.05);
  else if (k === 'r') { settings.quad = DEFAULT_QUAD.map((p) => [...p]) as Quad; settings.zoom = 1; keystone.setQuad(settings.quad); }
  else return false;
  e.preventDefault();
  if (keystone.active) show(KEYSTONE_HELP);
  return true;
}
window.addEventListener('keydown', (e) => {
  const k = e.key;
  if (keystone.active) { if (keystoneKeys(e)) save(); return; }
  if (k === 'k') { help.classList.remove('show'); keystone.toggle(true); show(KEYSTONE_HELP); return; }
  if (k === ' ' || k === 'ArrowRight') goScene((next >= 0 ? next : cur) + 1);
  else if (k === 'ArrowLeft') goScene((next >= 0 ? next : cur) - 1);
  else if (k >= '1' && k <= String(SCENES.length)) goScene(+k - 1);
  else if (k === 'p' || k === ']') setPalette(getPalette(ALL_IDS[(palIdx + 1) % ALL_IDS.length])!, 2);
  else if (k === '[') setPalette(getPalette(ALL_IDS[(palIdx - 1 + ALL_IDS.length) % ALL_IDS.length])!, 2);
  else if (k === 'a') { settings.auto = !settings.auto; show(`auto-cycle ${settings.auto ? 'on' : 'off'}`); }
  else if (k === 'ArrowUp') { settings.speed = Math.min(4, +(settings.speed * 1.15).toFixed(3)); show(`speed ×${settings.speed.toFixed(2)}`); }
  else if (k === 'ArrowDown') { settings.speed = Math.max(0.1, +(settings.speed / 1.15).toFixed(3)); show(`speed ×${settings.speed.toFixed(2)}`); }
  else if (k === '+' || k === '=') { settings.bright = Math.min(3, settings.bright + 0.1); show(`brightness ${settings.bright.toFixed(1)}`); }
  else if (k === '-' || k === '_') { settings.bright = Math.max(0.1, settings.bright - 0.1); show(`brightness ${settings.bright.toFixed(1)}`); }
  else if (k === 'b') { blackout = !blackout; show(blackout ? 'blackout' : 'lights up'); }
  else if (k === 'f') { document.fullscreenElement ? document.exitFullscreen() : document.documentElement.requestFullscreen(); }
  else if (k === 'x') { settings.flipX = !settings.flipX; show(`mirror X ${settings.flipX ? 'on' : 'off'}`); }
  else if (k === 'y') { settings.flipY = !settings.flipY; show(`mirror Y ${settings.flipY ? 'on' : 'off'}`); }
  else if (k === 'l') { settings.bloom = !settings.bloom; show(`bloom ${settings.bloom ? 'on' : 'off'}`); }
  else if (k === 'h' || k === '?') help.classList.toggle('show');
  else if (k === 'Escape') help.classList.remove('show');
  else if (k === 'w') {
    const v = prompt('WLED IP / hostname for palette sync (empty = off)', settings.wled);
    if (v !== null) { settings.wled = v.trim(); settings.wled ? wled.connect(settings.wled) : wled.disconnect(); }
  } else return;
  save();
});

// ---------- render loop ----------
let time = Math.random() * 1000;
let palClock = 0;
let last = performance.now();

function drawScene(i: number, seed: number, target: Target) {
  gl.bindFramebuffer(gl.FRAMEBUFFER, target.fbo);
  gl.viewport(0, 0, target.w, target.h);
  const prog = i < 0 ? calibProg : sceneProgs[i];
  prog.use().f('uTime', time).f('uRes', target.w, target.h).f('uSeed', seed).tex('uPalette', 0, paletteTex)
    .m3('uWarp', warpMatrix(settings.quad, W / H)).f('uZoom', i < 0 ? 1 : settings.zoom)
    .f('uFlip', settings.flipX ? 1 : 0, settings.flipY ? 1 : 0);
  if (i < 0) prog.f('uAspect', W / H);
  gl.drawArrays(gl.TRIANGLES, 0, 3);
}
function pass(p: Program, out: Target | null, w: number, h: number) {
  gl.bindFramebuffer(gl.FRAMEBUFFER, out ? out.fbo : null);
  gl.viewport(0, 0, w, h);
  p.f('uOutRes', w, h);
  gl.drawArrays(gl.TRIANGLES, 0, 3);
}

function frame(now: number) {
  const dt = Math.min(0.1, (now - last) / 1000);
  last = now;
  time += dt * settings.speed;
  resize();

  // director
  sceneT += dt;
  if (settings.auto && next < 0 && sceneT > settings.sceneSecs) {
    let n: number;
    do n = Math.floor(Math.random() * SCENES.length); while (n === cur);
    goScene(n);
  }
  if (next >= 0) {
    mixT += dt / settings.sceneFade;
    if (mixT >= 1) { cur = next; curSeed = nextSeed; next = -1; mixT = 0; }
  }
  palClock += dt;
  if (settings.auto && !wledActive() && palClock > settings.paletteSecs) {
    palClock = 0;
    setPalette(randomPalette(), settings.paletteFade);
  }
  updatePalette(dt);
  master += ((blackout ? 0 : 1) - master) * Math.min(1, dt * 1.5);

  const mix = next >= 0 ? mixT * mixT * (3 - 2 * mixT) : 0;
  if (keystone.active) drawScene(-1, 0, sceneA);
  else drawScene(cur, curSeed, sceneA);
  if (next >= 0 && !keystone.active) drawScene(next, nextSeed, sceneB);

  if (settings.bloom) {
    downMix.use().tex('uA', 0, sceneA.tex).tex('uB', 1, sceneB.tex).f('uMix', mix).f('uTexel', 1 / W, 1 / H);
    pass(downMix, b1, b1.w, b1.h);
    blur.use().tex('uSrc', 0, b1.tex).f('uDir', 1 / b1.w, 0); pass(blur, b1t, b1.w, b1.h);
    blur.use().tex('uSrc', 0, b1t.tex).f('uDir', 0, 1 / b1.h); pass(blur, b1, b1.w, b1.h);
    down.use().tex('uSrc', 0, b1.tex).f('uTexel', 1 / b1.w, 1 / b1.h); pass(down, b2, b2.w, b2.h);
    for (let i = 0; i < 2; i++) {
      blur.use().tex('uSrc', 0, b2.tex).f('uDir', (1 + i) / b2.w, 0); pass(blur, b2t, b2.w, b2.h);
      blur.use().tex('uSrc', 0, b2t.tex).f('uDir', 0, (1 + i) / b2.h); pass(blur, b2, b2.w, b2.h);
    }
  }
  composite.use()
    .tex('uA', 0, sceneA.tex).tex('uB', 1, sceneB.tex).tex('uBloom1', 2, b1.tex).tex('uBloom2', 3, b2.tex)
    .f('uMix', mix).f('uBloom', settings.bloom ? 0.9 : 0).f('uBright', settings.bright).f('uMaster', master)
    .f('uEdge', 0.03);
  pass(composite, null, W, H);

  requestAnimationFrame(frame);
}
show(`scene  ${cur + 1} · ${SCENES[cur].name}     (H for help)`);
requestAnimationFrame(frame);

// expose for debugging in the console
(window as any).ceiling = { settings, goScene, wled };
