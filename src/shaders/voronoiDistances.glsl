// Voronoi - distances — https://www.shadertoy.com/view/ldl3W8
// The MIT License
// Copyright © 2013 Inigo Quilez
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Mathematically correct cell interior distances and edges for Voronoi:
// https://iquilezles.org/articles/voronoilines
//
// Adapted for Hexaglow Sky: runs in ceiling space and uses the procedural hash
// instead of the noise texture. Coloured with the WLED palette: each cell gets its
// own palette colour, and the borders sweep through the palette from the centre out.

float vdTime = 0.0;

vec2 hash2(vec2 p) {
  return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

vec3 voronoi(in vec2 x, out vec2 cellId) {
  vec2 ip = floor(x);
  vec2 fp = fract(x);

  // first pass: regular voronoi
  vec2 mg, mr;
  float md = 8.0;
  for (int j = -1; j <= 1; j++)
  for (int i = -1; i <= 1; i++) {
    vec2 g = vec2(float(i), float(j));
    vec2 o = hash2(ip + g);
    o = 0.5 + 0.5 * sin(vdTime + 6.2831 * o);
    vec2 r = g + o - fp;
    float d = dot(r, r);
    if (d < md) { md = d; mr = r; mg = g; }
  }

  // second pass: distance to borders
  md = 8.0;
  for (int j = -2; j <= 2; j++)
  for (int i = -2; i <= 2; i++) {
    vec2 g = mg + vec2(float(i), float(j));
    vec2 o = hash2(ip + g);
    o = 0.5 + 0.5 * sin(vdTime + 6.2831 * o);
    vec2 r = g + o - fp;
    if (dot(mr - r, mr - r) > 0.00001)
      md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
  }
  cellId = ip + mg;
  return vec3(md, mr);
}

vec3 scene(vec2 p, float iTime) {
  vdTime = iTime;
  // the original shows 8 cells across the width; ceiling space is ~1.6 wide
  vec2 cellId;
  vec3 c = voronoi(5.0 * p, cellId);
  vec3 cellCol = pal(hash12(cellId + 0.37) * 0.4 + iTime * 0.02 + uSeed);
  vec3 edgeCol = pal(length(p) * 0.4 - iTime * 0.03 + 0.5 + uSeed);

  // isolines, tinted with the cell's colour
  vec3 col = c.x * (0.5 + 0.5 * sin(64.0 * c.x)) * cellCol * 1.3;
  // borders
  col = mix(edgeCol, col, smoothstep(0.04, 0.07, c.x));
  // feature points
  float dd = length(c.yz);
  vec3 dotCol = mix(cellCol, vec3(1.0), 0.3);
  col = mix(dotCol, col, smoothstep(0.0, 0.12, dd));
  col += dotCol * (1.0 - smoothstep(0.0, 0.04, dd));
  return col;
}
