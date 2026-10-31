/**
 * Migration Script: Imports exported Firestore JSON files into PostgreSQL database using Prisma Client.
 * Usage: node scripts/migrate_firebase_to_postgres.js
 */
const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('../taleemplus_backend/node_modules/@prisma/client');
const prisma = new PrismaClient();

const EXPORT_DIR = path.join(__dirname, '../data_export');

async function migrateData() {
  console.log('🚀 Starting Data Migration: Firebase JSON -> PostgreSQL via Prisma...');

  try {
    const usersPath = path.join(EXPORT_DIR, 'users.json');
    if (fs.existsSync(usersPath)) {
      const users = JSON.parse(fs.readFileSync(usersPath, 'utf8'));
      console.log(`  Processing ${users.length} user records...`);
      for (const u of users) {
        if (u.email && u.academy_id) {
          await prisma.user.upsert({
            where: { email: u.email },
            create: {
              id: u.uid || undefined,
              email: u.email,
              passwordHash: u.passwordHash || '$2a$10$abcdefghijklmnopqrstuu',
              fullName: u.full_name || u.email,
              role: (u.role || 'STUDENT').toUpperCase(),
              accountStatus: (u.account_status || 'ACTIVE').toUpperCase(),
              academyId: u.academy_id
            },
            update: {}
          });
        }
      }
    }
    console.log('✅ Data migration script completed.');
  } catch (err) {
    console.error('❌ Migration Error:', err);
  } finally {
    await prisma.$disconnect();
  }
}

migrateData();
