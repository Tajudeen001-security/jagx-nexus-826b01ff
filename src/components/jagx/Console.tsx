import { useEffect, useRef, useState } from "react";
import { useServerFn } from "@tanstack/react-start";
import { ArrowUp, Globe, Link2, Loader2, Square } from "lucide-react";
import { sendToJagx } from "@/lib/jagx.functions";
import { GRADE_LIST, type GradeId } from "@/lib/grades";
import { Markdown } from "./Markdown";

type Source = { title: string; url: string; snippet: string };
type Msg = { role: "user" | "assistant"; content: string; sources?: Source[]; error?: boolean };

const SUGGESTIONS = [
  "Design a fault-tolerant job queue in Postgres",
  "Write a TypeScript rate limiter with tests",
  "What shipped in AI infrastructure this week?",
  "Refactor this API for 10x traffic",
];

export function Console({ grade, onGrade }: { grade: GradeId; onGrade: (g: GradeId) => void }) {
  const chat = useServerFn(sendToJagx);
  const [messages, setMessages] = useState<Msg[]>([]);
  const [input, setInput] = useState("");
  const [web, setWeb] = useState(false);
  const [busy, setBusy] = useState(false);
  const [quota, setQuota] = useState("");
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, busy]);

  async function submit(text: string) {
    const message = text.trim();
    if (!message || busy) return;
    const history = messages
      .filter((m) => !m.error)
      .map((m) => ({ role: m.role, content: m.content }));
    setMessages((m) => [...m, { role: "user", content: message }]);
    setInput("");
    setBusy(true);
    try {
      const res = await chat({ data: { message, history, grade, web } });
      setQuota(res.quota ?? "");
      setMessages((m) => [
        ...m,
        { role: "assistant", content: res.response || "(empty response)", sources: res.sources },
      ]);
    } catch (e) {
      setMessages((m) => [
        ...m,
        { role: "assistant", content: e instanceof Error ? e.message : "Request failed", error: true },
      ]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex h-full flex-col">
      <div className="flex-1 overflow-y-auto px-4 py-6 sm:px-8">
        <div className="mx-auto w-full max-w-3xl space-y-6">
          {messages.length === 0 && (
            <div className="space-y-6 pt-4">
              <div>
                <h2 className="font-display text-2xl font-semibold tracking-tight sm:text-3xl">
                  Ask <span className="text-brand">JagX AI</span> anything.
                </h2>
                <p className="mt-2 text-sm text-muted-foreground">
                  Six intelligence grades, live web retrieval, an embedded terminal and permissioned
                  device access.
                </p>
              </div>
              <div className="grid gap-2 sm:grid-cols-2">
                {SUGGESTIONS.map((s) => (
                  <button
                    key={s}
                    onClick={() => submit(s)}
                    className="panel px-4 py-3 text-left text-sm text-muted-foreground transition-colors hover:border-primary/50 hover:text-foreground"
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map((m, i) =>
            m.role === "user" ? (
              <div key={i} className="flex justify-end">
                <div className="max-w-[85%] rounded-2xl rounded-br-sm bg-surface-2 px-4 py-2.5 text-sm">
                  {m.content}
                </div>
              </div>
            ) : (
              <div key={i} className="space-y-3">
                <div className="flex items-center gap-2 font-mono text-[10px] uppercase tracking-[0.25em] text-primary">
                  <span className="size-1.5 rounded-full bg-primary" />
                  JagX AI · {grade}
                </div>
                <div className={m.error ? "text-sm text-destructive" : ""}>
                  {m.error ? m.content : <Markdown content={m.content} />}
                </div>
                {m.sources && m.sources.length > 0 && (
                  <div className="flex flex-wrap gap-2 pt-1">
                    {m.sources.map((s, j) => (
                      <a
                        key={j}
                        href={s.url}
                        target="_blank"
                        rel="noreferrer noopener"
                        className="flex items-center gap-1.5 rounded-full border border-border px-2.5 py-1 font-mono text-[10px] text-muted-foreground transition-colors hover:border-primary/60 hover:text-primary"
                      >
                        <Link2 className="size-3" />
                        {new URL(s.url || "https://x.com").hostname.replace("www.", "")}
                      </a>
                    ))}
                  </div>
                )}
              </div>
            ),
          )}

          {busy && (
            <div className="flex items-center gap-2 font-mono text-xs text-muted-foreground">
              <Loader2 className="size-3.5 animate-spin text-primary" />
              {web ? "retrieving live sources · reasoning" : "reasoning"}
              <span className="caret">_</span>
            </div>
          )}
          <div ref={endRef} />
        </div>
      </div>

      <div className="border-t border-border bg-background/70 px-4 py-4 backdrop-blur sm:px-8">
        <div className="mx-auto w-full max-w-3xl space-y-2">
          <div className="flex gap-2 overflow-x-auto pb-1">
            {GRADE_LIST.map((g) => (
              <button
                key={g.id}
                onClick={() => onGrade(g.id)}
                title={g.blurb}
                className={`flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-1.5 font-mono text-[11px] transition-colors ${
                  grade === g.id
                    ? "border-primary/60 bg-primary/10 text-primary"
                    : "border-border text-muted-foreground hover:text-foreground"
                }`}
              >
                <g.icon className="size-3.5" />
                {g.label}
              </button>
            ))}
          </div>

          <div className="panel flex items-end gap-2 p-2">
            <textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  submit(input);
                }
              }}
              rows={1}
              placeholder="Message JagX AI…"
              className="max-h-40 min-h-10 flex-1 resize-none bg-transparent px-2 py-2 text-sm outline-none placeholder:text-muted-foreground"
            />
            <button
              onClick={() => setWeb((v) => !v)}
              title="Live web retrieval"
              className={`flex size-9 items-center justify-center rounded-lg border transition-colors ${
                web ? "border-signal/60 bg-signal/15 text-signal" : "border-border text-muted-foreground"
              }`}
            >
              <Globe className="size-4" />
            </button>
            <button
              onClick={() => submit(input)}
              disabled={busy || !input.trim()}
              className="flex size-9 items-center justify-center rounded-lg bg-primary text-primary-foreground transition-opacity disabled:opacity-40"
            >
              {busy ? <Square className="size-3.5" /> : <ArrowUp className="size-4" />}
            </button>
          </div>
          <p className="font-mono text-[10px] text-muted-foreground">
            {quota ? `${quota} · ` : ""}JagX AI 4.2 · responses carry an invisible watermark
          </p>
        </div>
      </div>
    </div>
  );
}
