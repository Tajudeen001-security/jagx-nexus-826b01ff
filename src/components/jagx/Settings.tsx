import { useEffect, useState, type ReactNode } from "react";
import { LogOut, Plug, Puzzle, Info, Plus, Trash2, User } from "lucide-react";
import { Sheet, SheetTrigger, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import {
  listMcpServers, addMcpServer, removeMcpServer,
  listPlugins, addPlugin, removePlugin, togglePlugin,
  type McpServer, type Plugin,
} from "@/lib/integrations";

export function Settings({ trigger }: { trigger: ReactNode }) {
  const [open, setOpen] = useState(false);
  const [servers, setServers] = useState<McpServer[]>([]);
  const [plugins, setPlugins] = useState<Plugin[]>([]);
  const [newServerName, setNewServerName] = useState("");
  const [newServerUrl, setNewServerUrl] = useState("");
  const [newPluginName, setNewPluginName] = useState("");

  useEffect(() => {
    if (open) {
      setServers(listMcpServers());
      setPlugins(listPlugins());
    }
  }, [open]);

  function handleAddServer() {
    if (!newServerName.trim() || !newServerUrl.trim()) return;
    addMcpServer(newServerName.trim(), newServerUrl.trim());
    setServers(listMcpServers());
    setNewServerName("");
    setNewServerUrl("");
  }

  function handleAddPlugin() {
    if (!newPluginName.trim()) return;
    addPlugin(newPluginName.trim());
    setPlugins(listPlugins());
    setNewPluginName("");
  }

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>{trigger}</SheetTrigger>
      <SheetContent side="right" className="flex w-[90vw] max-w-sm flex-col overflow-y-auto p-0">
        <SheetHeader className="border-b border-border px-4 py-3 text-left">
          <SheetTitle className="font-display text-sm">Settings</SheetTitle>
        </SheetHeader>

        <div className="flex-1 space-y-6 px-4 py-4">
          <section>
            <h3 className="mb-2 flex items-center gap-2 font-mono text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
              <User className="size-3.5" /> Account
            </h3>
            <p className="text-xs text-muted-foreground">
              Sign-in isn't set up yet on this build — chats are saved to this device only.
            </p>
            <button disabled className="mt-2 flex items-center gap-2 rounded-lg border border-border px-3 py-2 text-xs text-muted-foreground opacity-50">
              <LogOut className="size-3.5" /> Log out
            </button>
          </section>

          <section>
            <h3 className="mb-2 flex items-center gap-2 font-mono text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
              <Plug className="size-3.5" /> MCP servers
            </h3>
            <div className="space-y-1.5">
              {servers.map((s) => (
                <div key={s.id} className="flex items-center gap-2 rounded-lg border border-border px-2.5 py-2 text-xs">
                  <div className="flex-1 truncate">
                    <div className="font-medium">{s.name}</div>
                    <div className="truncate text-muted-foreground">{s.url}</div>
                  </div>
                  <button onClick={() => { removeMcpServer(s.id); setServers(listMcpServers()); }}>
                    <Trash2 className="size-3.5 text-muted-foreground hover:text-destructive" />
                  </button>
                </div>
              ))}
              {servers.length === 0 && <p className="text-xs text-muted-foreground">No MCP servers added yet.</p>}
            </div>
            <div className="mt-2 space-y-1.5">
              <input
                value={newServerName}
                onChange={(e) => setNewServerName(e.target.value)}
                placeholder="Server name"
                className="w-full rounded-lg border border-border bg-transparent px-2.5 py-1.5 text-xs outline-none placeholder:text-muted-foreground"
              />
              <input
                value={newServerUrl}
                onChange={(e) => setNewServerUrl(e.target.value)}
                placeholder="Server URL"
                className="w-full rounded-lg border border-border bg-transparent px-2.5 py-1.5 text-xs outline-none placeholder:text-muted-foreground"
              />
              <button
                onClick={handleAddServer}
                className="flex w-full items-center justify-center gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-xs text-muted-foreground transition-colors hover:text-foreground"
              >
                <Plus className="size-3.5" /> Add server
              </button>
            </div>
            <p className="mt-1.5 text-[10px] text-muted-foreground">
              Saved here for now — wiring these into live chat calls is next on the backend.
            </p>
          </section>

          <section>
            <h3 className="mb-2 flex items-center gap-2 font-mono text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
              <Puzzle className="size-3.5" /> Plugins
            </h3>
            <div className="space-y-1.5">
              {plugins.map((p) => (
                <div key={p.id} className="flex items-center gap-2 rounded-lg border border-border px-2.5 py-2 text-xs">
                  <span className="flex-1 truncate">{p.name}</span>
                  <button
                    onClick={() => { togglePlugin(p.id); setPlugins(listPlugins()); }}
                    className={`rounded-full px-2 py-0.5 text-[10px] ${p.enabled ? "bg-primary/15 text-primary" : "bg-surface-2 text-muted-foreground"}`}
                  >
                    {p.enabled ? "on" : "off"}
                  </button>
                  <button onClick={() => { removePlugin(p.id); setPlugins(listPlugins()); }}>
                    <Trash2 className="size-3.5 text-muted-foreground hover:text-destructive" />
                  </button>
                </div>
              ))}
              {plugins.length === 0 && <p className="text-xs text-muted-foreground">No plugins added yet.</p>}
            </div>
            <div className="mt-2 flex gap-1.5">
              <input
                value={newPluginName}
                onChange={(e) => setNewPluginName(e.target.value)}
                placeholder="Plugin name"
                className="flex-1 rounded-lg border border-border bg-transparent px-2.5 py-1.5 text-xs outline-none placeholder:text-muted-foreground"
              />
              <button
                onClick={handleAddPlugin}
                className="flex items-center gap-1 rounded-lg border border-border px-2.5 py-1.5 text-xs text-muted-foreground transition-colors hover:text-foreground"
              >
                <Plus className="size-3.5" />
              </button>
            </div>
          </section>

          <section>
            <h3 className="mb-2 flex items-center gap-2 font-mono text-[10px] uppercase tracking-[0.2em] text-muted-foreground">
              <Info className="size-3.5" /> About
            </h3>
            <p className="text-xs text-muted-foreground">JagX AI · Backend v6.7 · Built by JagX & JRILICENSE.</p>
          </section>
        </div>
      </SheetContent>
    </Sheet>
  );
}