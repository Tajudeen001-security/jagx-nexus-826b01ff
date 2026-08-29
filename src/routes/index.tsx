import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { MessageSquare } from "lucide-react";
import logo from "@/assets/jagx-logo.png";
import { Console } from "@/components/jagx/Console";
import { Sidebar } from "@/components/jagx/Sidebar";
import type { GradeId } from "@/lib/grades";
import type { Msg, ChatSession } from "@/lib/types";
import { listSessions, saveSession, newSessionId, titleFromMessages } from "@/lib/history";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "JagX AI 1.1.2 — Intelligence Console, Terminal & Live Web" },
      {
        name: "description",
        content:
          "JagX AI 1.1.2: thirteen intelligence modes, an embedded coding terminal, live web retrieval and sandboxed execution. Built by JagX & JRILICENSE.",
      },
      { property: "og:title", content: "JagX AI 1.1.2 — Intelligence Console" },
      {
        property: "og:description",
        content: "Thirteen intelligence modes, embedded terminal, live web retrieval and sandboxed execution.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Home,
});

const TABS = [{ id: "console", label: "Ask", icon: MessageSquare }] as const;

function Home() {
  const [tab] = useState<(typeof TABS)[number]["id"]>("console");
  const [grade, setGrade] = useState<GradeId>("core");
  const [sessionId, setSessionId] = useState<string>(() => newSessionId());
  const [messages, setMessages] = useState<Msg[]>([]);

  useEffect(() => {
    if (messages.length === 0) return;
    const session: ChatSession = {
      id: sessionId,
      title: titleFromMessages(messages),
      messages,
      grade,
      updatedAt: Date.now(),
    };
    saveSession(session);
  }, [messages, sessionId, grade]);

  function handleNewChat() {
    setSessionId(newSessionId());
    setMessages([]);
    setTab("console");
  }

  function handleSelectSession(id: string) {
    const found = listSessions().find((s) => s.id === id);
    if (!found) return;
    setSessionId(found.id);
    setMessages(found.messages);
    setGrade(found.grade as GradeId);
    setTab("console");
  }

  return (
    <div className="flex h-dvh flex-col overflow-hidden">
      <div className="pointer-events-none absolute inset-x-0 top-0 h-72 grid-field" aria-hidden />

      <header className="relative z-10 flex items-center justify-between gap-3 border-b border-border px-3 py-3 sm:px-8">
        <div className="flex items-center gap-2">
          <Sidebar currentSessionId={sessionId} onSelectSession={handleSelectSession} onNewChat={handleNewChat} />
          <div className="flex items-center gap-2.5">
            <img src={logo} alt="JagX AI logo" width={28} height={28} className="size-7" />
            <div className="leading-tight">
              <h1 className="font-display text-sm font-semibold tracking-tight">
                JagX <span className="text-brand">AI</span>
              </h1>
              <p className="font-mono text-[9px] uppercase tracking-[0.28em] text-muted-foreground">
                v1.1.2 · unlimited
              </p>
            </div>
          </div>
        </div>

        <nav className="flex items-center gap-1 rounded-full border border-border p-1">
          {TABS.map((t) => (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              className={`flex items-center gap-1.5 rounded-full px-3 py-1.5 font-mono text-[11px] transition-colors ${
                tab === t.id ? "bg-primary/15 text-primary" : "text-muted-foreground hover:text-foreground"
              }`}
            >
              <t.icon className="size-3.5" />
              <span className="hidden sm:inline">{t.label}</span>
            </button>
          ))}
        </nav>

        <div className="hidden items-center gap-2 font-mono text-[10px] text-muted-foreground md:flex">
          <span className="size-1.5 rounded-full bg-signal live-dot" />
          core online
        </div>
      </header>

      <main className="relative z-10 min-h-0 flex-1 overflow-hidden">
        {tab === "console" && (
          <Console grade={grade} onGrade={setGrade} messages={messages} setMessages={setMessages} />
        )}

      </main>
    </div>
  );
}
