import { useState } from "react";
import { runCode, RunCodeResult } from "@/lib/code-runner";
import HtmlPreview from "@/components/HtmlPreview";

interface CodeBlockProps {
  code: string;
  language: string;
}

export default function CodeBlock({ code, language }: CodeBlockProps) {
  const [isRunning, setIsRunning] = useState(false);
  const [result, setResult] = useState<RunCodeResult | null>(null);
  const [showPreview, setShowPreview] = useState(false);

  const handleRun = async () => {
    setIsRunning(true);
    setResult(null);
    setShowPreview(false);

    const res = await runCode(code, language || "javascript");
    setResult(res);

    if (res.language === "html" && res.success) {
      setShowPreview(true);
    }

    setIsRunning(false);
  };

  return (
    <div className="my-4 rounded-xl overflow-hidden border border-zinc-700 bg-zinc-900">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2 bg-zinc-800 text-sm">
        <span className="text-zinc-300 font-medium uppercase">
          {language || "code"}
        </span>

        <button
          onClick={handleRun}
          disabled={isRunning}
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-medium transition disabled:opacity-50"
        >
          {isRunning ? "Running..." : "▶ Run"}
        </button>
      </div>

      {/* Code */}
      <pre className="p-4 overflow-x-auto text-sm text-zinc-200">
        <code>{code}</code>
      </pre>

      {/* Result / Preview */}
      {result && (
        <div className="border-t border-zinc-700">
          {showPreview && result.success ? (
            <HtmlPreview code={result.output} height="350px" />
          ) : (
            <div className="p-4">
              <div className="text-xs text-zinc-400 mb-2">Output</div>
              <pre
                className={`text-sm whitespace-pre-wrap ${
                  result.success ? "text-emerald-300" : "text-red-400"
                }`}
              >
                {result.error || result.output || "No output"}
              </pre>
            </div>
          )}
        </div>
      )}
    </div>
  );
}