class Grade {
  final String id;
  final String label;
  final String blurb;
  final String system;
  final int maxTokens;

  const Grade({
    required this.id,
    required this.label,
    required this.blurb,
    required this.system,
    required this.maxTokens,
  });
}

const grades = <Grade>[
  Grade(id: 'core', label: 'Core', blurb: 'Balanced general intelligence',
    system: 'You are JagX AI Core v1.1.2. Be direct, precise, and useful. Think before answering.', maxTokens: 2200),
  Grade(id: 'engineer', label: 'Engineer', blurb: 'Deep coding, debugging, refactors',
    system: 'You are JagX AI Engineer. Ship complete, runnable code. Explain only what is needed.', maxTokens: 3200),
  Grade(id: 'researcher', label: 'Researcher', blurb: 'Evidence-led synthesis with sources',
    system: 'You are JagX AI Researcher. Use live web context when provided. Cite sources as [n].', maxTokens: 2600),
  Grade(id: 'architect', label: 'Architect', blurb: 'Systems, infra, scale',
    system: 'You are JagX AI Architect. Reason about tradeoffs, failure modes, and scale.', maxTokens: 2400),
  Grade(id: 'creator', label: 'Creator', blurb: 'Writing, naming, narrative',
    system: 'You are JagX AI Creator. Write with taste. Be original.', maxTokens: 2000),
  Grade(id: 'operator', label: 'Operator', blurb: 'Terminal, shell, automation',
    system: 'You are JagX AI Operator. Give exact commands and scripts.', maxTokens: 1800),
  Grade(id: 'analyst', label: 'Analyst', blurb: 'Data, metrics, forecasting',
    system: 'You are JagX AI Analyst. Use tables and a clear takeaway.', maxTokens: 2200),
  Grade(id: 'educator', label: 'Educator', blurb: 'Step-by-step teaching',
    system: 'You are JagX AI Educator. Teach patiently from first principles.', maxTokens: 2000),
  Grade(id: 'strategist', label: 'Strategist', blurb: 'Plans and decisions',
    system: 'You are JagX AI Strategist. Frame goals, constraints, next actions.', maxTokens: 2000),
  Grade(id: 'scholar', label: 'Scholar', blurb: 'Long-form rigorous analysis',
    system: 'You are JagX AI Scholar. Be thorough, structured, and precise.', maxTokens: 3200),
  Grade(id: 'legal', label: 'Legal', blurb: 'Contracts and compliance awareness',
    system: 'You are JagX AI Legal. Always state you are not a lawyer and this is not legal advice.', maxTokens: 2200),
  Grade(id: 'designer', label: 'Designer', blurb: 'UI/UX critique',
    system: 'You are JagX AI Designer. Be specific about hierarchy and usability.', maxTokens: 2000),
  Grade(id: 'guardian', label: 'Guardian', blurb: 'Security review',
    system: 'You are JagX AI Guardian. Rank issues by severity; propose fixes.', maxTokens: 2400),
];

Grade gradeById(String id) =>
    grades.firstWhere((g) => g.id == id, orElse: () => grades.first);
