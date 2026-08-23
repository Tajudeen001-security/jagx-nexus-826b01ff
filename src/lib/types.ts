export type Source = { title: string; url: string; snippet: string };

export type Msg = {
  role: "user" | "assistant";
  content: string;
  sources?: Source[];
  error?: boolean;
  image?: string;
  files?: string[];
};

export type ChatSession = {
  id: string;
  title: string;
  messages: Msg[];
  grade: string;
  updatedAt: number;
};