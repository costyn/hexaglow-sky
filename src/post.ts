const HEAD = `#version 300 es
precision highp float;
out vec4 outColor;
uniform vec2 uOutRes;
`;

/** Mixes the two scene buffers (scene crossfade) and downsamples with a 4-tap box filter. */
export const DOWNSAMPLE_MIX_FS = HEAD + `
uniform sampler2D uA, uB;
uniform float uMix;
uniform vec2 uTexel;
vec3 s(sampler2D t, vec2 uv) {
  return 0.25 * (texture(t, uv + uTexel * vec2(-1, -1)).rgb + texture(t, uv + uTexel * vec2(1, -1)).rgb
               + texture(t, uv + uTexel * vec2(-1, 1)).rgb + texture(t, uv + uTexel * vec2(1, 1)).rgb);
}
void main() {
  vec2 uv = gl_FragCoord.xy / uOutRes;
  vec3 c = s(uA, uv);
  if (uMix > 0.0) c = mix(c, s(uB, uv), uMix);
  outColor = vec4(c, 1.0);
}`;

export const DOWNSAMPLE_FS = HEAD + `
uniform sampler2D uSrc;
uniform vec2 uTexel;
void main() {
  vec2 uv = gl_FragCoord.xy / uOutRes;
  vec3 c = 0.25 * (texture(uSrc, uv + uTexel * vec2(-1, -1)).rgb + texture(uSrc, uv + uTexel * vec2(1, -1)).rgb
                 + texture(uSrc, uv + uTexel * vec2(-1, 1)).rgb + texture(uSrc, uv + uTexel * vec2(1, 1)).rgb);
  outColor = vec4(c, 1.0);
}`;

/** 9-tap gaussian using linear sampling (5 fetches). */
export const BLUR_FS = HEAD + `
uniform sampler2D uSrc;
uniform vec2 uDir;
void main() {
  vec2 uv = gl_FragCoord.xy / uOutRes;
  vec2 o1 = uDir * 1.3846153846, o2 = uDir * 3.2307692308;
  vec3 c = texture(uSrc, uv).rgb * 0.2270270270;
  c += (texture(uSrc, uv + o1).rgb + texture(uSrc, uv - o1).rgb) * 0.3162162162;
  c += (texture(uSrc, uv + o2).rgb + texture(uSrc, uv - o2).rgb) * 0.0702702703;
  outColor = vec4(c, 1.0);
}`;

export const COMPOSITE_FS = HEAD + `
uniform sampler2D uA, uB, uBloom1, uBloom2;
uniform float uMix, uBloom, uBright, uMaster, uEdge;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void main() {
  vec2 uv = gl_FragCoord.xy / uOutRes;
  vec2 suv = uv;
  vec3 c = texture(uA, suv).rgb;
  if (uMix > 0.0) c = mix(c, texture(uB, suv).rgb, uMix);
  c += (texture(uBloom1, suv).rgb * 0.8 + texture(uBloom2, suv).rgb * 1.1) * uBloom;
  c *= uBright;
  c = 1.0 - exp(-c * 1.5);            // soft shoulder, keeps hue in bright cores
  vec2 e = smoothstep(vec2(0.0), vec2(uEdge), uv) * smoothstep(vec2(0.0), vec2(uEdge), 1.0 - uv);
  c *= e.x * e.y * uMaster;
  c += (hash(gl_FragCoord.xy) - 0.5) / 255.0; // dither to avoid banding in the glow
  outColor = vec4(max(c, 0.0), 1.0);
}`;
