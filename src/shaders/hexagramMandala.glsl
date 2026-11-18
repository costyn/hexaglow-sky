// Hexagram Mandala — concentric counter-rotating stars of David with orbiting
// hexagons and triangles, breathing slowly.
vec3 scene(vec2 p, float t) {
  vec3 col = vec3(0.0);
  const int N = 8;
  for (int i = 0; i < N; i++) {
    float fi = float(i);
    float R = (0.05 + fi * 0.075) * (1.0 + 0.06 * sin(t * 0.27 + fi * 0.7));
    float dir = mod(fi, 2.0) < 0.5 ? 1.0 : -1.0;
    vec2 rp = rot(t * 0.035 * dir * (1.0 + fi * 0.15) + fi * 0.3 + uSeed) * p;
    float r2 = R * 0.866;
    float d1 = sdTri(rp, r2);
    float d2 = sdTri(vec2(rp.x, -rp.y), r2);
    float lw = 0.0022 + 0.0006 * fi;
    float pulse = 0.5 + 0.5 * sin(t * 0.5 - fi * 0.8);
    float s = max(stroke(d1, lw), stroke(d2, lw)) + halo(min(abs(d1), abs(d2)), lw);
    col += pal(fi * 0.09 + t * 0.012) * s * (0.25 + 0.75 * pulse);
  }
  float r = length(p);
  // orbiting filled hexagons
  {
    float n = 12.0, sa = TAU / n;
    float a = atan(p.y, p.x) + t * 0.04;
    float ai = floor(a / sa + 0.5);
    a -= ai * sa;
    float Ro = 0.36 + 0.02 * sin(t * 0.2);
    vec2 lp = vec2(cos(a), sin(a)) * r - vec2(Ro, 0.0);
    float d = sdHex(lp, 0.02);
    float tw = 0.5 + 0.5 * sin(t * 0.8 + ai * 1.7);
    col += pal(ai / n + t * 0.02) * (0.8 * fillAA(d) + halo(d, 0.004)) * tw;
  }
  // outer ring of outward-pointing triangles
  {
    float n = 18.0, sa = TAU / n;
    float a = atan(p.y, p.x) - t * 0.025;
    float ai = floor(a / sa + 0.5);
    a -= ai * sa;
    float Ro = 0.62;
    vec2 lp = vec2(cos(a), sin(a)) * r - vec2(Ro, 0.0);
    lp = vec2(-lp.y, lp.x); // point outward
    float d = sdTri(lp, 0.035);
    float tw = smoothstep(0.2, 1.0, sin(t * 0.3 + ai * 0.9));
    col += pal(ai / n * 0.5 + 0.5 + t * 0.01) * (stroke(d, 0.0025) + halo(d, 0.0025)) * tw;
  }
  return col;
}
