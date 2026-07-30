import crypto from 'crypto';

/** Human-readable, still-unique challan reference — e.g. `CH-202607-A3F9K2`. Dedup for billing is enforced by the (studentId, billingYear, billingMonth) DB constraint, not by this number. */
export function generateChallanNumber(billingYear: number, billingMonth: number): string {
  const period = `${billingYear}${String(billingMonth).padStart(2, '0')}`;
  const suffix = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `CH-${period}-${suffix}`;
}
