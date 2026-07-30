import { env } from '../src/config/env';
import { prisma } from '../src/config/database';

// Defense-in-depth: this file truncates tables before every test. If env
// loading is ever misconfigured again (see the dotenv/@prisma-client import
// order bug fixed in config/database.ts) and DATABASE_URL points at a
// non-test database, refuse to run rather than silently wiping real data.
if (!/test/i.test(env.DATABASE_URL)) {
  throw new Error(
    `Refusing to run tests: DATABASE_URL does not look like a test database (${env.DATABASE_URL}). ` +
      'Expected the database name to contain "test".',
  );
}

beforeEach(async () => {
  // Fresh state per test — cheaper and safer than per-file isolation for
  // this suite's size. FK order matters: children before parents.
  await prisma.auditLog.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.passwordResetToken.deleteMany();
  await prisma.securityQuestion.deleteMany();
  await prisma.parentChildLink.deleteMany();
  await prisma.user.deleteMany();
  await prisma.academy.deleteMany();
});

afterAll(async () => {
  await prisma.$disconnect();
});
