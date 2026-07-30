-- CreateTable
CREATE TABLE "learning_resources" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "offering_id" TEXT NOT NULL,
    "teacher_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "link_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "learning_resources_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "student_queries" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "offering_id" TEXT NOT NULL,
    "student_id" TEXT NOT NULL,
    "teacher_id" TEXT NOT NULL,
    "question" TEXT NOT NULL,
    "answer" TEXT,
    "is_resolved" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "answered_at" TIMESTAMP(3),

    CONSTRAINT "student_queries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "learning_resources_academy_id_idx" ON "learning_resources"("academy_id");

-- CreateIndex
CREATE INDEX "learning_resources_offering_id_idx" ON "learning_resources"("offering_id");

-- CreateIndex
CREATE INDEX "student_queries_academy_id_idx" ON "student_queries"("academy_id");

-- CreateIndex
CREATE INDEX "student_queries_offering_id_idx" ON "student_queries"("offering_id");

-- AddForeignKey
ALTER TABLE "learning_resources" ADD CONSTRAINT "learning_resources_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "learning_resources" ADD CONSTRAINT "learning_resources_offering_id_fkey" FOREIGN KEY ("offering_id") REFERENCES "class_offerings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "learning_resources" ADD CONSTRAINT "learning_resources_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_queries" ADD CONSTRAINT "student_queries_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_queries" ADD CONSTRAINT "student_queries_offering_id_fkey" FOREIGN KEY ("offering_id") REFERENCES "class_offerings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_queries" ADD CONSTRAINT "student_queries_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_queries" ADD CONSTRAINT "student_queries_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
