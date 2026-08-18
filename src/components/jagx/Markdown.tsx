import { useState } from "react";
import { Check, Copy, Play } from "lucide-react";
import { markProse } from "@/lib/watermark";
import { runInSandbox, formatSandbox } from "@/lib/sandbox";

const RUNNABLE = ["js", "javascript", "ts", "typescript", "jsx", "tsx", "node"];

function CodeBlock({ lang, code }: { lang: string; code: string }) {
  const [copied, setCopied] = useState(false);
  const [out, setOut] = useState<string | null>(null);
  const [running, setRunning] = useState(false);
  const runnable = RUNNABLE.includes(lang.toLowerCase());
  return (
    <div className="my-3 overflow-hidden rounded-lg border border-border bg-background/70">
      <div className="flex items-center justify-between border-b border-border px-3 py-1.5">
        <span className="font-mono text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
          {lang || "code"}
        </span>
        <div className="flex items-center gap-1">
        {runnable && (
          <button
            type="button"
            onClick={async () => {
              setRunning(true);
              setOut(formatSandbox(await runInSandbox(code)));
              setRunning(false);
            }}
            className="flex items-center gap-1 rounded px-1.5 py-0.5 font-mono text-[10px] text-muted-foreground transition-colors hover:text-signal"
          >
            <Play className="size-3" />
            {running ? "running" : "run"}
          </button>
        )}
        <button
          type="button"
          onClick={() => {
            navigator.clipboard?.writeText(code);
            setCopied(true);
            setTimeout(() => setCopied(false), 1400);
          }}
          className="flex items-center gap-1 rounded px-1.5 py-0.5 font-mono text-[10px] text-muted-foreground transition-colors hover:text-primary"
        >
          {copied ? <Check className="size-3" /> : <Copy className="size-3" />}
          {copied ? "copied" : "copy"}
        </button>
        </div>
      </div>
      <pre className="overflow-x-auto p-3 font-mono text-[12.5px] leading-relaxed">
        <code data-jagx="1">{code}</code>
      </pre>
      {out !== null && (
        <pre className="overflow-x-auto border-t border-border bg-surface-2/40 p-3 font-mono text-[11.5px] leading-relaxed text-muted-foreground">
          {out}
        </pre>
      )}
    </div>
  );
}

function inline(text: string, key: number) {
  const parts = text.split(/(`[^`]+`|\*\*[^*]+\*\*)/g).filter(Boolean);
  return (
    <p key={key} className="whitespace-pre-wrap text-[14px] leading-relaxed">
      {parts.map((p, i) => {
        if (p.startsWith("`") && p.endsWith("`"))
          return (
            <code key={i} className="rounded bg-surface-2 px-1 py-0.5 font-mono text-[12.5px] text-primary">
              {p.slice(1, -1)}
            </code>
          );
        if (p.startsWith("**") && p.endsWith("**"))
          return (
            <strong key={i} className="font-semibold text-foreground">
              {p.slice(2, -2)}
            </strong>
          );
        return <span key={i}>{markProse(p)}</span>;
      })}
    </p>
  );
}

export function Markdown({ content }: { content: string }) {
  const segments = content.split(/```/);
  return (
    <div className="space-y-1">
      {segments.map((seg, i) => {
        if (i % 2 === 1) {
          const nl = seg.indexOf("\n");
          const lang = nl > -1 ? seg.slice(0, nl).trim() : "";
          const code = nl > -1 ? seg.slice(nl + 1) : seg;
          return <CodeBlock key={i} lang={lang} code={code.replace(/\n$/, "")} />;
        }
        return (
          <div key={i} className="space-y-2">
            {seg
              .split(/\n{2,}/)
              .filter((b) => b.trim())
              .map((b, j) => inline(b.trim(), j))}
          </div>
        );
      })}
    </div>
  );
}
