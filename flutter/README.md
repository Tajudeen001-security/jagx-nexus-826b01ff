# JagX AI 1.1.2 (Flutter)

Mobile app for **JagX AI** — Grok × Claude style console.
Built by **JagX & JRILICENSE**.

Web site stays separate: https://www.jagxai.name.ng/
This folder is **mobile only** and does not replace the existing site code.

## Features

- Streaming chat with live activity steps + elapsed time
- Thirteen intelligence modes
- Live web retrieval (DuckDuckGo)
- Code Lab (analyze + improve with LLM)
- Book Studio (Markdown generate + export/share)
- Image Studio (xAI image generation)
- Auth: email/password + Google (Better Auth compatible, local fallback)

## Run

```bash
cd flutter
flutter pub get
flutter run \
  --dart-define=OPENROUTER_API_KEY=sk-or-... \
  --dart-define=XAI_API_KEY=xai-... \
  --dart-define=NVIDIA_API_KEY=nvapi-... \
  --dart-define=AUTH_BASE_URL=https://www.jagxai.name.ng
```

At least one LLM key is required for chat. Image Studio needs `XAI_API_KEY`.

## Version

**1.1.2** — not 6.7.
