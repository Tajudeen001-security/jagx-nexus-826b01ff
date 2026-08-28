# JagX AI 1.1.2 (Flutter)

Mobile app for **JagX AI** — Grok × Claude style console.
Built by **JagX & JRILICENSE**.

Web site stays separate: https://www.jagxai.name.ng/
This folder is **mobile only** and does not replace the existing site code.

## Features

- Chat with 13 intelligence modes
- Live activity steps (searching / reading / writing) + elapsed time
- Live web retrieval
- Code Lab
- Book Studio (Markdown → share)
- Image Studio
- Auth: email/password + Google (Better Auth compatible)

## Run

```bash
cd flutter
flutter pub get
flutter run \
  --dart-define=OPENROUTER_API_KEY=sk-or-... \
  --dart-define=XAI_API_KEY=xai-... \
  --dart-define=AUTH_BASE_URL=https://www.jagxai.name.ng
```

## Version

**1.1.2** — not 6.7.
