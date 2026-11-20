// Lattice Current — the wall's triangle lattice with comets of light racing along the
// channels between the triangles. They light up the triangle edges they pass, and every
// lattice vertex a comet runs through pops open into a hexagon that fades with its trail.

const float LH = 0.8660254; // spacing between parallel lattice lines (side 1)

// Comet brightness at position s along line k of family fam.
float comet(float s, float k, float fam, float t) {
  float h = hash12(vec2(k, fam * 7.1) + uSeed);
  float h2 = hash12(vec2(k * 1.7, fam + 3.3) + uSeed);
  float dirS = h2 > 0.5 ? 1.0 : -1.0;
  float speed = 0.45 + 0.6 * h;          // lattice units per second
  float P = 7.0 + 7.0 * h2;              // spacing between comets on one line
  float u = fract((t * speed - s * dirS) / P + h); // 0 at the head, grows along the trail
  float trail = exp(-u * P / 1.6);
  // lines switch on and off slowly, so the traffic keeps changing
  float on = smoothstep(0.4, 0.7, 0.5 + 0.5 * sin(t * 0.06 + h * TAU + fam * 2.1));
  return trail * on;
}

vec3 scene(vec2 p, float t) {
  float scale = 7.0 + 0.8 * sin(t * 0.04 + uSeed);
  p = rot(-t * 0.008 + uSeed) * p;
  vec2 q = p * scale;
  gUnit = scale;

  vec2 c; vec3 id;
  triCell(q, c, id);
  vec2 l = q - c;
  l.y *= mix(1.0, -1.0, id.z);
  float dTri = sdTri(l, 0.5);
  vec2 v = triVertex(q);

  float w = 0.02, inset = 0.075;
  vec3 lineCol = vec3(0.0);
  float near = 0.0; vec3 nearCol = vec3(0.0);
  float hexAmt = 0.0; vec3 hexCol = vec3(0.0);

  // the lattice lines come in three families, at 0°, 60° and 120°
  for (int f = 0; f < 3; f++) {
    float fam = float(f);
    float a = fam * PI / 3.0;
    vec2 dir = vec2(cos(a), sin(a));
    vec2 n = vec2(-dir.y, dir.x);

    float y = dot(q, n) / LH;
    float k = floor(y + 0.5);
    float dl = abs(y - k) * LH;           // distance to the nearest line of this family
    float cm = comet(dot(q, dir), k, fam, t);
    vec3 cc = pal(fam * 0.333 + hash12(vec2(k, fam) + uSeed) * 0.15 + t * 0.01);

    // the comet itself, running down the channel
    lineCol += cc * cm * (1.5 * stroke(dl, 0.012) + halo(dl, 0.02));
    // it lights the triangle edges along the channel
    float g = cm * smoothstep(0.3, 0.05, dl);
    if (g > near) { near = g; nearCol = cc; }
    // and opens a hexagon at each vertex it passes
    float kv = floor(dot(v, n) / LH + 0.5);
    float cv = comet(dot(v, dir), kv, fam, t);
    if (cv > hexAmt) { hexAmt = cv; hexCol = cc; }
  }

  float apo = 0.30 * smoothstep(0.15, 0.9, hexAmt);
  float dHex = sdHex(q - v, apo);
  float dShape = max(dTri + inset, -(dHex - inset * 1.2));

  float rc = length(c) / scale;
  float h = hash12(id.xy * 1.31 + id.z * 17.3 + uSeed);
  vec3 rest = pal(rc * 0.55 - t * 0.02 + h * 0.06) * 0.12; // dim resting glow
  vec3 tcol = rest + nearCol * near * 1.2;
  vec3 col = tcol * (stroke(dShape, w) + 0.08 * fillAA(dShape) + halo(dShape, w));
  col += lineCol * 0.8;

  float hexVis = smoothstep(0.02, 0.2, apo);
  col += hexCol * hexVis * (0.4 * fillAA(dHex) + stroke(dHex, w) + halo(dHex, w));
  return col;
}
