/**
 * Keystone / corner-pin correction.
 *
 * Instead of squeezing a rectangle into the projector's trapezoid (which wastes light and
 * shrinks the picture), every projector pixel is mapped through a homography into
 * "ceiling space" and the pattern is evaluated there. Shapes come out undistorted on the
 * ceiling and the full projector frame stays in use.
 *
 * The user drags four handles (in display uv, y up) onto where a rectangle should appear;
 * that quad is mapped to the world rectangle [-a/2, a/2] x [-0.5, 0.5] (a = aspect).
 */
export type Pt = [number, number];
export type Quad = [Pt, Pt, Pt, Pt]; // BL, BR, TR, TL in display uv (0..1, y up)

export const DEFAULT_QUAD: Quad = [[0, 0], [1, 0], [1, 1], [0, 1]];

/** Homography (column-major mat3) mapping display uv -> world p. */
export function warpMatrix(q: Quad, aspect: number): Float32Array {
  const a = aspect / 2;
  const dst: Pt[] = [[-a, -0.5], [a, -0.5], [a, 0.5], [-a, 0.5]];
  const A: number[][] = [];
  const b: number[] = [];
  for (let i = 0; i < 4; i++) {
    const [x, y] = q[i], [u, v] = dst[i];
    A.push([x, y, 1, 0, 0, 0, -u * x, -u * y]); b.push(u);
    A.push([0, 0, 0, x, y, 1, -v * x, -v * y]); b.push(v);
  }
  const h = solve(A, b);
  if (!h) return warpMatrix(DEFAULT_QUAD, aspect);
  // rows: [h0 h1 h2; h3 h4 h5; h6 h7 1] -> column-major
  return new Float32Array([h[0], h[3], h[6], h[1], h[4], h[7], h[2], h[5], 1]);
}

function solve(A: number[][], b: number[]): number[] | null {
  const n = b.length;
  const M = A.map((r, i) => [...r, b[i]]);
  for (let c = 0; c < n; c++) {
    let p = c;
    for (let r = c + 1; r < n; r++) if (Math.abs(M[r][c]) > Math.abs(M[p][c])) p = r;
    if (Math.abs(M[p][c]) < 1e-12) return null;
    [M[c], M[p]] = [M[p], M[c]];
    for (let r = 0; r < n; r++) {
      if (r === c) continue;
      const f = M[r][c] / M[c][c];
      for (let k = c; k <= n; k++) M[r][k] -= f * M[c][k];
    }
  }
  return M.map((r, i) => r[n] / r[i]);
}

/** Draggable corner handles drawn over the canvas while calibrating. */
export class KeystoneEditor {
  private svg: SVGSVGElement;
  private poly: SVGPolygonElement;
  private dots: SVGCircleElement[] = [];
  private drag = -1;
  selected = 0;
  active = false;

  constructor(private quad: Quad, private onChange: () => void) {
    const NS = 'http://www.w3.org/2000/svg';
    this.svg = document.createElementNS(NS, 'svg');
    Object.assign(this.svg.style, { position: 'fixed', inset: '0', width: '100vw', height: '100vh', display: 'none', cursor: 'default' });
    this.poly = document.createElementNS(NS, 'polygon');
    this.poly.setAttribute('fill', 'none');
    this.poly.setAttribute('stroke', '#fff');
    this.poly.setAttribute('stroke-width', '2');
    this.poly.setAttribute('stroke-dasharray', '8 6');
    this.svg.appendChild(this.poly);
    for (let i = 0; i < 4; i++) {
      const c = document.createElementNS(NS, 'circle');
      c.setAttribute('r', '16');
      c.setAttribute('stroke-width', '3');
      c.style.cursor = 'grab';
      c.addEventListener('pointerdown', (e) => {
        this.drag = i; this.selected = i;
        c.setPointerCapture(e.pointerId);
        this.render();
      });
      c.addEventListener('pointermove', (e) => {
        if (this.drag !== i) return;
        this.quad[i] = [clamp(e.clientX / innerWidth), clamp(1 - e.clientY / innerHeight)];
        this.render(); this.onChange();
      });
      c.addEventListener('pointerup', () => { this.drag = -1; });
      this.svg.appendChild(c);
      this.dots.push(c);
    }
    document.body.appendChild(this.svg);
    window.addEventListener('resize', () => this.render());
  }

  setQuad(q: Quad) { this.quad = q; this.render(); }

  toggle(on = !this.active) {
    this.active = on;
    this.svg.style.display = on ? 'block' : 'none';
    this.render();
  }

  nudge(dx: number, dy: number) {
    const p = this.quad[this.selected];
    this.quad[this.selected] = [clamp(p[0] + dx), clamp(p[1] + dy)];
    this.render(); this.onChange();
  }

  render() {
    const px = (p: Pt) => [p[0] * innerWidth, (1 - p[1]) * innerHeight];
    this.poly.setAttribute('points', this.quad.map((p) => px(p).join(',')).join(' '));
    this.dots.forEach((c, i) => {
      const [x, y] = px(this.quad[i]);
      c.setAttribute('cx', String(x));
      c.setAttribute('cy', String(y));
      c.setAttribute('fill', i === this.selected ? '#ff3b6b88' : '#ffffff33');
      c.setAttribute('stroke', i === this.selected ? '#ff3b6b' : '#fff');
    });
  }
}

const clamp = (v: number) => Math.min(1, Math.max(0, v));
