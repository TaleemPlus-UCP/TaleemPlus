ALTER TABLE "users" ADD COLUMN "studentCode" TEXT;

-- Existing records receive a deterministic opaque code; account IDs and other
-- historical relationships remain unchanged.
UPDATE "users"
SET "studentCode" = lower(substr(md5("id"), 1, 16))
WHERE "role" = 'STUDENT';

CREATE UNIQUE INDEX "users_studentCode_key" ON "users"("studentCode");
