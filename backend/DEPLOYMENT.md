# Deploying the TaleemPlus backend

This covers what the *code* needs to run in production. Provisioning actual
infrastructure (a host, a domain, a production Postgres instance, a Play
Console account for the Flutter app) is out of scope here — those are
account/billing decisions only the project owner can make.

## Required environment variables

Copy `.env.example` to `.env` (or set these as real env vars/secrets on
whatever host you pick) and fill in production values:

- `NODE_ENV=production`
- `DATABASE_URL` — a production Postgres connection string.
- `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` — long random strings (≥32
  chars), **different** from the dev/test values in this repo. Generate
  with e.g. `openssl rand -hex 48`.
- `CORS_ORIGINS` — comma-separated allowlist of the actual frontend
  origin(s). **The server refuses to boot in production if this is empty**
  (see `src/config/env.ts`) — that's intentional, not a bug.
- `SMTP_*` — a real SMTP provider for password-reset emails (left blank in
  dev, which falls back to an Ethereal test inbox).
- `CLOUDINARY_*` — only needed once the file-upload module actually uses it;
  safe to leave blank until then.

## Database migrations

```bash
npx prisma migrate deploy
```

Never run `npx prisma migrate dev` or the seed script (`prisma:seed`)
against production — `migrate dev` can generate destructive migrations
interactively, and the seed script creates demo accounts with a known
password.

## Running with Docker

```bash
docker build -t taleemplus-backend .
docker run -p 4000:4000 --env-file .env taleemplus-backend
```

The image's `CMD` runs `prisma migrate deploy` on every container start
before launching the server, so a fresh deploy always ends up on the latest
schema.

Logs are written both to stdout (captured by most container platforms
automatically) and to a local `logs/` directory via
`winston-daily-rotate-file` — mount a volume at `/app/logs` if you want
those retained across container restarts; otherwise they're ephemeral,
which is fine if your host already aggregates stdout.

## Wiring the Flutter app to a deployed backend

The app's only backend URL is `lib/core/config/api_config.dart`, overridable
at build time:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

The CI workflow (`.github/workflows/main.yml`) reads this from a repo
variable (`vars.PRODUCTION_API_BASE_URL`) for the web build — set that once
a production backend URL exists; until then it silently falls back to the
dev default (`localhost`/`10.0.2.2`), which will not work for a real
release build.

## Play Store readiness (once you're ready to publish)

Already done in-repo:
- `applicationId`/`namespace` set to a real reverse-domain id
  (`com.taleemplus.app`), not the `com.example.*` placeholder.
- Release signing config (`android/app/build.gradle.kts`) reads from
  `android/key.properties` (gitignored — generate your own release keystore,
  never commit it).
- CI builds a `.aab` (`android-release-aab` artifact) in addition to the
  APK.

Still needed from you:
- A Google Play Console developer account ($25 one-time).
- A real release keystore + `android/key.properties` (keep the password
  somewhere safe — losing it means you can never update the app again under
  the same listing).
- Store listing content: screenshots, description, privacy policy URL.
