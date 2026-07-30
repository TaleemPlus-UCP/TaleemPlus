import { PrismaClient } from '@prisma/client';
import { hashPassword } from '../src/utils/password';

const prisma = new PrismaClient();

const DEMO_PASSWORD = 'Passw0rd!';

async function main(): Promise<void> {
  const passwordHash = await hashPassword(DEMO_PASSWORD);

  const academy = await prisma.academy.upsert({
    where: { code: 'TP-DEMO1' },
    update: {},
    create: {
      name: 'Demo Academy',
      address: '123 Model Town, Lahore',
      phone: '+92-300-0000000',
      code: 'TP-DEMO1',
    },
  });

  const admin = await prisma.user.upsert({
    where: { email: 'admin@demo.taleemplus.app' },
    update: {},
    create: {
      fullName: 'Demo Admin',
      email: 'admin@demo.taleemplus.app',
      passwordHash,
      phoneNumber: '+92-300-0000001',
      role: 'ADMIN',
      accountStatus: 'ACTIVE',
      academyId: academy.id,
      joiningDate: new Date(),
    },
  });

  const teacher = await prisma.user.upsert({
    where: { email: 'teacher@demo.taleemplus.app' },
    update: {},
    create: {
      fullName: 'Demo Teacher',
      email: 'teacher@demo.taleemplus.app',
      passwordHash,
      phoneNumber: '+92-300-0000002',
      role: 'TEACHER',
      accountStatus: 'ACTIVE',
      academyId: academy.id,
      assignedSections: ['A', 'B'],
      joiningDate: new Date(),
    },
  });

  const student = await prisma.user.upsert({
    where: { email: 'student@demo.taleemplus.app' },
    update: {},
    create: {
      fullName: 'Demo Student',
      email: 'student@demo.taleemplus.app',
      passwordHash,
      phoneNumber: '+92-300-0000003',
      role: 'STUDENT',
      accountStatus: 'ACTIVE',
      academyId: academy.id,
      extraInfo: 'Roll No. 21',
      joiningDate: new Date(),
    },
  });

  const parent = await prisma.user.upsert({
    where: { email: 'parent@demo.taleemplus.app' },
    update: {},
    create: {
      fullName: 'Demo Parent',
      email: 'parent@demo.taleemplus.app',
      passwordHash,
      phoneNumber: '+92-300-0000004',
      role: 'PARENT',
      accountStatus: 'ACTIVE',
      academyId: academy.id,
      joiningDate: new Date(),
    },
  });

  await prisma.parentChildLink.upsert({
    where: { parentId_childId: { parentId: parent.id, childId: student.id } },
    update: {},
    create: { parentId: parent.id, childId: student.id },
  });

  console.log('Seed complete. Demo accounts (all share the same password):');
  console.log(`  Academy code: ${academy.code}`);
  console.log(`  Admin:   ${admin.email} / ${DEMO_PASSWORD}`);
  console.log(`  Teacher: ${teacher.email} / ${DEMO_PASSWORD}`);
  console.log(`  Student: ${student.email} / ${DEMO_PASSWORD}`);
  console.log(`  Parent:  ${parent.email} / ${DEMO_PASSWORD}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
