// src/lib/code-runner.ts

export type RunCodeResult = {
  success: boolean;
  output: string;
  error?: string;
  language: string;
};

const PISTON_URL = "https://emkc.org/api/v2/piston/execute";

const LANGUAGE_MAP: Record<string, { language: string; version: string }> = {
  python: { language: "python", version: "3.12.0" },
  javascript: { language: "javascript", version: "18.15.0" },
  js: { language: "javascript", version: "18.15.0" },
  typescript: { language: "typescript", version: "5.0.3" },
  ts: { language: "typescript", version: "5.0.3" },
  html: { language: "html", version: "*" },
  css: { language: "css", version: "*" },
  c: { language: "c", version: "10.2.0" },
  cpp: { language: "c++", version: "10.2.0" },
  java: { language: "java", version: "15.0.2" },
  go: { language: "go", version: "1.16.2" },
  php: { language: "php", version: "8.2.3" },
  rust: { language: "rust", version: "1.68.2" },
};

export async function runCode(
  code: string,
  language: string
): Promise<RunCodeResult> {
  const lang = language.toLowerCase().trim();
  const config = LANGUAGE_MAP[lang];

  if (!config) {
    return {
      success: false,
      output: "",
      error: `Language "${language}" is not supported yet.`,
      language,
    };
  }

  // Special case: HTML Preview (no need for Piston)
  if (lang === "html") {
    return {
      success: true,
      output: code, // frontend will render this in iframe
      language: "html",
    };
  }

  try {
    const response = await fetch(PISTON_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        language: config.language,
        version: config.version,
        files: [
          {
            content: code,
          },
        ],
      }),
    });

    const data = await response.json();

    if (data.run) {
      const output = data.run.stdout || data.run.stderr || "No output";
      const isError = !!data.run.stderr && !data.run.stdout;

      return {
        success: !isError,
        output: output.trim(),
        error: isError ? data.run.stderr : undefined,
        language: config.language,
      };
    }

    return {
      success: false,
      output: "",
      error: "Failed to execute code.",
      language,
    };
  } catch (err: any) {
    return {
      success: false,
      output: "",
      error: err.message || "Execution failed",
      language,
    };
  }
}