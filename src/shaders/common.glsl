#define PI 3.14159265
#define TAU 6.28318531
#define SQ3 1.7320508

uniform float uTime;
uniform vec2 uRes;
uniform sampler2D uPalette;
uniform float uSeed;

// WLED-style palette lookup, wraps like WLED does
vec3 pal(float x) { return texture(uPalette, vec2(fract(x), 0.5)).rgb; }

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.xx + p3.yz) * p3.zy);
}
mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// Equilateral triangle, centred on centroid, pointing up, side = 2r (iq)
float sdTri(vec2 p, float r) {
  const float k = SQ3;
  p.x = abs(p.x) - r;
  p.y = p.y + r / k;
  if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
  p.x -= clamp(p.x, -2.0 * r, 0.0);
  return -length(p) * sign(p.y);
}
// Hexagon with apothem r, vertices on the x axis (iq)
float sdHex(vec2 p, float r) {
  const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
  p = abs(p);
  p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
  p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
  return length(p) * sign(p.y);
}

// Anti-aliased stroke of width w around the zero-line of d
float stroke(float d, float w) {
  float px = max(fwidth(d), 1e-5);
  return 1.0 - smoothstep(w - px, w + px, abs(d));
}
float fillAA(float d) {
  float px = max(fwidth(d), 1e-5);
  return 1.0 - smoothstep(-px, px, d);
}
// soft halo, adds the "neon tube" feel on top of the bloom pass
float halo(float d, float w) { return w / (abs(d) + w) * 0.12; }

// Equilateral triangle lattice (side 1). Returns triangle centroid c and id (cell.xy, 1 = points down).
void triCell(vec2 p, out vec2 c, out vec3 id) {
  vec2 q = vec2(p.x - p.y / SQ3, p.y * 2.0 / SQ3);
  vec2 cell = floor(q);
  vec2 f = q - cell;
  float dn = step(1.0, f.x + f.y);
  vec2 cq = cell + mix(vec2(1.0 / 3.0), vec2(2.0 / 3.0), dn);
  c = vec2(cq.x + cq.y * 0.5, cq.y * SQ3 * 0.5);
  id = vec3(cell, dn);
}
// Nearest lattice vertex (where 6 triangles meet) in p-space
vec2 triVertex(vec2 p) {
  vec2 q = vec2(p.x - p.y / SQ3, p.y * 2.0 / SQ3);
  vec2 cell = floor(q);
  vec2 best = vec2(0.0);
  float bd = 1e9;
  for (int i = 0; i < 4; i++) {
    vec2 o = vec2(float(i & 1), float(i >> 1));
    vec2 vq = cell + o;
    vec2 v = vec2(vq.x + vq.y * 0.5, vq.y * SQ3 * 0.5);
    float d = dot(p - v, p - v);
    if (d < bd) { bd = d; best = v; }
  }
  return best;
}
