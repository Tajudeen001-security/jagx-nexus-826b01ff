export type ChatTurn = { role: "user" | "assistant"; content: string };

export type Grade =
  | "core"
  | "engineer"
  | "researcher"
  | "architect"
  | "creator"
  | "operator";

export const GRADES: Record<Grade, { label: string; blurb: string; system: string; tokens: number }> = {
  core: {
    label: "Core",
    blurb: "Balanced general intelligence",
    system:
      "Operate as JagX AI Core: precise, direct, high-signal answers with zero filler.",
    tokens: 1200,
  },
  engineer: {
    label: "Engineer",
    blurb: "Deep coding, debugging, refactors",
    system:
      "Operate as JagX AI Engineer: an elite software engineer. Always give complete, runnable code in fenced blocks with the language tag, explain trade-offs briefly, call out edge cases, security issues and complexity. Prefer production-grade patterns over toy examples.",
    tokens: 2400,
  },
  researcher: {
    label: "Researcher",
    blurb: "Evidence-led synthesis with sources",
    system:
      "Operate as JagX AI Researcher: synthesize evidence, separate fact from inference, cite the sources supplied in LIVE WEB CONTEXT by their URL, and state clearly when something is unverified.",
    tokens: 2000,
  },
  architect: {
    label: "Architect",
    blurb: "Systems, infra, scale strategy",
    system:
      "Operate as JagX AI Architect: reason about systems at scale — data models, failure modes, throughput, cost, migration paths. Answer with structured sections and concrete numbers.",
    tokens: 2000,
  },
  creator: {
    label: "Creator",
    blurb: "Writing, naming, narrative, brand",
    system:
      "Operate as JagX AI Creator: sharp, original, distinctive voice. No cliches, no corporate filler. Offer options when useful.",
    tokens: 1600,
  },
  operator: {
    label: "Operator",
    blurb: "Terminal ops, shell, automation",
    system:
      "Operate as JagX AI Operator: a command-line and automation expert. Reply with exact commands, flags and scripts. Warn before anything destructive.",
    tokens: 1400,
  },
};

const BASE = () => process.env["JAGX_BASE_URL"] || "https://jagx-ai-v2.onrender.com";

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
    /* fall through */
  }

  if (out.length === 0) {
    try {
      const r = await fetch(
        `https://api.duckduckgo.com/?q=${encodeURIComponent(query)}&format=json&no_html=1`,
      );
      const j = (await r.json()) as {
        AbstractText?: string;
        AbstractURL?: string;
        Heading?: string;
        RelatedTopics?: Array<{ Text?: string; FirstURL?: string }>;
      };
      if (j.AbstractText) {
        out.push({
          title: j.Heading || query,
          url: j.AbstractURL || "",
          snippet: j.AbstractText,
        });
      }
      for (const t of j.RelatedTopics?.slice(0, limit) ?? []) {
        if (t.Text && t.FirstURL) out.push({ title: t.Text.slice(0, 80), url: t.FirstURL, snippet: t.Text });
      }
    } catch {
      /* ignore */
    }
  }
  return out.slice(0, limit);
}

export async function readPage(url: string): Promise<string> {
  try {
    const r = await fetch(`https://r.jina.ai/${url}`, {
      headers: { "user-agent": "JagX-AI/4.2" },
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
  if (!key) throw new Error("JAGX_API_KEY is not configured.");

  const grade = GRADES[opts.grade] ?? GRADES.core;
  let sources: WebSource[] = [];
  let context = "";

  if (opts.web) {
    sources = await searchWeb(opts.message);
    if (sources.length) {
      const top = await readPage(sources[0]?.url ?? "");
      context =
        "\n\nLIVE WEB CONTEXT (retrieved just now — use it, cite URLs):\n" +
        sources.map((s, i) => `[${i + 1}] ${s.title}\n${s.url}\n${s.snippet}`).join("\n\n") +
        (top ? `\n\nFULL TEXT OF [1]:\n${top}` : "");
    }
  }

  const payload = {
    message: `${grade.system}\n\nUSER REQUEST:\n${opts.message}${context}`,
    max_tokens: opts.maxTokens ?? grade.tokens,
    history: opts.history.slice(-12),
  };

  const res = await fetch(`${BASE()}/chat`, {
    method: "POST",
    headers: { "content-type": "application/json", "x-api-key": key },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    let detail = `JagX API error ${res.status}`;
    try {
      const j = (await res.json()) as { detail?: string };
      if (j.detail) detail = j.detail;
    } catch {
      /* ignore */
    }
    if (res.status === 401) detail = "Invalid or inactive JagX API key. Update JAGX_API_KEY.";
    if (res.status === 429) detail = detail || "Hourly rate limit reached.";
    throw new Error(detail);
  }

  const data = (await res.json()) as { response?: string; model?: string; quota?: string };
  return {
    response: data.response ?? "",
    model: data.model ?? "JagX AI 4.2",
    quota: data.quota ?? "",
    sources,
  };
}

export async function jagxStatus() {
  try {
    const r = await fetch(`${BASE()}/`, { signal: AbortSignal.timeout(20000) });
    const j = (await r.json()) as Record<string, unknown>;
    return { online: true, ...j };
  } catch {
    return { online: false };
  }
}
