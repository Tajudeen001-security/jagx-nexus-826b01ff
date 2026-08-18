import { useEffect, useRef, useState } from "react";
import { useServerFn } from "@tanstack/react-start";
import { ArrowUp, Globe, ImagePlus, Link2, Loader2, Paperclip, Square, X } from "lucide-react";
import { sendToJagx, readAttachments, makeImage } from "@/lib/jagx.functions";
import { GRADE_LIST, type GradeId } from "@/lib/grades";
import { Markdown } from "./Markdown";

type Source = { title: string; url: string; snippet: string };
type Msg = {
  role: "user" | "assistant";
  content: string;
  sources?: Source[];
  error?: boolean;
  image?: string;
  files?: string[];
};
type Att = { name: string; mime: string; dataUrl: string };

const MAX_BYTES = 8 * 1024 * 1024;

function readFile(file: File): Promise<Att> {
  return new Promise((resolve, reject) => {
    const r = new FileReader();
    r.onerror = () => reject(new Error(`could not read ${file.name}`));
    r.onload = () =>
      resolve({ name: file.name, mime: file.type || "text/plain", dataUrl: String(r.result) });
    r.readAsDataURL(file);
  });
}

const SUGGESTIONS = [
  "Design a fault-tolerant job queue in Postgres",
  "Write a TypeScript rate limiter with tests",
  "What shipped in AI infrastructure this week?",
  "Refactor this API for 10x traffic",
];

export function Console({ grade, onGrade }: { grade: GradeId; onGrade: (g: GradeId) => void }) {
  const chat = useServerFn(sendToJagx);
  const analyze = useServerFn(readAttachments);
  const image = useServerFn(makeImage);
  const [messages, setMessages] = useState<Msg[]>([]);
  const [input, setInput] = useState("");
  const [web, setWeb] = useState(false);
  const [busy, setBusy] = useState(false);
  const [quota, setQuota] = useState("");
  const [atts, setAtts] = useState<Att[]>([]);
  const [imgMode, setImgMode] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, busy]);

  async function pick(list: FileList | null) {
    if (!list) return;
    const next: Att[] = [];
    for (const f of Array.from(list).slice(0, 6)) {
      if (f.size > MAX_BYTES) {
        setMessages((m) => [
          ...m,
          { role: "assistant", content: `${f.name} is larger than 8 MB.`, error: true },
        ]);
        continue;
      }
      next.push(await readFile(f));
    }
    setAtts((a) => [...a, ...next].slice(0, 6));
  }

  async function submit(text: string) {
    const message = text.trim();
    if ((!message && atts.length === 0) || busy) return;
    const history = messages
      .filter((m) => !m.error)
      .map((m) => ({ role: m.role, content: m.content }));
    const files = atts;
    setMessages((m) => [
      ...m,
      { role: "user", content: message, files: files.map((f) => f.name) },
    ]);
    setInput("");
    setAtts([]);
    setBusy(true);
    try {
      if (imgMode) {
        const { dataUrl } = await image({ data: { prompt: message } });
        setMessages((m) => [...m, { role: "assistant", content: message, image: dataUrl }]);
        return;
      }

      let augmented = message;
      if (files.length) {
        const { text: digest } = await analyze({
          data: {
            prompt:
              message ||
              "Read these files and give a precise, structured summary plus anything useful for building with them.",
            attachments: files,
          },
        });
        augmented = `${message || "Work with the attached files."}\n\nATTACHED FILES (${files
          .map((f) => f.name)
          .join(", ")}) — extracted content:\n${digest}`;
      }

      const res = await chat({ data: { message: augmented, history, grade, web } });
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
                  {m.files && m.files.length > 0 && (
                    <div className="mb-1 flex flex-wrap gap-1.5 font-mono text-[10px] text-muted-foreground">
                      {m.files.map((f) => (
                        <span key={f} className="rounded border border-border px-1.5 py-0.5">
                          {f}
                        </span>
                      ))}
                    </div>
                  )}
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
                {m.image && (
                  <img
                    src={m.image}
                    alt={m.content}
                    className="max-w-full rounded-xl border border-border"
                  />
                )}
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
              {imgMode ? "rendering image" : web ? "retrieving live sources · reasoning" : "reasoning"}
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

          {atts.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {atts.map((a, i) => (
                <span
                  key={`${a.name}-${i}`}
                  className="flex items-center gap-1.5 rounded-full border border-border px-2.5 py-1 font-mono text-[10px] text-muted-foreground"
                >
                  {a.mime.startsWith("image/") ? (
                    <img src={a.dataUrl} alt="" className="size-4 rounded object-cover" />
                  ) : (
                    <Paperclip className="size-3" />
                  )}
                  {a.name}
                  <button onClick={() => setAtts((p) => p.filter((_, j) => j !== i))}>
                    <X className="size-3 hover:text-destructive" />
                  </button>
                </span>
              ))}
            </div>
          )}

          <div className="panel flex items-end gap-2 p-2">
            <input
              ref={fileRef}
              type="file"
              multiple
              className="hidden"
              onChange={(e) => {
                void pick(e.target.files);
                e.target.value = "";
              }}
            />
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
              placeholder={imgMode ? "Describe an image to generate…" : "Message JagX AI…"}
              className="max-h-40 min-h-10 flex-1 resize-none bg-transparent px-2 py-2 text-sm outline-none placeholder:text-muted-foreground"
            />
            <button
              onClick={() => fileRef.current?.click()}
              title="Attach files or images"
              className="flex size-9 items-center justify-center rounded-lg border border-border text-muted-foreground transition-colors hover:text-foreground"
            >
              <Paperclip className="size-4" />
            </button>
            <button
              onClick={() => setImgMode((v) => !v)}
              title="Image generation"
              className={`flex size-9 items-center justify-center rounded-lg border transition-colors ${
                imgMode ? "border-brand/60 bg-brand/15 text-brand" : "border-border text-muted-foreground"
              }`}
            >
              <ImagePlus className="size-4" />
            </button>
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
              disabled={busy || (!input.trim() && atts.length === 0)}
              className="flex size-9 items-center justify-center rounded-lg bg-primary text-primary-foreground transition-opacity disabled:opacity-40"
            >
              {busy ? <Square className="size-3.5" /> : <ArrowUp className="size-4" />}
            </button>
          </div>
          <p className="font-mono text-[10px] text-muted-foreground">
            {quota ? `${quota} · ` : ""}JagX AI 4.2
          </p>
        </div>
      </div>
    </div>
  );
}
