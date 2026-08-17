import { Cpu, Code2, Globe2, Layers, Sparkles, TerminalSquare, type LucideIcon } from "lucide-react";

export type GradeId = "core" | "engineer" | "researcher" | "architect" | "creator" | "operator";

export const GRADE_LIST: Array<{ id: GradeId; label: string; blurb: string; icon: LucideIcon }> = [
  { id: "core", label: "Core", blurb: "Balanced general intelligence", icon: Cpu },
  { id: "engineer", label: "Engineer", blurb: "Deep coding, debugging, refactors", icon: Code2 },
  { id: "researcher", label: "Researcher", blurb: "Live web evidence, cited", icon: Globe2 },
  { id: "architect", label: "Architect", blurb: "Systems, infra, scale", icon: Layers },
  { id: "creator", label: "Creator", blurb: "Writing, naming, narrative", icon: Sparkles },
  { id: "operator", label: "Operator", blurb: "Shell, ops, automation", icon: TerminalSquare },
];
