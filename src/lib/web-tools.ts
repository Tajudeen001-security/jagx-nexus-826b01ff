// src/lib/web-tools.ts

export type WebSource = {
  title: string;
  url: string;
  snippet: string;
};

/**
 * Clean HTML entities and tags from text
 */
function cleanText(text: string): string {
  return text
    .replace(/<[^>]*>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Search the web using DuckDuckGo (free)
 */
export async function searchWeb(
  query: string,
  limit: number = 5
): Promise<WebSource[]> {
  const results: WebSource[] = [];

  try {
    const response = await fetch(
      `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`,
      {
        headers: {
          "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
          Accept: "text/html",
        },
      }
    );

    if (!response.ok) return results;

    const html = await response.text();
    const blocks = html.split("result__body").slice(1, limit + 1);

    for (const block of blocks) {
      const anchorMatch = block.match(
        /<a[^>]*class="result__a"[^>]*>([\s\S]*?)<\/a>/
      );
      const hrefMatch = anchorMatch
        ? anchorMatch[0].match(/href="([^"]+)"/)
        : null;
      const snippetMatch = block.match(
        /class="result__snippet"[^>]*>([\s\S]*?)<\/(?:a|td|div)>/
      );

      if (!anchorMatch || !hrefMatch) continue;

      let url = hrefMatch[1];

      // Decode DuckDuckGo redirect
      const uddgMatch = url.match(/uddg=([^&]+)/);
      if (uddgMatch?.[1]) {
        url = decodeURIComponent(uddgMatch[1]);
      }

      if (url.startsWith("//")) {
        url = "https:" + url;
      }

      results.push({
        title: cleanText(anchorMatch[1] || ""),
        url,
        snippet: snippetMatch ? cleanText(snippetMatch[1] || "") : "",
      });
    }
  } catch (error) {
    console.error("searchWeb error:", error);
  }

  return results;
}

/**
 * Read the full readable content of any webpage
 * Uses Jina AI Reader (free)
 */
export async function readFullPage(url: string): Promise<string> {
  try {
    const response = await fetch(`https://r.jina.ai/${url}`, {
      headers: {
        "User-Agent": "JagX-AI/5.0",
        Accept: "text/plain",
      },
    });

    if (!response.ok) return "";

    const text = await response.text();
    return text.slice(0, 15000); // Limit to avoid very large responses
  } catch (error) {
    console.error("readFullPage error:", error);
    return "";
  }
}

/**
 * Get information from a YouTube link
 */
export async function getYoutubeInfo(url: string): Promise<string> {
  try {
    const content = await readFullPage(url);

    if (!content) {
      return "I could not extract detailed information from this YouTube video.";
    }

    return `YouTube Video Information:\n\n${content.slice(0, 4000)}`;
  } catch (error) {
    return "Failed to read the YouTube video.";
  }
}

/**
 * Smart link reader
 * Automatically detects the type of link and extracts useful information
 */
export async function smartReadLink(url: string): Promise<string> {
  if (!url || !url.startsWith("http")) {
    return "Invalid URL provided.";
  }

  const lowerUrl = url.toLowerCase();

  // YouTube
  if (lowerUrl.includes("youtube.com") || lowerUrl.includes("youtu.be")) {
    return await getYoutubeInfo(url);
  }

  // TikTok, Instagram, X/Twitter, Facebook
  if (
    lowerUrl.includes("tiktok.com") ||
    lowerUrl.includes("instagram.com") ||
    lowerUrl.includes("twitter.com") ||
    lowerUrl.includes("x.com") ||
    lowerUrl.includes("facebook.com")
  ) {
    const content = await readFullPage(url);
    if (content) {
      return `Content extracted from link:\n\n${content.slice(0, 4000)}`;
    }
    return "I could not extract content from this social media link.";
  }

  // Normal websites
  const content = await readFullPage(url);

  if (content) {
    return content;
  }

  return "I could not read the content of this page.";
}

/**
 * Combined search + optional deep read of the top result
 */
export async function searchAndRead(
  query: string,
  deepRead: boolean = true
): Promise<{ sources: WebSource[]; fullContent?: string }> {
  const sources = await searchWeb(query, 5);

  let fullContent: string | undefined;

  if (deepRead && sources.length > 0) {
    fullContent = await readFullPage(sources[0].url);
  }

  return {
    sources,
    fullContent,
  };
}