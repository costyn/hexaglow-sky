// Lattice Bloom — the booth wall's motif: a triangle lattice where hexagons bloom
// out of the vertices in slow waves radiating from the centre.
vec3 scene(vec2 p, float t) {
  float scale = 7.0 + 1.2 * sin(t * 0.045 + uSeed);
  p = rot(t * 0.012 + uSeed) * p;
  vec2 q = p * scale;

  vec2 c; vec3 id;
  triCell(q, c, id);
  vec2 l = q - c;
  l.y *= mix(1.0, -1.0, id.z);
  float dTri = sdTri(l, 0.5);

  vec2 v = triVertex(q);
  float rv = length(v) / scale;
  float rc = length(c) / scale;
  float h = hash12(id.xy * 1.31 + id.z * 17.3 + uSeed);
  float hv = hash12(v * 3.7 + uSeed);

  // hexagon bloom: travelling rings + slow breathing core
  float ring = 0.5 + 0.5 * sin(rv * 10.0 - t * 0.55 + hv * 0.8);
  float core = 1.0 - smoothstep(0.08, 0.22 + 0.08 * sin(t * 0.13), rv);
  float hexAmt = max(smoothstep(0.55, 1.0, ring), core);
  float apo = 0.30 * hexAmt;
  float dHex = sdHex(q - v, apo);

  // triangle is cut by the hexagon (with a gap), like the laser-cut wall
  float inset = 0.075;
  float dShape = max(dTri + inset, -(dHex - inset * 1.2));

  // triangle activity: soft waves + per-cell twinkle
  float wave = 0.5 + 0.5 * sin(rc * 7.0 - t * 0.4);
  float swirl = 0.5 + 0.5 * sin(atan(c.y, c.x) * 3.0 + t * 0.21 + rc * 5.0);
  float act = 0.15 + 0.85 * smoothstep(0.25, 0.95, wave * 0.7 + swirl * 0.4);
  act *= 0.65 + 0.35 * sin(t * 0.7 + h * TAU);

  float w = 0.02;
  vec3 tcol = pal(rc * 0.55 - t * 0.025 + h * 0.06);
  vec3 col = tcol * act * (stroke(dShape, w) + 0.08 * fillAA(dShape) + halo(dShape, w));

  // hexagon: filled, brighter
  float hexVis = smoothstep(0.02, 0.2, apo);
  vec3 hcol = pal(rv * 0.55 - t * 0.025 + 0.5);
  col += hcol * hexVis * (0.4 * fillAA(dHex) + stroke(dHex, w) + halo(dHex, w));

  return col;
}
