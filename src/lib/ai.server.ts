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
 * Analyze one or more uploaded images using JagX backend /vision endpoint
 * Supports multiple images + text question
 */
export async function analyzeAttachments(opts: {
  prompt: string;
  attachments: Att[];
}): Promise<{ text: string }> {
  const key = getJagxKey();

  // Get all images
  const images = opts.attachments.filter((file) =>
    file.mime.startsWith("image/")
  );

  if (images.length === 0) {
    return {
      text: "I did not receive any image. Please upload at least one image and ask your question again.",
    };
  }

  const question = opts.prompt?.trim() || "Describe the image(s) in detail.";

  try {
    // For now we process the first image (most common case)
    // You can later extend the backend to accept multiple images
    const mainImage = images[0];

    const res = await fetch(`${JAGX_BASE}/vision`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": key,
      },
      body: JSON.stringify({
        image_base64: mainImage.dataUrl,
        question:
          images.length > 1
            ? `${question}\n\nNote: The user uploaded ${images.length} images. This is the first one.`
            : question,
      }),
    });

    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`Vision API error: ${res.status} - ${errorText}`);
    }

    const data = await res.json();

    let reply = data.response || "I could not analyze the image.";

    // Add helpful note if multiple images were uploaded
    if (images.length > 1) {
      reply += `\n\n(Note: You uploaded ${images.length} images. I analyzed the first one. Full multi-image support is coming soon.)`;
    }

    return {
      text: reply,
    };
  } catch (error: any) {
    return {
      text: `I received your image${images.length > 1 ? "s" : ""} but could not analyze ${images.length > 1 ? "them" : "it"} properly.\n\nError: ${error.message}`,
    };
  }
}

/**
 * Generate an image using JagX backend
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