import { useEffect, useState, type MouseEvent } from "react";
import { Menu, MessageSquarePlus, MessageSquare, Trash2, Settings as SettingsIcon } from "lucide-react";
import { Sheet, SheetTrigger, SheetContent, SheetHeader, SheetTitle, SheetClose } from "@/components/ui/sheet";
import { listSessions, deleteSession } from "@/lib/history";
import type { ChatSession } from "@/lib/types";
import { Settings } from "./Settings";

export function Sidebar({
  currentSessionId,
  onSelectSession,
  onNewChat,
}: {
  currentSessionId: string | null;
  onSelectSession: (id: string) => void;
  onNewChat: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [sessions, setSessions] = useState<ChatSession[]>([]);

  useEffect(() => {
    if (open) setSessions(listSessions());
  }, [open]);

  function remove(id: string, e: MouseEvent) {
    e.stopPropagation();
    deleteSession(id);
    setSessions(listSessions());
  }

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <button title="Chat history" className="flex size-8 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-surface-2 hover:text-foreground">
          <Menu className="size-4.5" />
        </button>
      </SheetTrigger>
      <SheetContent side="left" className="flex w-[85vw] max-w-xs flex-col p-0 sm:max-w-sm">
        <SheetHeader className="border-b border-border px-4 py-3 text-left">
          <SheetTitle className="font-display text-sm">JagX AI</SheetTitle>
        </SheetHeader>

        <div className="p-3">
          <SheetClose asChild>
            <button
              onClick={onNewChat}
              className="flex w-full items-center gap-2 rounded-xl border border-border px-3 py-2.5 text-sm text-foreground transition-colors hover:bg-surface-2"
            >
              <MessageSquarePlus className="size-4 text-primary" />
              New chat
            </button>
          </SheetClose>
        </div>

        <div className="flex-1 overflow-y-auto px-2 pb-2">
          {sessions.length === 0 && (
            <p className="px-3 py-4 text-xs text-muted-foreground">No saved chats yet — conversations save here automatically.</p>
          )}
          <div className="space-y-0.5">
            {sessions.map((s) => (
              <SheetClose asChild key={s.id}>
                <button
                  onClick={() => onSelectSession(s.id)}
                  className={`group flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm transition-colors ${
                    s.id === currentSessionId ? "bg-surface-2 text-foreground" : "text-muted-foreground hover:bg-surface-2 hover:text-foreground"
                  }`}
                >
                  <MessageSquare className="size-3.5 shrink-0" />
                  <span className="flex-1 truncate">{s.title}</span>
                  <span onClick={(e) => remove(s.id, e)} className="hidden shrink-0 rounded p-1 hover:text-destructive group-hover:block">
                    <Trash2 className="size-3.5" />
                  </span>
                </button>
              </SheetClose>
            ))}
          </div>
        </div>

        <div className="border-t border-border p-3">
          <Settings
            trigger={
              <button className="flex w-full items-center gap-2 rounded-xl px-3 py-2.5 text-sm text-muted-foreground transition-colors hover:bg-surface-2 hover:text-foreground">
                <SettingsIcon className="size-4" />
                Settings
              </button>
            }
          />
        </div>
      </SheetContent>
    </Sheet>
  );
}