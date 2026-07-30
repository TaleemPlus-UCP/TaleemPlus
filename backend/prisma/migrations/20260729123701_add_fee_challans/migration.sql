-- CreateEnum
CREATE TYPE "FeeChallanStatus" AS ENUM ('PENDING', 'PAID', 'OVERDUE');

-- CreateTable
CREATE TABLE "fee_challans" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "challan_number" TEXT NOT NULL,
    "student_id" TEXT NOT NULL,
    "class_label_snapshot" TEXT NOT NULL,
    "billing_year" INTEGER NOT NULL,
    "billing_month" INTEGER NOT NULL,
    "issue_date" DATE NOT NULL,
    "due_date" DATE NOT NULL,
    "monthly_fee" DECIMAL(10,2) NOT NULL,
    "admission_fee" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "exam_fee" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "transport_fee" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "fine" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "status" "FeeChallanStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "fee_challans_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "fee_challans_challan_number_key" ON "fee_challans"("challan_number");

-- CreateIndex
CREATE INDEX "fee_challans_academy_id_idx" ON "fee_challans"("academy_id");

-- CreateIndex
CREATE INDEX "fee_challans_student_id_idx" ON "fee_challans"("student_id");

-- CreateIndex
CREATE UNIQUE INDEX "fee_challans_student_id_billing_year_billing_month_key" ON "fee_challans"("student_id", "billing_year", "billing_month");

-- AddForeignKey
ALTER TABLE "fee_challans" ADD CONSTRAINT "fee_challans_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fee_challans" ADD CONSTRAINT "fee_challans_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
