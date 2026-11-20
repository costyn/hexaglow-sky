// Hex Gate — Lattice Bloom with the real wall's big hexagonal opening in the middle.
// Whole triangles are cut out so the opening follows the lattice lines; its rim glows
// and hexagonal rings drift inward through it like a portal.
vec3 scene(vec2 p, float t) {
  float scale = 7.0 + 0.8 * sin(t * 0.045 + uSeed);
  p = rot(t * 0.010 + uSeed) * p;
  vec2 q = p * scale;
  gUnit = scale;

  // opening: hexagon of side N lattice units centred on the vertex at the origin
  const float N = 2.0;
  float holeApo = N * SQ3 * 0.5;
  float dHole = sdHex(q, holeApo);

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

  // triangles whose centre is inside the opening are cut away
  float solid = step(0.0, sdHex(c, holeApo));
  // no hexagon blooms on the opening or its rim
  float vSolid = step(0.2, sdHex(v, holeApo));

  // hexagon bloom: rings travelling outward from the opening
  float ring = 0.5 + 0.5 * sin(rv * 10.0 - t * 0.55 + hv * 0.8);
  float hexAmt = smoothstep(0.55, 1.0, ring) * vSolid;
  float apo = 0.30 * hexAmt;
  float dHex = sdHex(q - v, apo);

  float inset = 0.075;
  float dShape = max(dTri + inset, -(dHex - inset * 1.2));

  float wave = 0.5 + 0.5 * sin(rc * 7.0 - t * 0.4);
  float swirl = 0.5 + 0.5 * sin(atan(c.y, c.x) * 3.0 + t * 0.21 + rc * 5.0);
  float act = 0.15 + 0.85 * smoothstep(0.25, 0.95, wave * 0.7 + swirl * 0.4);
  act *= 0.65 + 0.35 * sin(t * 0.7 + h * TAU);

  float w = 0.02;
  vec3 tcol = pal(rc * 0.55 - t * 0.025 + h * 0.06);
  vec3 col = solid * tcol * act * (stroke(dShape, w) + 0.08 * fillAA(dShape) + halo(dShape, w));

  float hexVis = smoothstep(0.02, 0.2, apo);
  vec3 hcol = pal(rv * 0.55 - t * 0.025 + 0.5);
  col += hcol * hexVis * (0.4 * fillAA(dHex) + stroke(dHex, w) + halo(dHex, w));

  // rim: a bright double outline set in by the same gap as the triangles
  float ang = atan(q.y, q.x);
  vec3 rimCol = pal(ang / TAU - t * 0.03);
  float rimPulse = 0.75 + 0.25 * sin(t * 0.35);
  float dRim = dHole + inset;
  col += rimCol * rimPulse * (1.6 * stroke(dRim, w * 1.3) + halo(dRim, w * 1.5));
  col += rimCol * 0.6 * stroke(dRim + 0.12, w * 0.7);

  // portal: hexagonal rings drifting inward, fading towards the centre
  float depth = -(dRim + 0.12);          // 0 just inside the inner outline
  if (depth > 0.0) {
    float s = 0.32;
    float phase = depth / s - t * 0.12;
    float k = floor(phase);
    float dRing = (fract(phase) - 0.5) * s;
    float fade = clamp(1.0 - depth / (holeApo - 0.25), 0.0, 1.0);
    fade *= fade;
    vec3 pcol = pal(k * 0.07 + t * 0.02 + 0.25);
    col += pcol * fade * 0.9 * (stroke(dRing, w * 0.8) + halo(dRing, w));
  }

  return col;
}
