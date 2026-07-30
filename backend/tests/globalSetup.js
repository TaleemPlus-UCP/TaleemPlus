const path = require('path');
const { execSync } = require('child_process');
const dotenv = require('dotenv');

module.exports = async function globalSetup() {
  const envPath = path.join(__dirname, '..', '.env.test');
  const parsed = dotenv.parse(require('fs').readFileSync(envPath));

  execSync('npx prisma migrate deploy', {
    cwd: path.join(__dirname, '..'),
    stdio: 'inherit',
    env: { ...process.env, ...parsed },
  });
};
