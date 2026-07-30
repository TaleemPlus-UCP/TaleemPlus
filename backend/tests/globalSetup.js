const path = require('path');
const { execSync } = require('child_process');
const dotenv = require('dotenv');
const { PrismaClient } = require('@prisma/client');

async function waitForDatabase(databaseUrl, attempts = 15, delayMs = 2000) {
  for (let i = 1; i <= attempts; i++) {
    const client = new PrismaClient({ datasources: { db: { url: databaseUrl } } });
    try {
      await client.$queryRaw`SELECT 1`;
      await client.$disconnect();
      return;
    } catch (err) {
      await client.$disconnect().catch(() => {});
      if (i === attempts) throw new Error(`Database not reachable after ${attempts} attempts: ${err.message}`);
      // Service containers (e.g. a fresh Postgres in CI) can report
      // "ready" via a health check before the app role/db from
      // POSTGRES_USER/POSTGRES_DB actually exist — retry instead of
      // failing on the very first connection attempt.
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
}

module.exports = async function globalSetup() {
  const envPath = path.join(__dirname, '..', '.env.test');
  const parsed = dotenv.parse(require('fs').readFileSync(envPath));

  await waitForDatabase(parsed.DATABASE_URL);

  execSync('npx prisma migrate deploy', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit',
    env: { ...process.env, ...parsed },
  });
};
