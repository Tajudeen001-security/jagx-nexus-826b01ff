# JagX AI 1.2.1

Flutter Android app — a Grok-style AI workspace with live web research, coding, books and images.

## AI providers

JagX now uses only two LLM providers:

1. NVIDIA NIM — primary, using NVIDIA_API_KEY.
2. OpenRouter — fallback, using OPENROUTER_API_KEY.

Kimi/Moonshot and Groq have been removed from the runtime and Android build workflow. JagX will not select a Kimi model.

The NVIDIA provider uses the current NVIDIA Nemotron 3.5 Lightning 30B endpoint. OpenRouter uses its current free-model router instead of hard-coding a model that can become unavailable.

## Web research

When Web is enabled, JagX searches the live web, opens the top result pages, extracts readable page text, gives that material to the selected model, and shows clickable sources below the answer.

You can also paste a direct URL into a prompt and JagX will attempt to read it.

Some sites block automated requests. In that case JagX keeps the search result and tells the model only what it could retrieve.

## UI

The provider/mode controls were removed from the top app bar and moved into the bottom composer, following the interaction pattern shown in Grok. The top bar is intentionally minimal.

## GitHub Actions

Required repository secrets:

- NVIDIA_API_KEY
- OPENROUTER_API_KEY

The Android workflow uses the current stable Flutter channel, runs Flutter analysis, builds the release APK, and uploads the APK as an artifact.

## Security

GitHub Actions secrets are encrypted and protected inside GitHub. However, passing an API key with Flutter dart-define embeds that key in the compiled APK. For a public production release, move the LLM calls behind a server-side API so provider keys never ship inside the mobile binary.

## Version

1.2.1
