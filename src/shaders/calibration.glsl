// Keystone calibration pattern, drawn in ceiling space. Drag the corners until the
// squares look square and the circle looks round on the ceiling.
uniform float uAspect;
vec3 scene(vec2 p, float t) {
  vec3 col = vec3(0.0);
  // fine grid of squares
  vec2 g = abs(fract(p / 0.1 + 0.5) - 0.5) * 0.1;
  float dg = min(g.x, g.y);
  col += vec3(0.15, 0.45, 0.6) * stroke(dg, 0.0012);
  // world rectangle that the four handles pin
  vec2 r = abs(p) - vec2(uAspect * 0.5, 0.5);
  float dr = max(r.x, r.y);
  col += vec3(1.0, 0.25, 0.45) * stroke(dr, 0.004);
  // circle + hexagon + crosshair
  col += vec3(1.0) * stroke(length(p) - 0.4, 0.003);
  col += vec3(0.4, 1.0, 0.6) * stroke(sdHex(p, 0.25), 0.003);
  col += vec3(0.8) * (stroke(p.x, 0.0015) + stroke(p.y, 0.0015)) * step(length(p), 0.48);
  // arrow pointing "up" so mirroring is obvious
  vec2 ap = p - vec2(0.0, 0.42);
  col += vec3(1.0, 0.8, 0.2) * stroke(sdTri(ap, 0.03), 0.003);
  return col;
}
