// Vercel serverless entry point. Express apps are already callable as
// `(req, res) => void`, so exporting the built app directly is enough —
// no separate handler wrapper needed. This intentionally imports `../src/app`
// rather than `../src/server` since server.ts calls `app.listen()`, which
// doesn't apply in a serverless function (Vercel owns the HTTP server).
import { createApp } from '../src/app';

export default createApp();
