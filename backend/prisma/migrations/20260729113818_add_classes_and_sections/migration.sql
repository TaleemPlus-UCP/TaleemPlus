-- CreateTable
CREATE TABLE "class_sections" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "class_name" TEXT NOT NULL,
    "section_label" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "class_sections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "section_enrollments" (
    "id" TEXT NOT NULL,
    "section_id" TEXT NOT NULL,
    "student_id" TEXT NOT NULL,
    "enrolled_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "section_enrollments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "class_offerings" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "section_id" TEXT NOT NULL,
    "subject" TEXT NOT NULL DEFAULT '',
    "teacher_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "class_offerings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "class_sections_academy_id_idx" ON "class_sections"("academy_id");

-- CreateIndex
CREATE UNIQUE INDEX "class_sections_academy_id_class_name_section_label_key" ON "class_sections"("academy_id", "class_name", "section_label");

-- CreateIndex
CREATE INDEX "section_enrollments_student_id_idx" ON "section_enrollments"("student_id");

-- CreateIndex
CREATE UNIQUE INDEX "section_enrollments_section_id_student_id_key" ON "section_enrollments"("section_id", "student_id");

-- CreateIndex
CREATE INDEX "class_offerings_academy_id_idx" ON "class_offerings"("academy_id");

-- CreateIndex
CREATE INDEX "class_offerings_teacher_id_idx" ON "class_offerings"("teacher_id");

-- CreateIndex
CREATE UNIQUE INDEX "class_offerings_section_id_subject_key" ON "class_offerings"("section_id", "subject");

-- AddForeignKey
ALTER TABLE "class_sections" ADD CONSTRAINT "class_sections_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "section_enrollments" ADD CONSTRAINT "section_enrollments_section_id_fkey" FOREIGN KEY ("section_id") REFERENCES "class_sections"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "section_enrollments" ADD CONSTRAINT "section_enrollments_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "class_offerings" ADD CONSTRAINT "class_offerings_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "class_offerings" ADD CONSTRAINT "class_offerings_section_id_fkey" FOREIGN KEY ("section_id") REFERENCES "class_sections"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "class_offerings" ADD CONSTRAINT "class_offerings_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
