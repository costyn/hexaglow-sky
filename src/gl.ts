export const FULLSCREEN_VS = `#version 300 es
void main() {
  vec2 v = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));
  gl_Position = vec4(v * 2.0 - 1.0, 0.0, 1.0);
}`;

export class Program {
  prog: WebGLProgram;
  private locs = new Map<string, WebGLUniformLocation | null>();
  constructor(private gl: WebGL2RenderingContext, fs: string, label: string) {
    const p = gl.createProgram()!;
    gl.attachShader(p, compile(gl, gl.VERTEX_SHADER, FULLSCREEN_VS, label + ' (vs)'));
    gl.attachShader(p, compile(gl, gl.FRAGMENT_SHADER, fs, label));
    gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw new Error(`${label}: ${gl.getProgramInfoLog(p)}`);
    this.prog = p;
  }
  use() { this.gl.useProgram(this.prog); return this; }
  loc(name: string) {
    if (!this.locs.has(name)) this.locs.set(name, this.gl.getUniformLocation(this.prog, name));
    return this.locs.get(name)!;
  }
  f(name: string, ...v: number[]) {
    const l = this.loc(name);
    if (v.length === 1) this.gl.uniform1f(l, v[0]);
    else if (v.length === 2) this.gl.uniform2f(l, v[0], v[1]);
    else if (v.length === 3) this.gl.uniform3f(l, v[0], v[1], v[2]);
    return this;
  }
  tex(name: string, unit: number, t: WebGLTexture) {
    const gl = this.gl;
    gl.activeTexture(gl.TEXTURE0 + unit);
    gl.bindTexture(gl.TEXTURE_2D, t);
    gl.uniform1i(this.loc(name), unit);
    return this;
  }
}

function compile(gl: WebGL2RenderingContext, type: number, src: string, label: string) {
  const s = gl.createShader(type)!;
  gl.shaderSource(s, src);
  gl.compileShader(s);
  if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
    const numbered = src.split('\n').map((l, i) => `${String(i + 1).padStart(4)}: ${l}`).join('\n');
    console.error(numbered);
    throw new Error(`${label}: ${gl.getShaderInfoLog(s)}`);
  }
  return s;
}

export type Target = { fbo: WebGLFramebuffer; tex: WebGLTexture; w: number; h: number };

export function createTarget(gl: WebGL2RenderingContext, w: number, h: number, hdr: boolean): Target {
  const tex = gl.createTexture()!;
  gl.bindTexture(gl.TEXTURE_2D, tex);
  if (hdr) gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, w, h, 0, gl.RGBA, gl.HALF_FLOAT, null);
  else gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  const fbo = gl.createFramebuffer()!;
  gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
  gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0);
  return { fbo, tex, w, h };
}

export function deleteTarget(gl: WebGL2RenderingContext, t: Target | undefined) {
  if (!t) return;
  gl.deleteFramebuffer(t.fbo);
  gl.deleteTexture(t.tex);
}
