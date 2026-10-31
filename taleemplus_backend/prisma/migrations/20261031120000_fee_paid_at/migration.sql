-- Add an explicit payment timestamp for auditable, leakage-safe fee labels.
-- Existing paid challans intentionally keep NULL because updatedAt is not a
-- reliable substitute for their actual payment date.
ALTER TABLE "fee_challans" ADD COLUMN "paidAt" TIMESTAMP(3);
