import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";
import { jagxChat, jagxStatus, searchWeb, readPage } from "./jagx.server";
import { analyzeAttachments, generateImage } from "./ai.server";

const ChatInput = z.object({
  message: z.string().min(1),
  grade: z
    .enum([
      "core", "engineer", "researcher", "architect", "creator", "operator",
      "analyst", "educator", "strategist", "scholar", "legal", "designer", "guardian",
    ])
    .default("core"),
  web: z.boolean().default(false),
  maxTokens: z.number().int().min(64).max(4000).optional(),
  history: z
    .array(z.object({ role: z.enum(["user", "assistant"]), content: z.string() }))
    .default([]),
});

export const sendToJagx = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => ChatInput.parse(input))
  .handler(async ({ data }) => jagxChat(data));

export const getJagxStatus = createServerFn({ method: "GET" }).handler(async () => jagxStatus());

export const webSearch = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => z.object({ query: z.string().min(1) }).parse(input))
  .handler(async ({ data }) => ({ results: await searchWeb(data.query, 6) }));

export const fetchPage = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => z.object({ url: z.string().url() }).parse(input))
  .handler(async ({ data }) => ({ text: await readPage(data.url) }));

const AttachInput = z.object({
  prompt: z.string().min(1),
  attachments: z
    .array(z.object({ name: z.string(), mime: z.string(), dataUrl: z.string().min(8) }))
    .min(1)
    .max(6),
});

export const readAttachments = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => AttachInput.parse(input))
  .handler(async ({ data }) => analyzeAttachments(data));

export const makeImage = createServerFn({ method: "POST" })
  .inputValidator((input: unknown) => z.object({ prompt: z.string().min(2) }).parse(input))
  .handler(async ({ data }) => generateImage(data.prompt));