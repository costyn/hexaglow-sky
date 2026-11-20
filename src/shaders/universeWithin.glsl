// The Universe Within - by Martijn Steinrucken aka BigWings 2018
// Tutorial: https://youtu.be/3CycKKJiwis
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// Adapted for Hexaglow Sky: runs in ceiling space; no mouse parallax, no audio glow,
// and no fade-out every 230 s (it would black out the ceiling). Each depth layer takes
// its colour from the WLED palette, so the layers drift through it as they fly in.

#define S(a, b, t) smoothstep(a, b, t)
#define NUM_LAYERS 4.

float N21(vec2 p) {
  vec3 a = fract(vec3(p.xyx) * vec3(213.897, 653.453, 253.098));
  a += dot(a, a.yzx + 79.76);
  return fract((a.x + a.y) * a.z);
}

vec2 GetPos(vec2 id, vec2 offs, float t) {
  float n = N21(id + offs);
  float n1 = fract(n * 10.);
  float n2 = fract(n * 100.);
  float a = t + n;
  return offs + vec2(sin(a * n1), cos(a * n2)) * .4;
}

float df_line(in vec2 a, in vec2 b, in vec2 p) {
  vec2 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h);
}

float uwLine(vec2 a, vec2 b, vec2 uv) {
  float r1 = .04;
  float r2 = .01;
  float d = df_line(a, b, uv);
  float d2 = length(a - b);
  float fade = S(1.5, .5, d2);
  fade += S(.05, .02, abs(d2 - .75));
  return S(r1, r2, d) * fade;
}

float NetLayer(vec2 st, float n, float t) {
  vec2 id = floor(st) + n;
  st = fract(st) - .5;

  vec2 p[9];
  int i = 0;
  for (float y = -1.; y <= 1.; y++) {
    for (float x = -1.; x <= 1.; x++) {
      p[i++] = GetPos(id, vec2(x, y), t);
    }
  }

  float m = 0.;
  float sparkle = 0.;
  for (int i = 0; i < 9; i++) {
    m += uwLine(p[4], p[i], st);
    float d = length(st - p[i]);
    float s = (.005 / max(d * d, 1e-5));
    s *= S(1., .7, d);
    float pulse = sin((fract(p[i].x) + fract(p[i].y) + t) * 5.) * .4 + .6;
    pulse = pow(pulse, 20.);
    s *= pulse;
    sparkle += s;
  }

  m += uwLine(p[1], p[3], st);
  m += uwLine(p[1], p[5], st);
  m += uwLine(p[7], p[5], st);
  m += uwLine(p[7], p[3], st);

  float sPhase = (sin(t + n) + sin(t * .1)) * .25 + .5;
  sPhase += pow(sin(t * .1) * .5 + .5, 50.) * 5.;
  m += sparkle * sPhase;
  return m;
}

vec3 scene(vec2 uv, float iTime) {
  float t = iTime * .1;
  float s = sin(t);
  float c = cos(t);
  mat2 rm = mat2(c, -s, s, c);
  vec2 st = uv * rm;

  vec3 col = vec3(0.);
  for (float i = 0.; i < 1.; i += 1. / NUM_LAYERS) {
    float z = fract(t + i);
    float size = mix(15., 1., z);
    float fade = S(0., .6, z) * S(1., .8, z);
    // colour per layer, shifting with depth; the layer's offset (i - z) is constant,
    // so a layer keeps its colour while it flies in and only drifts slowly
    vec3 layerCol = pal(z * 0.35 + i * 0.5 + t * 0.15 + uSeed) * 1.15;
    col += layerCol * fade * NetLayer(st * size, i, iTime);
  }
  col *= 1. - dot(uv, uv);
  return min(max(col, 0.0), vec3(20.0));
}
