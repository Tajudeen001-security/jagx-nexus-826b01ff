# JagX AI 1.1.2 (Flutter)

Mobile app — Grok × Claude style. Built by **JagX & JRILICENSE**.

## Build APK on GitHub (no local Flutter needed)

1. Add repo **Secrets** (Settings → Secrets → Actions):
   - `OPENROUTER_API_KEY` (recommended)
   - `GROQ_API_KEY` (free)
   - `NVIDIA_API_KEY`
   - `KIMI_API_KEY` (optional)
2. Actions → **Build JagX AI Android** → Run workflow (or push to `main`).
3. Download **jagx-ai-apk** artifact (`app-release.apk`).

## Features

- **SSE token streaming** chat + live activity steps + elapsed time
- 13 modes, live web
- Code Lab, Book Studio (**PDF + Markdown export**)
- Image Studio (free Pollinations)
- Custom JagX icon (SVG → mipmaps in CI)
- Auth deferred — open chat without sign-in for now

## Providers

OpenRouter → Kimi → NVIDIA → Groq (no xAI).

## Version

**1.1.2**
