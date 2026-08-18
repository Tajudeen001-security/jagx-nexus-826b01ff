import { runInSandbox, formatSandbox } from "./sandbox";
import { vfs } from "./vfs";

export type AgentStep = { kind: "thought" | "action" | "observation" | "final"; text: string };

type Deps = {
  chat: (args: {
    data: { message: string; history: []; grade: "operator"; web: false; maxTokens?: number };
  }) => Promise<{ response: string }>;
  search: (args: { data: { query: string } }) => Promise<{ results: Array<{ title: string; url: string; snippet: string }> }>;
  open: (args: { data: { url: string } }) => Promise<{ text: string }>;
};

const SYSTEM = `You are JagX AI Operator running inside a real execution loop with tools.
Reply with EXACTLY ONE fenced json block and nothing else:

\`\`\`json
{"thought":"one short line","tool":"js|search|open|write|read|ls|final","args":{...}}
\`\`\`

Tools:
- js      {"code":"..."}          run JavaScript in a sandboxed worker (async allowed, no DOM/network). Use console.log or return a value.
- search  {"query":"..."}         live web search
- open    {"url":"https://..."}   read a web page as text
- write   {"path":"src/x.ts","content":"..."}  write a file into the workspace
- read    {"path":"..."}          read a workspace file
- ls      {}                      list workspace files
- final   {"answer":"..."}        finish, with the full answer for the user

Rules: verify code by running it with js before claiming it works. Keep iterating until the task is genuinely done, then call final.`;

function parseAction(raw: string): { thought?: string; tool: string; args: Record<string, string> } | null {
  const fence = raw.match(/```(?:json)?\s*([\s\S]*?)```/);
  const body = (fence?.[1] ?? raw).trim();
  const start = body.indexOf("{");
  const end = body.lastIndexOf("}");
  if (start < 0 || end < 0) return null;
  try {
    const o = JSON.parse(body.slice(start, end + 1)) as {
      thought?: string;
      tool?: string;
      args?: Record<string, string>;
    };
    if (!o.tool) return null;
    return { thought: o.thought ?? "", tool: o.tool, args: o.args ?? {} };
  } catch {
    return null;
  }
}

export async function runAgent(
  task: string,
  deps: Deps,
  emit: (s: AgentStep) => void,
  maxSteps = 8,
): Promise<void> {
  let transcript = `TASK:\n${task}`;

  for (let i = 0; i < maxSteps; i++) {
    const res = await deps.chat({
      data: {
        message: `${SYSTEM}\n\n${transcript}\n\nNext action:`,
        history: [],
        grade: "operator",
        web: false,
        maxTokens: 2000,
      },
    });
    const action = parseAction(res.response);
    if (!action) {
      emit({ kind: "final", text: res.response.trim() || "(no action returned)" });
      return;
    }
    if (action.thought) emit({ kind: "thought", text: action.thought });

    if (action.tool === "final") {
      emit({ kind: "final", text: action.args["answer"] ?? "(done)" });
      return;
    }

    let observation = "";
    try {
      switch (action.tool) {
        case "js": {
          const code = action.args["code"] ?? "";
          emit({ kind: "action", text: `js\n${code}` });
          observation = formatSandbox(await runInSandbox(code));
          break;
        }
        case "search": {
          const q = action.args["query"] ?? "";
          emit({ kind: "action", text: `search ${q}` });
          const { results } = await deps.search({ data: { query: q } });
          observation = results.map((r, n) => `[${n + 1}] ${r.title}\n${r.url}\n${r.snippet}`).join("\n\n") || "no results";
          break;
        }
        case "open": {
          const url = action.args["url"] ?? "";
          emit({ kind: "action", text: `open ${url}` });
          const { text } = await deps.open({ data: { url } });
          observation = text.slice(0, 4000) || "(empty page)";
          break;
        }
        case "write": {
          const path = action.args["path"] ?? "";
          vfs.write(path, action.args["content"] ?? "");
          emit({ kind: "action", text: `write ${path}` });
          observation = `wrote ${path} (${(action.args["content"] ?? "").length} bytes)`;
          break;
        }
        case "read": {
          const path = action.args["path"] ?? "";
          emit({ kind: "action", text: `read ${path}` });
          observation = vfs.read(path) ?? `no such file: ${path}`;
          break;
        }
        case "ls": {
          emit({ kind: "action", text: "ls" });
          observation = vfs.list().join("\n") || "(workspace empty)";
          break;
        }
        default:
          observation = `unknown tool: ${action.tool}`;
      }
    } catch (e) {
      observation = `tool error: ${e instanceof Error ? e.message : String(e)}`;
    }

    emit({ kind: "observation", text: observation.slice(0, 4000) });
    transcript += `\n\nACTION: ${action.tool} ${JSON.stringify(action.args).slice(0, 1500)}\nOBSERVATION:\n${observation.slice(0, 3000)}`;
  }

  emit({ kind: "final", text: "step limit reached — run `agent` again to continue." });
}
