ALTER TABLE "academies"
  ADD COLUMN "paymentQrData" BYTEA,
  ADD COLUMN "paymentQrMimeType" TEXT,
  ADD COLUMN "paymentProvider" TEXT,
  ADD COLUMN "paymentAccountTitle" TEXT,
  ADD COLUMN "paymentAccountDetails" TEXT,
  ADD COLUMN "paymentQrEnabled" BOOLEAN NOT NULL DEFAULT false;

CREATE TYPE "PaymentProofStatus" AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');

CREATE TABLE "fee_payment_proofs" (
  "id" TEXT NOT NULL,
  "academyId" TEXT NOT NULL,
  "challanId" TEXT NOT NULL,
  "submittedById" TEXT NOT NULL,
  "reviewedById" TEXT,
  "imageData" BYTEA NOT NULL,
  "mimeType" TEXT NOT NULL,
  "status" "PaymentProofStatus" NOT NULL DEFAULT 'PENDING',
  "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "reviewedAt" TIMESTAMP(3),
  CONSTRAINT "fee_payment_proofs_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "fee_payment_proofs_academyId_fkey" FOREIGN KEY ("academyId") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "fee_payment_proofs_challanId_fkey" FOREIGN KEY ("challanId") REFERENCES "fee_challans"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "fee_payment_proofs_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "fee_payment_proofs_reviewedById_fkey" FOREIGN KEY ("reviewedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX "fee_payment_proofs_academyId_status_submittedAt_idx"
  ON "fee_payment_proofs"("academyId", "status", "submittedAt");
