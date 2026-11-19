// Triangle Drift — scattered outlined triangles that slowly fade in and out while
// drifting, around a pulsing cluster of filled hexagons (the mockup's centre).
vec3 scene(vec2 p, float t) {
  vec3 col = vec3(0.0);
  vec2 mp = vec2(abs(p.x), p.y);
  for (int L = 0; L < 3; L++) {
    float fl = float(L);
    float cs = 0.13 + fl * 0.075;
    vec2 off = vec2(-t * 0.006 * (1.0 + fl * 0.4), t * 0.012 * (1.0 + fl * 0.5)) + uSeed;
    vec2 g = (mp + off) / cs;
    vec2 cid = floor(g);
    vec2 f = fract(g) - 0.5;
    float h = hash12(cid + fl * 31.7 + uSeed);
    float h2 = hash12(cid * 1.7 + 5.1 + fl);
    float ph = fract(t * 0.035 * (0.6 + h2) + h);
    float life = sin(ph * PI);
    life *= life;
    float exists = step(0.38, h2);
    vec2 jit = (hash22(cid + fl * 7.0) - 0.5) * 0.25;
    vec2 lp = f - jit;
    lp.y *= mix(1.0, -1.0, step(0.5, fract(h * 7.3)));
    float sz = 0.17 + 0.11 * h2;
    float d = sdTri(lp, sz) * cs;
    float lw = 0.0026 + 0.0008 * fl;
    vec3 c = pal(h * 0.25 + fl * 0.18 + length(p) * 0.3 - t * 0.01);
    // fade the glow before the cell border so neighbouring cells don't show a seam
    vec2 ef = 0.5 - abs(f);
    float edge = smoothstep(0.0, 0.12, min(ef.x, ef.y));
    col += c * exists * life * (stroke(d, lw) + halo(d, lw) * edge + 0.08 * fillAA(d));
  }
  // central hexagon cluster
  float scale = 10.0;
  vec2 q = p * scale;
  vec2 v = triVertex(q);
  float rv = length(v) / scale;
  float R = 0.12 + 0.07 * sin(t * 0.11 + uSeed);
  float hv = hash12(v + uSeed);
  float m = 1.0 - smoothstep(R - 0.04, R + 0.02, rv + hv * 0.03);
  float tw = 0.55 + 0.45 * sin(t * 0.6 + hv * TAU);
  float dh = sdHex(q - v, 0.32 + 0.06 * sin(t * 0.3 - rv * 12.0)) / scale;
  vec3 hc = pal(rv * 1.2 + hv * 0.15 - t * 0.02 + 0.5);
  col += hc * m * tw * (0.7 * fillAA(dh) + stroke(dh, 0.002));
  // a single large central hexagon outline breathing
  float dc = sdHex(p, 0.05 + 0.015 * sin(t * 0.25));
  col += pal(t * 0.015) * (stroke(dc, 0.003) + halo(dc, 0.003)) * 0.9;
  return col;
}
