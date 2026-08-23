import type { ChatSession, Msg } from "./types";

const KEY = "jagx.sessions.v1";
const MAX_SESSIONS = 50;

function readAll(): ChatSession[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = window.localStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as ChatSession[]) : [];
  } catch {
    return [];
  }
}

function writeAll(sessions: ChatSession[]) {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(KEY, JSON.stringify(sessions.slice(0, MAX_SESSIONS)));
  } catch {
    // storage full or unavailable — chat still works for this session, it just won't persist
  }
}

export function listSessions(): ChatSession[] {
  return readAll().sort((a, b) => b.updatedAt - a.updatedAt);
}

export function saveSession(session: ChatSession) {
  const all = readAll();
  const idx = all.findIndex((s) => s.id === session.id);
  if (idx >= 0) all[idx] = session;
  else all.unshift(session);
  writeAll(all);
}

export function deleteSession(id: string) {
  writeAll(readAll().filter((s) => s.id !== id));
}

export function newSessionId(): string {
  return `s_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

export function titleFromMessages(messages: Msg[]): string {
  const firstUser = messages.find((m) => m.role === "user" && m.content.trim());
  if (!firstUser) return "New chat";
  const text = firstUser.content.trim();
  return text.length > 48 ? `${text.slice(0, 48)}…` : text;
}