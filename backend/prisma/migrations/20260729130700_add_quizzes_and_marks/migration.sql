-- CreateEnum
CREATE TYPE "QuestionType" AS ENUM ('MCQ', 'SHORT', 'LONG');

-- CreateEnum
CREATE TYPE "QuizDifficulty" AS ENUM ('EASY', 'MEDIUM', 'HARD');

-- CreateTable
CREATE TABLE "quizzes" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "offering_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "session" TEXT,
    "chapter" TEXT,
    "difficulty" "QuizDifficulty" NOT NULL DEFAULT 'MEDIUM',
    "total_marks" DECIMAL(6,2) NOT NULL,
    "test_date" DATE NOT NULL,
    "instructions" TEXT,
    "created_by_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "quizzes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quiz_questions" (
    "id" TEXT NOT NULL,
    "quiz_id" TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "text" TEXT NOT NULL,
    "type" "QuestionType" NOT NULL,
    "options" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "correct_index" INTEGER,
    "marks" DECIMAL(6,2) NOT NULL,
    "grading_keywords" TEXT[] DEFAULT ARRAY[]::TEXT[],

    CONSTRAINT "quiz_questions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "test_marks" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "quiz_id" TEXT NOT NULL,
    "student_id" TEXT NOT NULL,
    "marks_obtained" DECIMAL(6,2) NOT NULL,
    "total_marks" DECIMAL(6,2) NOT NULL,
    "percentage" DECIMAL(5,2) NOT NULL,
    "grade_letter" TEXT NOT NULL,
    "teacher_feedback" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "test_marks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "quizzes_academy_id_idx" ON "quizzes"("academy_id");

-- CreateIndex
CREATE INDEX "quizzes_offering_id_idx" ON "quizzes"("offering_id");

-- CreateIndex
CREATE INDEX "quiz_questions_quiz_id_idx" ON "quiz_questions"("quiz_id");

-- CreateIndex
CREATE INDEX "test_marks_academy_id_idx" ON "test_marks"("academy_id");

-- CreateIndex
CREATE INDEX "test_marks_student_id_idx" ON "test_marks"("student_id");

-- CreateIndex
CREATE UNIQUE INDEX "test_marks_quiz_id_student_id_key" ON "test_marks"("quiz_id", "student_id");

-- AddForeignKey
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_offering_id_fkey" FOREIGN KEY ("offering_id") REFERENCES "class_offerings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quizzes" ADD CONSTRAINT "quizzes_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quiz_questions" ADD CONSTRAINT "quiz_questions_quiz_id_fkey" FOREIGN KEY ("quiz_id") REFERENCES "quizzes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "test_marks" ADD CONSTRAINT "test_marks_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "test_marks" ADD CONSTRAINT "test_marks_quiz_id_fkey" FOREIGN KEY ("quiz_id") REFERENCES "quizzes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "test_marks" ADD CONSTRAINT "test_marks_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
