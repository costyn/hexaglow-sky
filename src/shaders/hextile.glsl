// Hextile — https://www.shadertoy.com/view/dtSXWV (Shadertoy, CC BY-NC-SA 3.0 unless the author says otherwise)
// Adapted for Hexaglow Sky: runs in ceiling space, no mouse zoom.
//
// The original's colour pattern gets denser forever (it multiplies by iTime), so after a while
// the edges turn into fast aliasing noise. Here its clock runs back and forth between 0 and
// HT_MAX instead: the small hexagons coalesce into big ones, then fall apart again.

const float HT_MAX = 3.0; // how far into the original's timeline to go before turning back

vec3 scene(vec2 p, float iTime) {
  float tt = HT_MAX * (1.0 - abs(1.0 - 2.0 * fract(iTime / (2.0 * HT_MAX))));

  vec2 v = p * 2.0,                  // Shadertoy uv spans ±1 vertically
       u = v * 10.0,                 // coords with zoom & scale
       o = vec2(.5, .866),           // hex offset
       a = mod(u, o + o) - o,        // grid 1
       b = mod(u - o, o + o) - o,    // grid 2
       h = dot(a, a) < dot(b, b) ? a : b, // combine grids for hex tile
       k = abs(h);

  float pp = pow(length(u - h), 2.) * tt / 60., // color & shadow pattern
        n = 6.2832;

  vec3 c = (1. - max(k.x, dot(k, o)) * 2.)                    // hex tile
         * (sin(pp * n) / 2. + 1.)                             // brightness pattern
         * (cos(radians(vec3(-95, -135, 170)) + pp * n) * .5 + .5) // color
         * (2. - length(v));                                   // darken screen edges
  return max(c, 0.0);
}
