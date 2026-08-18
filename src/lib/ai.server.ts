const GATEWAY = "https://ai.gateway.lovable.dev/v1";

function key() {
  const k = process.env["LOVABLE_API_KEY"];
  if (!k) throw new Error("AI gateway key is not configured.");
  return k;
}

async function gateway(path: string, body: unknown) {
  const res = await fetch(`${GATEWAY}${path}`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${key()}`,
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    let msg = `AI gateway error ${res.status}`;
    try {
      const j = JSON.parse(text) as { error?: { message?: string }; message?: string };
      msg = j.error?.message || j.message || msg;
    } catch {
      /* keep default */
    }
    if (res.status === 429) msg = "Rate limited — wait a moment and try again.";
    if (res.status === 402) msg = `${msg} (AI credits exhausted — top up in Lovable.)`;
    throw new Error(msg);
  }
  return (await res.json()) as Record<string, unknown>;
}

type Att = { name: string; mime: string; dataUrl: string };

/** Read uploaded files (images, PDFs, text) and answer a question about them. */
export async function analyzeAttachments(opts: {
  prompt: string;
  attachments: Att[];
}): Promise<{ text: string }> {
  const content: unknown[] = [{ type: "text", text: opts.prompt }];
  for (const a of opts.attachments) {
    if (a.mime.startsWith("image/")) {
      content.push({ type: "image_url", image_url: { url: a.dataUrl } });
    } else if (a.mime === "application/pdf") {
      content.push({ type: "file", file: { filename: a.name, file_data: a.dataUrl } });
    } else {
      const b64 = a.dataUrl.split(",")[1] ?? "";
      let text = "";
      try {
        text = atob(b64);
      } catch {
        text = "";
      }
      content.push({ type: "text", text: `--- ${a.name} ---\n${text.slice(0, 60000)}` });
    }
  }

  const j = (await gateway("/chat/completions", {
    model: "google/gemini-3.7-flash",
    messages: [
      {
        role: "system",
        content:
          "You are JagX AI Vision. Read the supplied files precisely. Summarize, extract structure, transcribe code or text verbatim when asked, and be concrete.",
      },
      { role: "user", content },
    ],
  })) as { choices?: Array<{ message?: { content?: string } }> };

  return { text: j.choices?.[0]?.message?.content ?? "" };
}

/** Generate an image, returned as a data URL. */
export async function generateImage(prompt: string): Promise<{ dataUrl: string }> {
  const j = (await gateway("/images/generations", {
    model: "google/gemini-3-pro-image",
    messages: [{ role: "user", content: prompt }],
    modalities: ["image", "text"],
  })) as {
    data?: Array<{ b64_json?: string; url?: string }>;
    choices?: Array<{ message?: { images?: Array<{ image_url?: { url?: string } }> } }>;
  };

  const inline = j.choices?.[0]?.message?.images?.[0]?.image_url?.url;
  if (inline) return { dataUrl: inline };
  const d = j.data?.[0];
  if (d?.b64_json) return { dataUrl: `data:image/png;base64,${d.b64_json}` };
  if (d?.url) return { dataUrl: d.url };
  throw new Error("Image generation returned no image.");
}
