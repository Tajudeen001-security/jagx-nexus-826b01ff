# JagX AI 1.1.2 (Flutter)

Mobile app for **JagX AI** — Grok × Claude style console.
Built by **JagX & JRILICENSE**.

Web site stays separate: https://www.jagxai.name.ng/
This folder is **mobile only**.

## Providers (no xAI)

| Provider | Env / dart-define | Notes |
|----------|-------------------|--------|
| **OpenRouter** | `OPENROUTER_API_KEY` | Prefer free models e.g. `moonshotai/kimi-k2:free` |
| **Kimi (Moonshot)** | `KIMI_API_KEY` or `MOONSHOT_API_KEY` | Official API is **paid** (credits on signup possible) |
| **NVIDIA NIM** | `NVIDIA_API_KEY` | Free tier on build.nvidia.com |
| **Groq** | `GROQ_API_KEY` | Strong free tier |

Priority in app: OpenRouter → Kimi → NVIDIA → Groq.

**Images:** free Pollinations (no key).

## Do not paste keys in chat or commit them

1. Get keys from each provider console.
2. For **GitHub Actions builds**: Repo → Settings → Secrets and variables → Actions → New repository secret.
3. For **local / Codemagic / CI build**: pass `--dart-define=NAME=value` at build time.

Suggested secret names:

- `OPENROUTER_API_KEY`
- `KIMI_API_KEY`
- `NVIDIA_API_KEY`
- `GROQ_API_KEY`

## Run (when you have a machine or CI)

```bash
cd flutter
flutter pub get
flutter run \
  --dart-define=OPENROUTER_API_KEY=sk-or-... \
  --dart-define=KIMI_API_KEY=sk-... \
  --dart-define=NVIDIA_API_KEY=nvapi-... \
  --dart-define=GROQ_API_KEY=gsk_... \
  --dart-define=AUTH_BASE_URL=https://www.jagxai.name.ng
```

At least **one** LLM key is required for chat.

## Version

**1.1.2**
