import { ChevronDown } from "lucide-react";
import { GRADE_LIST, type GradeId } from "@/lib/grades";
import {
  Drawer, DrawerContent, DrawerHeader, DrawerTitle, DrawerClose,
} from "@/components/ui/drawer";

export function ModelPicker({ grade, onGrade }: { grade: GradeId; onGrade: (g: GradeId) => void }) {
  const current = GRADE_LIST.find((g) => g.id === grade) ?? GRADE_LIST[0];

  return (
    <Drawer>
      <DrawerContent className="mx-auto max-h-[80vh] max-w-lg">
        <DrawerHeader className="text-left">
          <DrawerTitle className="font-display text-base">Choose a mode</DrawerTitle>
        </DrawerHeader>
        <div className="max-h-[60vh] overflow-y-auto px-4 pb-6">
          <div className="space-y-1">
            {GRADE_LIST.map((g) => (
              <DrawerClose key={g.id} asChild>
                <button
                  onClick={() => onGrade(g.id)}
                  className={`flex w-full items-start gap-3 rounded-xl border px-3 py-3 text-left transition-colors ${
                    grade === g.id
                      ? "border-primary/60 bg-primary/10"
                      : "border-transparent hover:bg-surface-2"
                  }`}
                >
                  <g.icon className={`mt-0.5 size-4.5 shrink-0 ${grade === g.id ? "text-primary" : "text-muted-foreground"}`} />
                  <div>
                    <div className="text-sm font-medium">{g.label}</div>
                    <div className="mt-0.5 text-xs text-muted-foreground">{g.detail}</div>
                  </div>
                </button>
              </DrawerClose>
            ))}
          </div>
        </div>
      </DrawerContent>
      <DrawerTriggerButton current={current} />
    </Drawer>
  );
}

function DrawerTriggerButton({ current }: { current: (typeof GRADE_LIST)[number] }) {
  const { DrawerTrigger } = require("@/components/ui/drawer");
  return (
    <DrawerTrigger asChild>
      <button className="flex items-center gap-1.5 rounded-full border border-border px-3 py-1.5 font-mono text-[11px] text-muted-foreground transition-colors hover:text-foreground">
        <current.icon className="size-3.5 text-primary" />
        {current.label}
        <ChevronDown className="size-3" />
      </button>
    </DrawerTrigger>
  );
}