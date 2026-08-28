# JagX AI 1.1.2 — Better Auth (from scratch)

The live Grok preview app already has Better Auth with Google, X, and email/password.

To add the same to jagxai.name.ng (this Lovable repo):

1. Install `better-auth` and a Postgres database (Neon is fine).
2. Create `/api/auth/*` catch-all that calls `auth.handler(request)`.
3. Enable email/password in Better Auth config.
4. Add Google OAuth:
   - Google Cloud Console → OAuth client (Web)
   - Authorized redirect: `https://www.jagxai.name.ng/api/auth/callback/google`
   - Env: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `BETTER_AUTH_SECRET`, `BETTER_AUTH_URL=https://www.jagxai.name.ng`
5. Sign-in page: email/password form + Continue with Google.
6. Scope every saved chat to `session.user.id`. Never trust a client-sent user id.

Do not put API keys in the browser. NVIDIA NIM and OpenRouter stay server-side, same as `JAGX_API_KEY`.
