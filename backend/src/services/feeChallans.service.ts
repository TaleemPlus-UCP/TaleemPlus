import { FeeChallanStatus, UserRole } from '@prisma/client';
import { AUDIT_ACTIONS } from '../constants/roles';
import { BadRequestError, ConflictError, ForbiddenError, NotFoundError } from '../exceptions/AppError';
import { auditLogRepository } from '../repositories/auditLog.repository';
import { classSectionRepository } from '../repositories/classSection.repository';
import { feeChallanRepository } from '../repositories/feeChallan.repository';
import { parentChildLinkRepository } from '../repositories/parentChildLink.repository';
import { userRepository } from '../repositories/user.repository';
import { buildPaginationMeta } from '../utils/apiResponse';
import { generateChallanNumber } from '../utils/challanNumber';

interface ActorContext {
  userId: string;
  academyId: string;
  role: UserRole;
}

interface Pagination {
  page: number;
  limit: number;
}

interface GenerateChallansInput {
  sectionId: string;
  billingYear: number;
  billingMonth: number;
  monthlyFee: number;
  admissionFee: number;
  examFee: number;
  transportFee: number;
  fine: number;
  dueDate?: Date;
}

function defaultDueDate(billingYear: number, billingMonth: number): Date {
  // Matches the legacy app's convention: the 10th of the billing month.
  return new Date(Date.UTC(billingYear, billingMonth - 1, 10));
}

async function generate(ctx: ActorContext, input: GenerateChallansInput) {
  const section = await classSectionRepository.findByIdAndAcademy(input.sectionId, ctx.academyId);
  if (!section) throw new NotFoundError('Class section not found in your academy.');

  const enrolledIds = await classSectionRepository.findEnrolledStudentIds(input.sectionId);
  if (enrolledIds.length === 0) {
    throw new BadRequestError('No students are enrolled in this section.');
  }

  const students = await userRepository.findManyByIds(enrolledIds);
  const activeStudents = students.filter((s) => s.role === 'STUDENT' && s.accountStatus === 'ACTIVE');
  if (activeStudents.length === 0) {
    throw new BadRequestError('No ACTIVE students are enrolled in this section.');
  }

  const classLabelSnapshot = `${section.className}-${section.sectionLabel}`;
  const issueDate = new Date();
  const dueDate = input.dueDate ?? defaultDueDate(input.billingYear, input.billingMonth);

  const { count } = await feeChallanRepository.generateMany(
    activeStudents.map((student) => ({
      academyId: ctx.academyId,
      challanNumber: generateChallanNumber(input.billingYear, input.billingMonth),
      studentId: student.id,
      classLabelSnapshot,
      billingYear: input.billingYear,
      billingMonth: input.billingMonth,
      issueDate,
      dueDate,
      monthlyFee: input.monthlyFee,
      admissionFee: input.admissionFee,
      examFee: input.examFee,
      transportFee: input.transportFee,
      fine: input.fine,
    })),
  );

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.FEE_CHALLANS_GENERATED,
    metadata: { sectionId: input.sectionId, billingYear: input.billingYear, billingMonth: input.billingMonth, generatedCount: count },
  });

  return { generatedCount: count, skippedCount: activeStudents.length - count, eligibleCount: activeStudents.length };
}

interface CreateChallanInput {
  studentId: string;
  billingYear: number;
  billingMonth: number;
  monthlyFee: number;
  admissionFee: number;
  examFee: number;
  transportFee: number;
  fine: number;
  dueDate?: Date;
}

/** One ad-hoc challan for a single student (e.g. a one-off library fine), independent of section-wide billing. */
async function createOne(ctx: ActorContext, input: CreateChallanInput) {
  const student = await userRepository.findById(input.studentId);
  if (!student || student.academyId !== ctx.academyId || student.role !== 'STUDENT' || student.accountStatus !== 'ACTIVE') {
    throw new BadRequestError('studentId must be an ACTIVE student in your academy.');
  }

  const alreadyBilled = await feeChallanRepository.existsForStudentAndMonth(
    input.studentId,
    input.billingYear,
    input.billingMonth,
  );
  if (alreadyBilled) {
    throw new ConflictError('This student already has a fee challan for that billing month.');
  }

  const sectionIds = await classSectionRepository.findSectionIdsForStudent(input.studentId);
  let classLabelSnapshot = '';
  if (sectionIds.length > 0) {
    const section = await classSectionRepository.findByIdAndAcademy(sectionIds[0], ctx.academyId);
    if (section) classLabelSnapshot = `${section.className}-${section.sectionLabel}`;
  }

  const issueDate = new Date();
  const dueDate = input.dueDate ?? defaultDueDate(input.billingYear, input.billingMonth);

  const challan = await feeChallanRepository.createOne({
    academyId: ctx.academyId,
    challanNumber: generateChallanNumber(input.billingYear, input.billingMonth),
    studentId: input.studentId,
    classLabelSnapshot,
    billingYear: input.billingYear,
    billingMonth: input.billingMonth,
    issueDate,
    dueDate,
    monthlyFee: input.monthlyFee,
    admissionFee: input.admissionFee,
    examFee: input.examFee,
    transportFee: input.transportFee,
    fine: input.fine,
  });

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.FEE_CHALLAN_CREATED,
    metadata: { challanId: challan.id, studentId: input.studentId },
  });

  return challan;
}

interface ListFilters {
  studentId?: string;
  billingYear?: number;
  billingMonth?: number;
  status?: FeeChallanStatus;
}

async function list(ctx: ActorContext, filters: ListFilters, pagination: Pagination) {
  if (ctx.role === 'ADMIN') {
    const { studentId, ...rest } = filters;
    const { items, total } = studentId
      ? await feeChallanRepository.findManyForStudent(studentId, rest, pagination)
      : await feeChallanRepository.findManyByAcademy(ctx.academyId, filters, pagination);
    return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
  }

  if (ctx.role === 'STUDENT') {
    const { billingYear, billingMonth, status } = filters;
    const { items, total } = await feeChallanRepository.findManyForStudent(
      ctx.userId,
      { billingYear, billingMonth, status },
      pagination,
    );
    return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
  }

  if (ctx.role === 'PARENT') {
    if (!filters.studentId) {
      throw new BadRequestError('studentId query parameter is required for parent accounts.');
    }
    const linked = await parentChildLinkRepository.existsLink(ctx.userId, filters.studentId);
    if (!linked) {
      throw new ForbiddenError('You can only view fee challans for your linked children.');
    }
    const { studentId, ...rest } = filters;
    const { items, total } = await feeChallanRepository.findManyForStudent(studentId, rest, pagination);
    return { items, meta: buildPaginationMeta(pagination.page, pagination.limit, total) };
  }

  throw new ForbiddenError('Teachers do not have access to fee challans.');
}

async function getOne(ctx: ActorContext, challanId: string) {
  const challan = await feeChallanRepository.findByIdAndAcademy(challanId, ctx.academyId);
  if (!challan) throw new NotFoundError('Fee challan not found.');

  if (ctx.role === 'ADMIN') return challan;

  if (ctx.role === 'STUDENT') {
    if (challan.studentId !== ctx.userId) throw new NotFoundError('Fee challan not found.');
    return challan;
  }

  if (ctx.role === 'PARENT') {
    const linked = await parentChildLinkRepository.existsLink(ctx.userId, challan.studentId);
    if (!linked) throw new NotFoundError('Fee challan not found.');
    return challan;
  }

  throw new ForbiddenError('Teachers do not have access to fee challans.');
}

async function updateStatus(ctx: ActorContext, challanId: string, status: FeeChallanStatus) {
  const challan = await feeChallanRepository.findByIdAndAcademy(challanId, ctx.academyId);
  if (!challan) throw new NotFoundError('Fee challan not found.');

  const updated = await feeChallanRepository.updateStatus(challanId, status);

  await auditLogRepository.record({
    userId: ctx.userId,
    action: AUDIT_ACTIONS.FEE_CHALLAN_STATUS_UPDATED,
    metadata: { challanId, status },
  });

  return updated;
}

async function getSectionStatus(ctx: ActorContext, sectionId: string, year?: number, month?: number) {
  const section = await classSectionRepository.findByIdAndAcademy(sectionId, ctx.academyId);
  if (!section) throw new NotFoundError('Class section not found in your academy.');

  const now = new Date();
  const resolvedYear = year ?? now.getUTCFullYear();
  const resolvedMonth = month ?? now.getUTCMonth() + 1;

  const enrolledIds = await classSectionRepository.findEnrolledStudentIds(sectionId);
  const students = await userRepository.findManyByIds(enrolledIds);
  const challans = await feeChallanRepository.findForStudentsInMonth(enrolledIds, resolvedYear, resolvedMonth);
  const challanByStudent = new Map(challans.map((c) => [c.studentId, c]));

  const roster = students
    .map((student) => ({
      studentId: student.id,
      fullName: student.fullName,
      challan: challanByStudent.get(student.id) ?? null,
    }))
    .sort((a, b) => a.fullName.localeCompare(b.fullName));

  return { sectionId, year: resolvedYear, month: resolvedMonth, students: roster };
}

export const feeChallansService = {
  generate,
  createOne,
  list,
  getOne,
  updateStatus,
  getSectionStatus,
};
