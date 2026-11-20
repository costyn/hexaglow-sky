// Shader Art — by kishimisu, https://www.shadertoy.com/view/mtyGWy
// Material of the tutorial https://youtu.be/f4s1h2YETNY. Adapted for Hexaglow Sky:
// runs in ceiling space; keeps its own cosine palette (https://iquilezles.org/articles/palettes/).

vec3 saPalette(float t) {
  vec3 a = vec3(0.5, 0.5, 0.5);
  vec3 b = vec3(0.5, 0.5, 0.5);
  vec3 c = vec3(1.0, 1.0, 1.0);
  vec3 d = vec3(0.263, 0.416, 0.557);
  return a + b * cos(6.28318 * (c * t + d));
}

vec3 scene(vec2 p, float iTime) {
  vec2 uv = p * 2.0; // Shadertoy uv spans ±1 vertically, ceiling space spans ±0.5
  vec2 uv0 = uv;
  vec3 finalColor = vec3(0.0);

  for (float i = 0.0; i < 4.0; i++) {
    uv = fract(uv * 1.5) - 0.5;
    float d = length(uv) * exp(-length(uv0));
    vec3 col = saPalette(length(uv0) + i * 0.4 + iTime * 0.4);
    d = sin(d * 8.0 + iTime) / 8.0;
    d = abs(d);
    d = pow(0.01 / max(d, 1e-4), 1.2); // guard: 0.01/0 would put inf into the bloom
    finalColor += col * d;
  }
  return min(finalColor, vec3(20.0));
}
