ALTER TABLE "fee_challans" ADD COLUMN "billingPeriod" TEXT;

CREATE UNIQUE INDEX "fee_challans_academyId_studentId_billingPeriod_key"
  ON "fee_challans"("academyId", "studentId", "billingPeriod");
