// src/lib/jagx.server.ts

export type ChatTurn = { role: "user" | "assistant"; content: string };

export type Grade =
  | "core"
  | "engineer"
  | "researcher"
  | "architect"
  | "creator"
  | "operator";

export const GRADES: Record<
  Grade,
  { label: string; blurb: string; system: string; tokens: number }
> = {
  core: {
    label: "Core",
    blurb: "Balanced general intelligence",
    system:
      "You are JagX AI Core. Give clear, helpful, and natural answers. Be friendly and direct.",
    tokens: 1500,
  },
  engineer: {
    label: "Engineer",
    blurb: "Deep coding, debugging, refactors",
    system:
      "You are JagX AI Engineer. You are an expert software engineer. Always provide complete, clean, and runnable code. Explain briefly when needed.",
    tokens: 2400,
  },
  researcher: {
    label: "Researcher",
    blurb: "Evidence-led synthesis with sources",
    system:
      "You are JagX AI Researcher. Provide well-researched answers. Use the live web context when available and cite sources clearly.",
    tokens: 2000,
  },
  architect: {
    label: "Architect",
    blurb: "Systems, infra, scale strategy",
    system:
      "You are JagX AI Architect. Think about systems, scalability, architecture, and best practices. Give structured and practical advice.",
    tokens: 2000,
  },
  creator: {
    label: "Creator",
    blurb: "Writing, naming, narrative, brand",
    system:
      "You are JagX AI Creator. Be creative, original, and clear. Help with writing, naming, branding, and content.",
    tokens: 1600,
  },
  operator: {
    label: "Operator",
    blurb: "Terminal ops, shell, automation",
    system:
      "You are JagX AI Operator. Provide exact commands, scripts, and clear step-by-step instructions for terminals and automation.",
    tokens: 1400,
  },
};

const BASE = () =>
  process.env["JAGX_BASE_URL"] || "https://jagx-ai-v2.onrender.com";

export type WebSource = { title: string; url: string; snippet: string };

function decode(s: string) {
  return s
    .replace(/<[^>]*>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#x27;|&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .trim();
}

export async function searchWeb(query: string, limit = 5): Promise<WebSource[]> {
  const out: WebSource[] = [];

  try {
    const res = await fetch(
      `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`,
      {
        headers: {
          "user-agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36",
          accept: "text/html",
        },
      },
    );

    const html = await res.text();
    const blocks = html.split("result__body").slice(1, limit + 1);

    for (const b of blocks) {
      const anchor = b.match(/<a[^>]*class="result__a"[^>]*>([\s\S]*?)<\/a>/);
      const href = anchor ? anchor[0].match(/href="([^"]+)"/) : null;
      const snip = b.match(/class="result__snippet"[^>]*>([\s\S]*?)<\/a>/);

      if (!anchor || !href) continue;

      let url = decode(href[1] ?? "");
      const uddg = url.match(/uddg=([^&]+)/);
      if (uddg?.[1]) url = decodeURIComponent(uddg[1]);
      if (url.startsWith("//")) url = `https:${url}`;

      out.push({
        title: decode(anchor[1] ?? ""),
        url,
        snippet: snip ? decode(snip[1] ?? "") : "",
      });
    }
  } catch {
    // ignore
  }

  return out.slice(0, limit);
}

export async function readPage(url: string): Promise<string> {
  try {
    const r = await fetch(`https://r.jina.ai/${url}`, {
      headers: { "user-agent": "JagX-AI/5.0" },
    });
    if (!r.ok) return "";
    return (await r.text()).slice(0, 6000);
  } catch {
    return "";
  }
}

export async function jagxChat(opts: {
  message: string;
  history: ChatTurn[];
  grade: Grade;
  web: boolean;
  maxTokens?: number | undefined;
}): Promise<{ response: string; model: string; quota: string; sources: WebSource[] }> {
  const key = process.env["JAGX_API_KEY"];

  if (!key || key.trim() === "") {
    throw new Error(
      "JAGX_API_KEY is missing. Go to Vercel → Settings → Environment Variables and add JAGX_API_KEY, then Redeploy.",
    );
  }

  const grade = GRADES[opts.grade] ?? GRADES.core;
  let sources: WebSource[] = [];
  let extraContext = "";

  if (opts.web) {
    sources = await searchWeb(opts.message);
    if (sources.length) {
      const top = await readPage(sources[0]?.url ?? "");
      extraContext =
        "\n\nLIVE WEB CONTEXT:\n" +
        sources
          .map((s, i) => `[${i + 1}] \( {s.title}\n \){s.url}\n${s.snippet}`)
          .join("\n\n") +
        (top ? `\n\nFULL TEXT OF [1]:\n${top}` : "");
    }
  }

  // ✅ CLEAN MESSAGE (This is the important fix)
  const cleanMessage = opts.message + extraContext;

  const payload = {
    message: cleanMessage,
    max_tokens: opts.maxTokens ?? grade.tokens,
    history: opts.history.slice(-12),
  };

  const res = await fetch(`${BASE()}/chat`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": key.trim(),
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    let detail = `JagX API error ${res.status}`;

    try {
      const j = (await res.json()) as { detail?: string };
      if (j.detail) detail = j.detail;
    } catch {
      // ignore
    }

    if (res.status === 401) {
      detail =
        "Invalid or inactive JagX API key. Check JAGX_API_KEY in Vercel and make sure the key is active.";
    }

    if (res.status === 429) {
      detail = detail || "Hourly rate limit reached. Please wait or upgrade your key.";
    }

    throw new Error(detail);
  }

  const data = (await res.json()) as {
    response?: string;
    model?: string;
    quota?: string;
  };

  return {
    response: data.response ?? "",
    model: data.model ?? "JagX AI 5.0",
    quota: data.quota ?? "",
    sources,
  };
}

export async function jagxStatus() {
  try {
    const r = await fetch(`${BASE()}/`, {
      signal: AbortSignal.timeout(20000),
    });
    const j = (await r.json()) as Record<string, unknown>;
    return { online: true, ...j };
  } catch {
    return { online: false };
  }
}