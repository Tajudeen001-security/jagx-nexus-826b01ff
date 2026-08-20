// src/lib/ai.server.ts

const JAGX_BASE = process.env["JAGX_BASE_URL"] || "https://jagx-ai-v2.onrender.com";

function getJagxKey(): string {
  const key = process.env["JAGX_API_KEY"];
  if (!key) {
    throw new Error(
      "JAGX_API_KEY is missing. Please add it in your Vercel Environment Variables."
    );
  }
  return key.trim();
}

type Att = {
  name: string;
  mime: string;
  dataUrl: string;
};

/**
 * Analyze uploaded images / files using JagX backend
 * Note: Full vision (seeing the image) is limited until we add vision support to the backend.
 */
export async function analyzeAttachments(opts: {
  prompt: string;
  attachments: Att[];
}): Promise<{ text: string }> {
  const key = getJagxKey();

  // Prepare information about the uploaded files
  const fileInfo = opts.attachments
    .map((file, index) => {
      return `File ${index + 1}: \( {file.name} ( \){file.mime})`;
    })
    .join("\n");

  const message = `The user uploaded the following file(s):\n${fileInfo}\n\nUser question: ${opts.prompt}\n\nPlease respond helpfully. If you cannot see the actual image content, politely explain that full image understanding is still being improved on JagX AI.`;

  try {
    const res = await fetch(`${JAGX_BASE}/chat`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": key,
      },
      body: JSON.stringify({
        message,
        max_tokens: 1000,
      }),
    });

    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`JagX API error: ${res.status} - ${errorText}`);
    }

    const data = await res.json();

    return {
      text:
        data.response ||
        "I received your file, but I couldn't generate a proper response.",
    };
  } catch (error: any) {
    return {
      text: `I received your file, but there was a problem analyzing it: ${error.message}`,
    };
  }
}

/**
 * Generate an image using JagX backend (/image endpoint)
 */
export async function generateImage(
  prompt: string
): Promise<{ dataUrl: string }> {
  const key = getJagxKey();

  const res = await fetch(`${JAGX_BASE}/image`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": key,
    },
    body: JSON.stringify({
      prompt,
      width: 1024,
      height: 1024,
    }),
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`Image generation failed: ${errorText}`);
  }

  const data = await res.json();

  if (data.image_base64) {
    return {
      dataUrl: `data:image/png;base64,${data.image_base64}`,
    };
  }

  throw new Error("No image returned from JagX backend");
}