import { Academy, ClassOffering, ClassSection, FeeChallan, Quiz, QuizQuestion, TestMark, TimetableSlot, User } from '@prisma/client';

type UserWithAcademy = User & { academy?: Academy | null };

/** Never let a raw Prisma User (which carries `passwordHash`) leave the API layer. */
export function toUserResponse(user: UserWithAcademy) {
  return {
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    phoneNumber: user.phoneNumber,
    role: user.role,
    accountStatus: user.accountStatus,
    joiningDate: user.joiningDate,
    extraInfo: user.extraInfo,
    assignedSections: user.assignedSections,
    createdAt: user.createdAt,
    academy: user.academy
      ? {
          id: user.academy.id,
          name: user.academy.name,
          address: user.academy.address,
          phone: user.academy.phone,
          logoUrl: user.academy.logoUrl,
          code: user.academy.code,
        }
      : null,
  };
}

type SectionWithDetails = ClassSection & {
  enrollments: { studentId: string }[];
  _count: { enrollments: number; offerings: number };
};

export function toSectionResponse(section: SectionWithDetails) {
  return {
    id: section.id,
    academyId: section.academyId,
    className: section.className,
    sectionLabel: section.sectionLabel,
    studentIds: section.enrollments.map((e) => e.studentId),
    enrollmentCount: section._count.enrollments,
    offeringCount: section._count.offerings,
    createdAt: section.createdAt,
    updatedAt: section.updatedAt,
  };
}

type OfferingWithDetails = ClassOffering & {
  section: { id: string; className: string; sectionLabel: string; _count: { enrollments: number } };
  teacher: { id: string; fullName: string; email: string } | null;
};

export function toOfferingResponse(offering: OfferingWithDetails) {
  return {
    id: offering.id,
    academyId: offering.academyId,
    subject: offering.subject,
    section: {
      id: offering.section.id,
      className: offering.section.className,
      sectionLabel: offering.section.sectionLabel,
      enrollmentCount: offering.section._count.enrollments,
    },
    teacher: offering.teacher,
    createdAt: offering.createdAt,
    updatedAt: offering.updatedAt,
  };
}

type SlotWithDetails = TimetableSlot & {
  offering: {
    id: string;
    subject: string;
    sectionId: string;
    section: { id: string; className: string; sectionLabel: string };
    teacher: { id: string; fullName: string } | null;
  } | null;
};

export function toTimetableSlotResponse(slot: SlotWithDetails) {
  return {
    id: slot.id,
    academyId: slot.academyId,
    isBreak: slot.isBreak,
    dayOfWeek: slot.dayOfWeek,
    startMinutes: slot.startMinutes,
    endMinutes: slot.endMinutes,
    room: slot.room,
    semester: slot.semester,
    effectiveFrom: slot.effectiveFrom,
    effectiveTo: slot.effectiveTo,
    offering: slot.offering
      ? {
          id: slot.offering.id,
          subject: slot.offering.subject,
          section: slot.offering.section,
          teacher: slot.offering.teacher,
        }
      : null,
    createdAt: slot.createdAt,
    updatedAt: slot.updatedAt,
  };
}

type ChallanWithStudent = FeeChallan & {
  student: { id: string; fullName: string; extraInfo: string | null };
};

/** Storage/arithmetic stays `Decimal` end-to-end; only the API response converts to plain numbers. */
export function toFeeChallanResponse(challan: ChallanWithStudent) {
  const monthlyFee = challan.monthlyFee.toNumber();
  const admissionFee = challan.admissionFee.toNumber();
  const examFee = challan.examFee.toNumber();
  const transportFee = challan.transportFee.toNumber();
  const fine = challan.fine.toNumber();

  return {
    id: challan.id,
    academyId: challan.academyId,
    challanNumber: challan.challanNumber,
    student: challan.student,
    classLabelSnapshot: challan.classLabelSnapshot,
    billingYear: challan.billingYear,
    billingMonth: challan.billingMonth,
    issueDate: challan.issueDate,
    dueDate: challan.dueDate,
    monthlyFee,
    admissionFee,
    examFee,
    transportFee,
    fine,
    totalAmount: Math.round((monthlyFee + admissionFee + examFee + transportFee + fine) * 100) / 100,
    status: challan.status,
    createdAt: challan.createdAt,
    updatedAt: challan.updatedAt,
  };
}

type QuizWithDetails = Quiz & {
  offering: {
    id: string;
    subject: string;
    sectionId: string;
    teacherId: string | null;
    section: { id: string; className: string; sectionLabel: string };
    teacher: { id: string; fullName: string } | null;
  };
  questions: QuizQuestion[];
  createdBy: { id: string; fullName: string } | null;
};

/** Staff-only response — includes the answer key (correctIndex/gradingKeywords). Never sent to students/parents. */
export function toQuizResponse(quiz: QuizWithDetails) {
  return {
    id: quiz.id,
    academyId: quiz.academyId,
    offering: {
      id: quiz.offering.id,
      subject: quiz.offering.subject,
      section: quiz.offering.section,
      teacher: quiz.offering.teacher,
    },
    title: quiz.title,
    subject: quiz.subject,
    session: quiz.session,
    chapter: quiz.chapter,
    difficulty: quiz.difficulty,
    totalMarks: quiz.totalMarks.toNumber(),
    testDate: quiz.testDate,
    instructions: quiz.instructions,
    createdBy: quiz.createdBy,
    questions: quiz.questions.map((q) => ({
      id: q.id,
      order: q.order,
      text: q.text,
      type: q.type,
      options: q.options,
      correctIndex: q.correctIndex,
      marks: q.marks.toNumber(),
      gradingKeywords: q.gradingKeywords,
    })),
    createdAt: quiz.createdAt,
    updatedAt: quiz.updatedAt,
  };
}

type TestMarkWithDetails = TestMark & {
  student: { id: string; fullName: string };
  quiz: { id: string; title: string; subject: string; testDate: Date; offeringId: string };
};

/** Never includes quiz questions/answer key — safe for students and parents to read. */
export function toTestMarkResponse(mark: TestMarkWithDetails) {
  return {
    id: mark.id,
    academyId: mark.academyId,
    quiz: { id: mark.quiz.id, title: mark.quiz.title, subject: mark.quiz.subject, testDate: mark.quiz.testDate },
    student: mark.student,
    marksObtained: mark.marksObtained.toNumber(),
    totalMarks: mark.totalMarks.toNumber(),
    percentage: mark.percentage.toNumber(),
    gradeLetter: mark.gradeLetter,
    teacherFeedback: mark.teacherFeedback,
    createdAt: mark.createdAt,
    updatedAt: mark.updatedAt,
  };
}
