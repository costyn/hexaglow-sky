// Chevron Cascade — mirrored slanted segments forming chevrons, X's and diamonds
// (the top half of the mockup), sliding slowly and fading in and out piece by piece.
vec3 scene(vec2 p, float t) {
  vec3 col = vec3(0.0);
  float u = abs(p.x);
  const float k = 0.57735; // tan 30deg
  for (int layer = 0; layer < 3; layer++) {
    float fl = float(layer);
    float s = layer == 0 ? 1.0 : (layer == 1 ? -1.0 : 0.0);
    float slopeCos = layer == 2 ? 1.0 : 0.866;
    float rowH = layer == 2 ? 0.11 : 0.15;
    float colW = layer == 2 ? 0.12 : 0.2;
    float w = p.y + s * u * k;
    w += t * 0.018 * (layer == 1 ? -1.0 : 1.0) + uSeed;
    float rowF = w / rowH;
    float row = floor(rowF);
    float wl = fract(rowF) - 0.5;
    float cu = u / colW + row * 0.5 * fl;
    float cidx = floor(cu);
    float uf = fract(cu);
    vec2 cid = vec2(row, cidx) + fl * 41.0;
    float h = hash12(cid + uSeed);
    float h2 = hash12(cid * 1.7 + 3.1);
    float exists = step(layer == 2 ? 0.72 : 0.42, h2);
    float lo = 0.08 + 0.15 * h, hi = 0.92 - 0.1 * fract(h * 7.0);
    float du = max(lo - uf, uf - hi) * colW;
    float dl = abs(wl) * rowH * slopeCos;
    float d = length(vec2(max(du, 0.0), dl));
    float ph = sin(t * (0.18 + 0.12 * h2) + h * TAU);
    float life = smoothstep(-0.2, 0.8, ph);
    float lw = layer == 2 ? 0.0028 : 0.0042;
    vec3 c = pal(row * 0.045 + fl * 0.33 + u * 0.4 - t * 0.012);
    col += c * exists * life * (stroke(d, lw) + halo(d, lw)) * (layer == 2 ? 0.8 : 1.0);
  }
  // keep the very edges calmer, centre axis brightest
  col *= 0.7 + 0.3 * smoothstep(0.9, 0.0, u);
  return col;
}
