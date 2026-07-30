/*
  Warnings:

  - You are about to drop the column `salt` on the `security_questions` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "security_questions" DROP COLUMN "salt";
