// LED Wall — an approximate replica of the booth's laser-cut Hexaglow wall (from its STL),
// with WLED-style light effects glowing through the holes.
//
// Wall geometry, in lattice units (triangle side 1 ≈ 248 mm on the real wall):
// - triangle holes, separated by bars ~50 mm wide
// - round hubs at every node, growing towards the middle, which cut the triangle holes
//   near the centre into hexagons
// - one big hexagonal hole in the middle, made of the 6 triangles around the centre node
// The pattern continues past the real wall's edges, so it fills the whole ceiling.

const float LW_SCALE = 6.85;   // lattice units across the screen height (the wall is ~6.85 tall)
const float LW_BAR = 0.1;      // half bar width
const float LW_EFFECTS = 5.0;

// One effect value per hole: x = palette position, y = brightness
vec2 lwEffect(int e, vec2 c, float h, float t) {
  float r = length(c), a = r > 1e-3 ? atan(c.y, c.x) : 0.0; // atan(0,0) is undefined
  if (e == 0) { // ripple: rings running out from the centre hole
    return vec2(r * 0.12 - t * 0.04, pow(0.5 + 0.5 * sin(r * 1.9 - t * 1.3), 2.0));
  }
  if (e == 1) { // three-arm spiral sweeping round
    return vec2(a / TAU + t * 0.02, pow(0.5 + 0.5 * sin(3.0 * a - r * 1.1 - t * 0.9), 3.0));
  }
  if (e == 2) { // plasma
    float v = sin(c.x * 0.8 + t * 0.5) + sin(c.y * 0.9 - t * 0.37) + sin((c.x + c.y) * 0.6 + t * 0.29);
    return vec2(v * 0.12 + t * 0.015, 0.25 + 0.75 * smoothstep(-1.0, 2.0, v));
  }
  if (e == 3) { // twinkle: holes flash at random
    float f = pow(max(0.0, sin(t * (0.3 + h * 0.5) + h * TAU)), 6.0);
    return vec2(h * 0.6 + t * 0.01, 0.06 + f);
  }
  // 4: scanner bar sweeping up and down, like a Larson scanner
  float y = 3.2 * sin(t * 0.35);
  return vec2(c.y * 0.08 + t * 0.02, 0.08 + exp(-pow((c.y - y) * 1.3, 2.0)));
}

vec3 scene(vec2 p, float t) {
  vec2 q = p * LW_SCALE;
  gUnit = LW_SCALE;

  vec2 c; vec3 id;
  triCell(q, c, id);
  vec2 l = q - c;
  l.y *= mix(1.0, -1.0, id.z);
  vec2 v = triVertex(q);

  // hub radius grows towards the middle (big hubs ring the centre hole)
  float rv = length(v);
  float hub = 0.19 + 0.21 * (1.0 - smoothstep(1.0, 3.2, rv));

  // hole = inside the inset triangle and outside the hub
  float dHole = max(sdTri(l, 0.5) + LW_BAR, hub - length(q - v));
  vec2 cell = c;
  // the 6 triangles around the centre node merge into one big hexagonal hole
  if (length(c) < 0.7) {
    dHole = sdHex(q, SQ3 * 0.5 - LW_BAR);
    cell = vec2(0.0);
  }

  // light behind this hole, cycling through the effects with crossfades
  float h = hash12(cell * 1.37 + uSeed);
  float mt = t / 22.0 + uSeed;
  float k = floor(mt);
  int e0 = int(mod(k, LW_EFFECTS)), e1 = int(mod(k + 1.0, LW_EFFECTS));
  float fm = smoothstep(0.7, 1.0, fract(mt));
  // crossfade the colours, not the palette positions: the two effects' positions can be
  // many palette cycles apart, and blending them raced every hole through the palette
  vec2 E0 = lwEffect(e0, cell, h, t), E1 = lwEffect(e1, cell, h, t);
  vec3 light = mix(pal(E0.x) * E0.y, pal(E1.x) * E1.y, fm);

  // the LED strips sit on the back of the lattice bars, so each hole is brightest along
  // its edges and falls off towards the middle (the big centre hole gets quite dark inside)
  float depth = max(-dHole, 0.0);
  float edgeLit = 0.22 + 1.0 * exp(-depth / 0.07) + 0.25 * exp(-depth / 0.25);
  vec3 col = light * edgeLit * fillAA(dHole);
  return col;
}
