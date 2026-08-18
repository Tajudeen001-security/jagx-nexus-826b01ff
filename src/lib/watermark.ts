// Invisible provenance mark. Applied to prose only — never inside fenced code,
// inline code or attribute values, so generated code stays byte-exact and runnable.
const ZW = ["\u200b", "\u200c"]; // 0 -> ZWSP, 1 -> ZWNJ
const TAG = "JAGX";

const BITS = Array.from(TAG)
  .flatMap((c) => c.charCodeAt(0).toString(2).padStart(8, "0").split(""))
  .map((b) => ZW[Number(b)] as string)
  .join("");

/** Strip every zero-width mark (used before copy / before sending text back to a model). */
export function stripMark(text: string): string {
  return text.replace(/[\u200b\u200c\u200d\ufeff]/g, "");
}

/** Embed the mark in a prose string. Returns text unchanged when it is empty. */
export function markProse(text: string): string {
  if (!text.trim()) return text;
  const clean = stripMark(text);
  const i = Math.min(clean.length, Math.max(1, Math.floor(clean.length / 2)));
  return clean.slice(0, i) + BITS + clean.slice(i);
}

/** True when the text carries a JagX provenance mark. */
export function hasMark(text: string): boolean {
  return text.includes(BITS);
}
