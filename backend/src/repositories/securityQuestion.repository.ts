import { prisma } from '../config/database';

export const securityQuestionRepository = {
  upsert(userId: string, question: string, answerHash: string) {
    return prisma.securityQuestion.upsert({
      where: { userId },
      create: { userId, question, answerHash },
      update: { question, answerHash },
    });
  },

  findByUserId(userId: string) {
    return prisma.securityQuestion.findUnique({ where: { userId } });
  },
};
