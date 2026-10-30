// Init script for boot2013.mjs --script: taps what reaches the speakers.
// Every audio node connected to an AudioContext's destination is also
// connected to an analyser; window.__audio() returns the context state and
// the loudness (RMS, 0–1) of what is playing now.
(() => {
  const taps = new Map();
  const connect = AudioNode.prototype.connect;
  AudioNode.prototype.connect = function (target, ...rest) {
    const r = connect.call(this, target, ...rest);
    try {
      if (target instanceof AudioDestinationNode) {
        const ctx = target.context;
        let a = taps.get(ctx);
        if (!a) {
          a = ctx.createAnalyser();
          a.fftSize = 2048;
          taps.set(ctx, a);
        }
        connect.call(this, a);
      }
    } catch {}
    return r;
  };
  window.__audio = () => {
    const out = [];
    for (const [ctx, a] of taps) {
      const buf = new Float32Array(a.fftSize);
      a.getFloatTimeDomainData(buf);
      let s = 0;
      for (const v of buf) s += v * v;
      out.push({ state: ctx.state, rms: Math.sqrt(s / buf.length) });
    }
    return out;
  };
})();
