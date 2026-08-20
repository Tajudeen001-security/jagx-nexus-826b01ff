import { useState } from "react";
import { runCode, RunCodeResult } from "@/lib/code-runner";
import HtmlPreview from "@/components/HtmlPreview";

interface CodeBlockProps {
  code: string;
  language?: string;
}

function detectLanguage(code: string, fallback?: string): string {
  const lang = (fallback || "").toLowerCase().trim();

  if (lang && lang !== "unknown") return lang;

  if (code.includes("def ") || code.includes("import ") && code.includes("print(")) return "python";
  if (code.includes("fn main") || code.includes("let mut")) return "rust";
  if (code.includes("package main") || code.includes("fmt.")) return "go";
  if (code.includes("public class") || code.includes("System.out")) return "java";
  if (code.includes("interface ") || code.includes(": number") || code.includes(": string")) return "typescript";
  if (code.includes("<!DOCTYPE html") || code.includes("<html") || code.includes("<div")) return "html";
  if (code.includes("function ") || code.includes("const ") || code.includes("=>")) return "javascript";

  return "javascript";
}

export default function CodeBlock({ code, language }: CodeBlockProps) {
  const [isRunning, setIsRunning] = useState(false);
  const [result, setResult] = useState<RunCodeResult | null>(null);
  const [showPreview, setShowPreview] = useState(false);

  const detectedLang = detectLanguage(code, language);

  const handleRun = async () => {
    setIsRunning(true);
    setResult(null);
    setShowPreview(false);

    const res = await runCode(code, detectedLang);
    setResult(res);

    if (res.language === "html" && res.success) {
      setShowPreview(true);
    }

    setIsRunning(false);
  };

  return (
    <div className="my-4 rounded-xl overflow-hidden border border-emerald-900/50 bg-[#0b1411]">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2.5 bg-[#0f1c17] border-b border-emerald-900/40">
        <span className="text-emerald-400/90 text-xs font-semibold uppercase tracking-wider">
          {detectedLang}
        </span>

        <button
          onClick={handleRun}
          disabled={isRunning}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white text-xs font-medium transition-all disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isRunning ? (
            <>
              <span className="animate-spin">⟳</span> Running...
            </>
          ) : (
            <>▶ Run</>
          )}
        </button>
      </div>

      {/* Code */}
      <pre className="p-4 overflow-x-auto text-sm text-emerald-50/90 leading-relaxed">
        <code>{code}</code>
      </pre>

      {/* Output / Preview */}
      {result && (
        <div className="border-t border-emerald-900/40">
          {showPreview && result.success ? (
            <HtmlPreview code={result.output} height="350px" />
          ) : (
            <div className="p-4 bg-[#07110e]">
              <div className="text-xs text-emerald-500/80 mb-2 font-medium">
                {result.success ? "Output" : "Error"}
              </div>
              <pre
                className={`text-sm whitespace-pre-wrap font-mono ${
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