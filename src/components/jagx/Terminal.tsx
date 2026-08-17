import { useEffect, useRef, useState } from "react";
import { useServerFn } from "@tanstack/react-start";
import { sendToJagx, getJagxStatus, webSearch } from "@/lib/jagx.functions";

type Line = { kind: "in" | "out" | "err" | "sys"; text: string };

const HELP = `JagX Shell 4.2 — available commands

  help                 show this list
  clear                clear the buffer
  status               ping the JagX core
  whoami               session + runtime identity
  grades               list intelligence grades
  ask <prompt>         query JagX AI (Core)
  code <prompt>        query JagX AI (Engineer)
  ops <prompt>         query JagX AI (Operator)
  search <query>       live web search
  js <expression>      evaluate JS in this sandbox
  sys                  local device telemetry
  geo                  request geolocation (asks permission)
  time                 local + UTC clock`;

export function Terminal() {
  const chat = useServerFn(sendToJagx);
  const status = useServerFn(getJagxStatus);
  const search = useServerFn(webSearch);
  const [lines, setLines] = useState<Line[]>([
    { kind: "sys", text: "JagX Shell 4.2 — type `help` to begin." },
  ]);
  const [value, setValue] = useState("");
  const [hist, setHist] = useState<string[]>([]);
  const [hi, setHi] = useState(-1);
  const [busy, setBusy] = useState(false);
  const endRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [lines, busy]);

  const push = (l: Line) => setLines((p) => [...p, l]);

  async function run(raw: string) {
    const cmd = raw.trim();
    if (!cmd) return;
    push({ kind: "in", text: cmd });
    setHist((h) => [cmd, ...h]);
    setHi(-1);
    const [name, ...rest] = cmd.split(" ");
    const arg = rest.join(" ");
    setBusy(true);
    try {
      switch (name) {
        case "help":
          push({ kind: "out", text: HELP });
          break;
        case "clear":
          setLines([]);
          break;
        case "status": {
          const s = await status({});
          push({ kind: "out", text: JSON.stringify(s, null, 2) });
          break;
        }
        case "whoami":
          push({
            kind: "out",
            text: `operator@jagx\nagent: JagX AI 4.2 (JagX & JRILICENSE)\nruntime: ${navigator.userAgent}`,
          });
          break;
        case "grades":
          push({
            kind: "out",
            text: "core · engineer · researcher · architect · creator · operator",
          });
          break;
        case "time":
          push({
            kind: "out",
            text: `local: ${new Date().toString()}\nutc:   ${new Date().toISOString()}`,
          });
          break;
        case "sys":
          push({
            kind: "out",
            text: JSON.stringify(
              {
                platform: navigator.platform,
                languages: navigator.languages,
                cores: navigator.hardwareConcurrency,
                memoryGB: (navigator as unknown as { deviceMemory?: number }).deviceMemory ?? "n/a",
                online: navigator.onLine,
                screen: `${screen.width}x${screen.height}@${devicePixelRatio}x`,
                timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
              },
              null,
              2,
            ),
          });
          break;
        case "geo": {
          const pos = await new Promise<GeolocationPosition>((res, rej) =>
            navigator.geolocation.getCurrentPosition(res, rej, { timeout: 15000 }),
          );
          push({
            kind: "out",
            text: `lat ${pos.coords.latitude.toFixed(5)}, lon ${pos.coords.longitude.toFixed(5)} (±${Math.round(pos.coords.accuracy)}m)`,
          });
          break;
        }
        case "js": {
          // eslint-disable-next-line no-new-func
          const out = new Function(`return (${arg})`)();
          push({ kind: "out", text: typeof out === "object" ? JSON.stringify(out, null, 2) : String(out) });
          break;
        }
        case "search": {
          if (!arg) throw new Error("usage: search <query>");
          const { results } = await search({ data: { query: arg } });
          push({
            kind: "out",
            text: results.length
              ? results.map((r, i) => `[${i + 1}] ${r.title}\n    ${r.url}\n    ${r.snippet}`).join("\n\n")
              : "no results",
          });
          break;
        }
        case "ask":
        case "code":
        case "ops": {
          if (!arg) throw new Error(`usage: ${name} <prompt>`);
          const grade = name === "code" ? "engineer" : name === "ops" ? "operator" : "core";
          const res = await chat({ data: { message: arg, history: [], grade, web: false } });
          push({ kind: "out", text: res.response });
          break;
        }
        default:
          push({ kind: "err", text: `command not found: ${name} — try \`help\`` });
      }
    } catch (e) {
      push({ kind: "err", text: e instanceof Error ? e.message : String(e) });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div
      onClick={() => inputRef.current?.focus()}
      className="mx-auto flex h-full w-full max-w-4xl flex-col px-4 py-6 sm:px-8"
    >
      <div className="panel flex min-h-0 flex-1 flex-col overflow-hidden">
        <div className="flex items-center gap-2 border-b border-border px-4 py-2">
          <span className="size-2.5 rounded-full bg-destructive/70" />
          <span className="size-2.5 rounded-full bg-warn/70" />
          <span className="size-2.5 rounded-full bg-signal/70" />
          <span className="ml-2 font-mono text-[11px] text-muted-foreground">jagx-shell — /workspace</span>
        </div>
        <div className="flex-1 overflow-y-auto p-4 font-mono text-[12.5px] leading-relaxed">
          {lines.map((l, i) => (
            <pre
              key={i}
              className={`whitespace-pre-wrap break-words ${
                l.kind === "in"
                  ? "text-foreground"
                  : l.kind === "err"
                    ? "text-destructive"
                    : l.kind === "sys"
                      ? "text-signal"
                      : "text-muted-foreground"
              }`}
            >
              {l.kind === "in" ? `❯ ${l.text}` : l.text}
            </pre>
          ))}
          {busy && <pre className="text-primary">executing…</pre>}
          <div className="mt-1 flex items-center gap-2">
            <span className="text-primary">❯</span>
            <input
              ref={inputRef}
              value={value}
              onChange={(e) => setValue(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  run(value);
                  setValue("");
                } else if (e.key === "ArrowUp") {
                  e.preventDefault();
                  const n = Math.min(hi + 1, hist.length - 1);
                  if (n >= 0) {
                    setHi(n);
                    setValue(hist[n]);
                  }
                } else if (e.key === "ArrowDown") {
                  e.preventDefault();
                  const n = hi - 1;
                  setHi(n);
                  setValue(n >= 0 ? hist[n] : "");
                }
              }}
              spellCheck={false}
              autoComplete="off"
              className="flex-1 bg-transparent font-mono text-[12.5px] outline-none"
            />
          </div>
          <div ref={endRef} />
        </div>
      </div>
    </div>
  );
}
