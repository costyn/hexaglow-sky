// Kaleido Lattice — a triangle lattice pans and turns underneath a 6-fold
// kaleidoscope; inner triangles grow and shrink in waves.
vec3 scene(vec2 p, float t) {
  float r = length(p);
  float a = atan(p.y, p.x) + t * 0.01;
  float seg = TAU / 6.0;
  a = mod(a, seg);
  a = abs(a - seg * 0.5);
  vec2 k = vec2(cos(a), sin(a)) * r;
  k = rot(t * 0.025 + uSeed) * k;
  k += vec2(t * 0.035, t * 0.017) + uSeed;

  float scale = 5.0;
  vec2 q = k * scale;
  vec2 c; vec3 id;
  triCell(q, c, id);
  vec2 l = q - c;
  l.y *= mix(1.0, -1.0, id.z);
  float h = hash12(id.xy + id.z * 9.1 + uSeed);

  float dOuter = sdTri(l, 0.5);
  float inner = 0.08 + 0.3 * (0.5 + 0.5 * sin(t * 0.45 - r * 7.0 + h * 2.0));
  float dInner = sdTri(l, inner);
  vec2 lr = rot(t * 0.2 * (h - 0.5)) * l;
  float dRot = sdTri(vec2(lr.x, -lr.y), inner * 0.55);

  vec3 c1 = pal(r * 0.7 + h * 0.08 - t * 0.02);
  vec3 c2 = pal(r * 0.7 + 0.35 - t * 0.02);
  vec3 col = c1 * 0.35 * stroke(dOuter, 0.012);
  col += c2 * (stroke(dInner, 0.018) + halo(dInner, 0.018)) * (0.4 + 0.6 * h);
  col += c1 * stroke(dRot, 0.012) * step(0.55, h);

  col *= smoothstep(0.0, 0.06, r) * 0.85 + 0.15;
  return col;
}
