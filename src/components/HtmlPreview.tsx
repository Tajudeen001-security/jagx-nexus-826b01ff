// src/components/HtmlPreview.tsx
import { useEffect, useRef } from "react";

interface HtmlPreviewProps {
  code: string;
  height?: string;
}

export default function HtmlPreview({ code, height = "400px" }: HtmlPreviewProps) {
  const iframeRef = useRef<HTMLIFrameElement>(null);

  useEffect(() => {
    if (iframeRef.current) {
      const doc = iframeRef.current.contentDocument;
      if (doc) {
        doc.open();
        doc.write(code);
        doc.close();
      }
    }
  }, [code]);

  return (
    <div className="w-full border border-zinc-700 rounded-xl overflow-hidden bg-white">
      <div className="bg-zinc-900 text-zinc-300 text-xs px-3 py-2 flex items-center justify-between">
        <span>HTML Preview</span>
        <span className="text-zinc-500">Live</span>
      </div>
      <iframe
        ref={iframeRef}
        title="HTML Preview"
        className="w-full bg-white"
        style={{ height, border: "none" }}
        sandbox="allow-scripts"
      />
    </div>
  );
}