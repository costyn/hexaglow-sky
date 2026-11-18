// Sacred Tunnel — nested triangles and hexagons emerging from the centre and
// drifting outward with a slow exponential zoom. Classic psy main-stage.
vec3 scene(vec2 p, float t) {
  vec3 col = vec3(0.0);
  p = rot(t * 0.015) * p;
  const int N = 16;
  float speed = 0.28;
  for (int k = 0; k < N; k++) {
    float g = float(k) + t * speed;
    float cyc = floor(g / float(N));
    float f = fract(g / float(N));
    float id = float(k) + cyc * float(N);
    float R = 0.015 * exp(f * 4.6);
    float fade = smoothstep(0.0, 0.12, f) * (1.0 - smoothstep(0.75, 1.0, f));
    float h = hash12(vec2(id, uSeed));
    float dir = mod(id, 2.0) < 0.5 ? 1.0 : -1.0;
    vec2 rp = rot(id * 0.5236 + t * 0.03 * dir) * p;
    float shape = mod(id, 3.0);
    float d;
    if (shape < 1.0) d = sdHex(rp, R * 0.866);
    else if (shape < 2.0) d = sdTri(rp, R * 0.866);
    else d = min(sdTri(rp, R * 0.866), sdTri(vec2(rp.x, -rp.y), R * 0.866)); // hexagram
    float lw = 0.0018 + R * 0.006;
    vec3 c = pal(id * 0.061 + h * 0.1);
    col += c * fade * (stroke(d, lw) + halo(d, lw));
  }
  // faint radial spokes
  float r = length(p);
  float a = atan(p.y, p.x);
  float seg = PI / 3.0;
  float ds = r * sin(abs(mod(a + seg * 0.5, seg) - seg * 0.5));
  col += pal(t * 0.01 + 0.5) * stroke(ds, 0.0012) * 0.25 * smoothstep(0.05, 0.5, r);
  return col;
}
