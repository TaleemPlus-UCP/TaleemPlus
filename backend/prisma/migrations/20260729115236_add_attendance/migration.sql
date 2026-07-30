-- CreateEnum
CREATE TYPE "AttendanceStatus" AS ENUM ('PRESENT', 'ABSENT', 'LATE');

-- CreateTable
CREATE TABLE "attendance_records" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "offering_id" TEXT NOT NULL,
    "student_id" TEXT NOT NULL,
    "log_date" DATE NOT NULL,
    "status" "AttendanceStatus" NOT NULL,
    "marked_by_id" TEXT,
    "recorded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "attendance_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "attendance_records_academy_id_idx" ON "attendance_records"("academy_id");

-- CreateIndex
CREATE INDEX "attendance_records_student_id_log_date_idx" ON "attendance_records"("student_id", "log_date");

-- CreateIndex
CREATE INDEX "attendance_records_offering_id_log_date_idx" ON "attendance_records"("offering_id", "log_date");

-- CreateIndex
CREATE UNIQUE INDEX "attendance_records_offering_id_student_id_log_date_key" ON "attendance_records"("offering_id", "student_id", "log_date");

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_offering_id_fkey" FOREIGN KEY ("offering_id") REFERENCES "class_offerings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "attendance_records" ADD CONSTRAINT "attendance_records_marked_by_id_fkey" FOREIGN KEY ("marked_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
