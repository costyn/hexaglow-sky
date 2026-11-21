// Moiré Lattice — two of the wall's triangle lattices, one behind the other, as if looking
// through the laser-cut wall at a second one. The front layer is slightly rotated against the
// back, so their lines beat into a giant hexagonal moiré; where the two lattices' vertices line
// up, hexagons bloom, tracing that giant pattern. The layers drift at different speeds
// (parallax), which the moiré magnifies into a much faster, sweeping motion.

struct Layer { float d; vec2 c; vec3 id; vec2 v; };

Layer lattice(vec2 q) {
  Layer L;
  triCell(q, L.c, L.id);
  vec2 l = q - L.c;
  l.y *= mix(1.0, -1.0, L.id.z);
  L.d = sdTri(l, 0.5);
  L.v = triVertex(q);
  return L;
}

vec3 scene(vec2 p, float t) {
  float scale = 8.5;
  gUnit = scale;
  float ang = t * 0.01 + uSeed;
  // relative twist between the layers sets the moiré size: ~1 / angle lattice cells
  float twist = radians(9.0 + 4.0 * sin(t * 0.03 + uSeed));
  // parallax: the back layer drifts slower than the front
  vec2 drift = vec2(cos(uSeed * 3.0), sin(uSeed * 3.0));
  vec2 offF = drift * t * 0.06;
  vec2 offB = drift * t * 0.035;

  mat2 rF = rot(ang + twist), rB = rot(ang);
  vec2 qF = rF * p * scale + offF;
  vec2 qB = rB * p * scale + offB;
  Layer F = lattice(qF);
  Layer B = lattice(qB);

  // how well this front vertex lines up with the nearest back vertex
  vec2 vp = transpose(rF) * (F.v - offF);           // front vertex, in scale-space
  vec2 qBv = rB * vp + offB;
  float align = length(qBv - triVertex(qBv));       // lattice units
  float hexAmt = smoothstep(0.4, 0.06, align);
  float apo = 0.30 * hexAmt;
  float dHex = sdHex(qF - F.v, apo);

  float inset = 0.075, w = 0.02;
  float dF = max(F.d + inset, -(dHex - inset * 1.2));
  float dB = B.d + inset;

  float rc = length(F.c) / scale;
  float h = hash12(F.id.xy * 1.31 + F.id.z * 17.3 + uSeed);
  // shadow waves rolling across the front layer (deeper than Lattice Bloom's)
  float wave = 0.5 + 0.5 * sin(rc * 6.0 - t * 0.35);
  float act = 0.1 + 0.9 * smoothstep(0.3, 0.85, wave);
  act *= 0.75 + 0.25 * sin(t * 0.6 + h * TAU);

  // back layer: dimmer, thinner, offset in the palette, seen mostly through the front's gaps
  float rb = length(B.c) / scale;
  vec3 bcol = pal(rb * 0.5 - t * 0.02 + 0.5) * 0.35;
  // the back layer has its own, slower shadow waves, so the two interfere
  float bwave = 0.5 + 0.5 * sin(rb * 5.0 + t * 0.22 + 1.7);
  bcol *= 0.25 + 0.75 * smoothstep(0.2, 0.8, bwave);
  vec3 col = bcol * (stroke(dB, w * 0.8) + halo(dB, w));
  col *= 1.0 - 0.55 * fillAA(dF);

  // front layer
  vec3 fcol = pal(rc * 0.5 - t * 0.025 + h * 0.06);
  col += fcol * act * (stroke(dF, w) + 0.06 * fillAA(dF) + halo(dF, w));

  // alignment hexagons
  float hexVis = smoothstep(0.02, 0.2, apo);
  vec3 hcol = pal(rc * 0.5 - t * 0.025 + 0.35);
  col += hcol * hexVis * (0.4 * fillAA(dHex) + stroke(dHex, w) + halo(dHex, w));
  return col;
}
