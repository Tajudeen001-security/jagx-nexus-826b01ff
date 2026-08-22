import {
  Cpu, Code2, Globe2, Layers, Sparkles, TerminalSquare,
  BarChart3, GraduationCap, Compass, BookOpen, Scale, PenTool, ShieldCheck,
  type LucideIcon,
} from "lucide-react";

export type GradeId =
  | "core" | "engineer" | "researcher" | "architect" | "creator" | "operator"
  | "analyst" | "educator" | "strategist" | "scholar" | "legal" | "designer" | "guardian";

export const GRADE_LIST: Array<{ id: GradeId; label: string; blurb: string; detail: string; icon: LucideIcon }> = [
  { id: "core", label: "Core", blurb: "Balanced general intelligence", detail: "Your default assistant for everyday questions, writing, and quick help.", icon: Cpu },
  { id: "engineer", label: "Engineer", blurb: "Deep coding, debugging, refactors", detail: "Full programs, bug fixes, and code reviews across any language.", icon: Code2 },
  { id: "researcher", label: "Researcher", blurb: "Live web evidence, cited", detail: "Pulls current information from the web and cites sources.", icon: Globe2 },
  { id: "architect", label: "Architect", blurb: "Systems, infra, scale", detail: "System design, architecture decisions, and scaling strategy.", icon: Layers },
  { id: "creator", label: "Creator", blurb: "Writing, naming, narrative", detail: "Copywriting, brand names, stories, and creative content.", icon: Sparkles },
  { id: "operator", label: "Operator", blurb: "Shell, ops, automation", detail: "Exact terminal commands, scripts, and automation workflows.", icon: TerminalSquare },
  { id: "analyst", label: "Analyst", blurb: "Data, metrics, forecasting", detail: "Breaks down numbers, spreadsheets, and business metrics.", icon: BarChart3 },
  { id: "educator", label: "Educator", blurb: "Clear, step-by-step teaching", detail: "Explains concepts simply, like a patient tutor.", icon: GraduationCap },
  { id: "strategist", label: "Strategist", blurb: "Business planning & decisions", detail: "Helps think through strategy, tradeoffs, and next moves.", icon: Compass },
  { id: "scholar", label: "Scholar", blurb: "Deep, rigorous long-form analysis", detail: "Thorough, well-reasoned answers for complex topics.", icon: BookOpen },
  { id: "legal", label: "Legal", blurb: "Contracts & compliance awareness", detail: "Reviews and drafts documents with legal structure in mind (not a lawyer).", icon: Scale },
  { id: "designer", label: "Designer", blurb: "UI/UX & visual design feedback", detail: "Product design critique, layout ideas, and visual polish.", icon: PenTool },
  { id: "guardian", label: "Guardian", blurb: "Security review & best practices", detail: "Reviews code and systems for vulnerabilities and hardening.", icon: ShieldCheck },
];