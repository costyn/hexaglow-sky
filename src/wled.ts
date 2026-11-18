/**
 * Follows a WLED controller's palette over its WebSocket API (ws://<ip>/ws).
 * WLED pushes its full state on connect and on every change, so the browser can
 * listen directly — no UDP bridge needed.
 */
export type WledPaletteEvent = { pal: number; cols: number[][]; transitionMs: number };
export type WledStatus = 'off' | 'connecting' | 'connected' | 'error';

export class WledSync {
  private ws?: WebSocket;
  private retry = 1000;
  private timer?: number;
  private last = '';
  status: WledStatus = 'off';

  constructor(
    private onPalette: (e: WledPaletteEvent) => void,
    private onStatus: (s: WledStatus, host: string) => void,
  ) {}

  host = '';

  connect(host: string) {
    this.disconnect();
    this.host = host.trim().replace(/^https?:\/\//, '').replace(/\/.*$/, '');
    if (!this.host) return;
    this.open();
  }

  disconnect() {
    clearTimeout(this.timer);
    if (this.ws) { this.ws.onclose = null; this.ws.close(); }
    this.ws = undefined;
    this.last = '';
    this.setStatus('off');
  }

  private setStatus(s: WledStatus) { this.status = s; this.onStatus(s, this.host); }

  private open() {
    this.setStatus('connecting');
    let ws: WebSocket;
    try { ws = new WebSocket(`ws://${this.host}/ws`); } catch { this.setStatus('error'); return this.schedule(); }
    this.ws = ws;
    ws.onopen = () => { this.retry = 1000; this.setStatus('connected'); };
    ws.onmessage = (ev) => {
      if (typeof ev.data !== 'string') return; // binary = live LED preview frames
      try { this.handle(JSON.parse(ev.data)); } catch { /* ignore */ }
    };
    ws.onclose = () => { this.setStatus('error'); this.schedule(); };
    ws.onerror = () => ws.close();
  }

  private schedule() {
    this.timer = window.setTimeout(() => this.open(), this.retry);
    this.retry = Math.min(this.retry * 2, 15000);
  }

  private handle(msg: any) {
    const st = msg?.state ?? msg;
    const segs: any[] | undefined = st?.seg;
    if (!Array.isArray(segs) || !segs.length) return;
    const main = st.mainseg ?? 0;
    const seg = segs.find((s) => s.id === main) ?? segs[0];
    if (typeof seg?.pal !== 'number') return;
    const cols: number[][] = Array.isArray(seg.col) ? seg.col : [];
    const key = JSON.stringify([seg.pal, cols]);
    if (key === this.last) return;
    this.last = key;
    const transitionMs = typeof st.transition === 'number' ? st.transition * 100 : 700;
    this.onPalette({ pal: seg.pal, cols, transitionMs });
  }
}
