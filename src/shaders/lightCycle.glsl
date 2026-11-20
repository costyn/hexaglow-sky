// Light Cycle — "Octgrams" by whisky_shusuky (2020), https://www.shadertoy.com/view/tlVGDt
// Inspired by arabesque. Adapted for Hexaglow Sky: runs in ceiling space and is
// coloured with the current WLED palette instead of the original blue.

float lcTime = 0.0;

// the original's rotation (opposite direction to common.glsl's rot)
mat2 lcRot(float a) {
  float c = cos(a), s = sin(a);
  return mat2(c, s, -s, c);
}

float lcSdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float lcBox(vec3 pos, float scale) {
  pos *= scale;
  return -lcSdBox(pos, vec3(0.4, 0.4, 0.1)) / 1.5;
}

float lcBoxSet(vec3 pos) {
  vec3 o = pos;
  float s = sin(lcTime * 0.4);
  float sc = 2.0 - abs(s) * 1.5;
  pos = o; pos.y += s * 2.5; pos.xy *= lcRot(0.8);
  float b1 = lcBox(pos, sc);
  pos = o; pos.y -= s * 2.5; pos.xy *= lcRot(0.8);
  float b2 = lcBox(pos, sc);
  pos = o; pos.x += s * 2.5; pos.xy *= lcRot(0.8);
  float b3 = lcBox(pos, sc);
  pos = o; pos.x -= s * 2.5; pos.xy *= lcRot(0.8);
  float b4 = lcBox(pos, sc);
  pos = o; pos.xy *= lcRot(0.8);
  float b5 = lcBox(pos, 0.5) * 6.0;
  float b6 = lcBox(o, 0.5) * 6.0;
  return max(max(max(max(max(b1, b2), b3), b4), b5), b6);
}

vec3 scene(vec2 p, float iTime) {
  p *= 2.0; // Shadertoy uv spans ±1 vertically, ceiling space spans ±0.5
  vec3 ro = vec3(0.0, -0.2, iTime * 4.0);
  vec3 ray = normalize(vec3(p, 1.5));
  ray.xy = ray.xy * lcRot(sin(iTime * 0.03) * 5.0);
  ray.yz = ray.yz * lcRot(sin(iTime * 0.05) * 0.2);
  float t = 0.1;
  float ac = 0.0;
  vec3 glow = vec3(0.0);

  for (int i = 0; i < 99; i++) {
    vec3 pos = ro + ray * t;
    pos = mod(pos - 2.0, 4.0) - 2.0;
    lcTime = iTime - float(i) * 0.01;
    float d = max(abs(lcBoxSet(pos)), 0.01);
    float a = exp(-d * 23.0);
    ac += a;
    // colour by depth, so the octgram tunnel runs through the palette
    glow += pal(t * 0.025 - iTime * 0.02 + uSeed) * a;
    t += d * 0.55;
  }

  // the original's grey glow (ac * 0.02), squared for contrast so the bloom pass
  // doesn't wash it out, tinted with the depth-weighted palette colour
  float g = ac * 0.02;
  vec3 col = glow / max(ac, 1e-3) * g * g * 1.1;
  // the original's pulsing backdrop, in a palette colour and much dimmer
  col += pal(0.5 + iTime * 0.01 + uSeed) * (0.035 + 0.02 * sin(iTime));
  return col;
}
