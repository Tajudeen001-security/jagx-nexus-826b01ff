const KEY = "jagx.vfs.v1";

type Files = Record<string, string>;

function load(): Files {
  if (typeof window === "undefined") return {};
  try {
    return JSON.parse(localStorage.getItem(KEY) || "{}") as Files;
  } catch {
    return {};
  }
}

function save(f: Files) {
  if (typeof window !== "undefined") localStorage.setItem(KEY, JSON.stringify(f));
}

export const vfs = {
  list(): string[] {
    return Object.keys(load()).sort();
  },
  read(path: string): string | null {
    return load()[path] ?? null;
  },
  write(path: string, content: string) {
    const f = load();
    f[path] = content;
    save(f);
  },
  remove(path: string) {
    const f = load();
    delete f[path];
    save(f);
  },
  clear() {
    save({});
  },
  bundle(paths?: string[]): string {
    const f = load();
    return (paths ?? Object.keys(f))
      .filter((p) => f[p] !== undefined)
      .map((p) => `--- ${p} ---\n${f[p]}`)
      .join("\n\n");
  },
};
