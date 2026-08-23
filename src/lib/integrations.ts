export type McpServer = { id: string; name: string; url: string };
export type Plugin = { id: string; name: string; enabled: boolean };

const MCP_KEY = "jagx.mcp.v1";
const PLUGIN_KEY = "jagx.plugins.v1";

function read<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;
  try {
    const raw = window.localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function write<T>(key: string, value: T) {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // ignore
  }
}

export function listMcpServers(): McpServer[] {
  return read<McpServer[]>(MCP_KEY, []);
}
export function addMcpServer(name: string, url: string) {
  const servers = listMcpServers();
  servers.push({ id: `mcp_${Date.now()}`, name, url });
  write(MCP_KEY, servers);
}
export function removeMcpServer(id: string) {
  write(MCP_KEY, listMcpServers().filter((s) => s.id !== id));
}

export function listPlugins(): Plugin[] {
  return read<Plugin[]>(PLUGIN_KEY, []);
}
export function addPlugin(name: string) {
  const plugins = listPlugins();
  plugins.push({ id: `pg_${Date.now()}`, name, enabled: true });
  write(PLUGIN_KEY, plugins);
}
export function removePlugin(id: string) {
  write(PLUGIN_KEY, listPlugins().filter((p) => p.id !== id));
}
export function togglePlugin(id: string) {
  write(PLUGIN_KEY, listPlugins().map((p) => (p.id === id ? { ...p, enabled: !p.enabled } : p)));
}