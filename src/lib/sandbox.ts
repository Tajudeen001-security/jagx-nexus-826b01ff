export type SandboxResult = { ok: boolean; logs: string[]; result?: string; error?: string; ms: number };

const WORKER_SRC = `
self.onmessage = async (e) => {
  const logs = [];
  const fmt = (v) => {
    try {
      if (typeof v === "string") return v;
      return JSON.stringify(v, (k, x) => (typeof x === "function" ? String(x) : x), 2);
    } catch { return String(v); }
  };
  const cap = (tag) => (...a) => logs.push((tag ? tag + " " : "") + a.map(fmt).join(" "));
  self.console = { log: cap(""), info: cap("[info]"), warn: cap("[warn]"), error: cap("[error]"), debug: cap("[debug]"), table: cap("[table]") };
  const t0 = Date.now();
  try {
    const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
    const fn = new AsyncFunction("\\n" + e.data.code + "\\n");
    const out = await fn();
    self.postMessage({ ok: true, logs, result: out === undefined ? undefined : fmt(out), ms: Date.now() - t0 });
  } catch (err) {
    self.postMessage({ ok: false, logs, error: (err && err.stack) || String(err), ms: Date.now() - t0 });
  }
};
`;

export function runInSandbox(code: string, timeoutMs = 8000): Promise<SandboxResult> {
  return new Promise((resolve) => {
    const url = URL.createObjectURL(new Blob([WORKER_SRC], { type: "text/javascript" }));
    const w = new Worker(url);
    const done = (r: SandboxResult) => {
      clearTimeout(timer);
      w.terminate();
      URL.revokeObjectURL(url);
      resolve(r);
    };
    const timer = setTimeout(
      () => done({ ok: false, logs: [], error: `sandbox timeout after ${timeoutMs}ms`, ms: timeoutMs }),
      timeoutMs,
    );
    w.onmessage = (e) => done(e.data as SandboxResult);
    w.onerror = (e) => done({ ok: false, logs: [], error: e.message, ms: 0 });
    w.postMessage({ code });
  });
}

export function formatSandbox(r: SandboxResult): string {
  const parts: string[] = [];
  if (r.logs.length) parts.push(r.logs.join("\n"));
  if (r.result !== undefined) parts.push(`=> ${r.result}`);
  if (r.error) parts.push(r.error);
  parts.push(`— ${r.ok ? "ok" : "failed"} in ${r.ms}ms`);
  return parts.join("\n");
}
