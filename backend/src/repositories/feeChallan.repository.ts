import { FeeChallanStatus, Prisma } from '@prisma/client';
import { prisma } from '../config/database';

const withStudent = {
  student: { select: { id: true, fullName: true, extraInfo: true } },
} satisfies Prisma.FeeChallanInclude;

interface GenerateChallanInput {
  academyId: string;
  challanNumber: string;
  studentId: string;
  classLabelSnapshot: string;
  billingYear: number;
  billingMonth: number;
  issueDate: Date;
  dueDate: Date;
  monthlyFee: number;
  admissionFee: number;
  examFee: number;
  transportFee: number;
  fine: number;
}

interface Pagination {
  page: number;
  limit: number;
}

interface ListFilters {
  studentId?: string;
  billingYear?: number;
  billingMonth?: number;
  status?: FeeChallanStatus;
}

export const feeChallanRepository = {
  async challanNumberExists(challanNumber: string): Promise<boolean> {
    const found = await prisma.feeChallan.findUnique({ where: { challanNumber }, select: { id: true } });
    return found !== null;
  },

  async existsForStudentAndMonth(studentId: string, billingYear: number, billingMonth: number): Promise<boolean> {
    const found = await prisma.feeChallan.findUnique({
      where: { studentId_billingYear_billingMonth: { studentId, billingYear, billingMonth } },
      select: { id: true },
    });
    return found !== null;
  },

  /** Skips (rather than errors on) students who already have a challan for that (year, month) — the DB constraint is authoritative. */
  async generateMany(challans: GenerateChallanInput[]) {
    return prisma.feeChallan.createMany({ data: challans, skipDuplicates: true });
  },

  createOne(challan: GenerateChallanInput) {
    return prisma.feeChallan.create({ data: challan, include: withStudent });
  },

  findByIdAndAcademy(id: string, academyId: string) {
    return prisma.feeChallan.findFirst({ where: { id, academyId }, include: withStudent });
  },

  async findManyByAcademy(academyId: string, filters: ListFilters, { page, limit }: Pagination) {
    const where: Prisma.FeeChallanWhereInput = { academyId, ...filters };
    const [items, total] = await Promise.all([
      prisma.feeChallan.findMany({
        where,
        include: withStudent,
        orderBy: [{ billingYear: 'desc' }, { billingMonth: 'desc' }, { createdAt: 'desc' }],
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.feeChallan.count({ where }),
    ]);
    return { items, total };
  },

  async findManyForStudent(studentId: string, filters: Omit<ListFilters, 'studentId'>, { page, limit }: Pagination) {
    const where: Prisma.FeeChallanWhereInput = { studentId, ...filters };
    const [items, total] = await Promise.all([
      prisma.feeChallan.findMany({
        where,
        include: withStudent,
        orderBy: [{ billingYear: 'desc' }, { billingMonth: 'desc' }, { createdAt: 'desc' }],
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.feeChallan.count({ where }),
    ]);
    return { items, total };
  },

  findForStudentsInMonth(studentIds: string[], billingYear: number, billingMonth: number) {
    return prisma.feeChallan.findMany({
      where: { studentId: { in: studentIds }, billingYear, billingMonth },
      include: withStudent,
    });
  },

  findAllForAcademy(academyId: string) {
    return prisma.feeChallan.findMany({ where: { academyId } });
  },

  updateStatus(id: string, status: FeeChallanStatus) {
    return prisma.feeChallan.update({ where: { id }, data: { status }, include: withStudent });
  },
};
