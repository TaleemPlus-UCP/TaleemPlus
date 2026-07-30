-- CreateTable
CREATE TABLE "ocr_documents" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "extracted_text" TEXT NOT NULL,
    "created_by_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ocr_documents_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ocr_documents_created_by_id_idx" ON "ocr_documents"("created_by_id");

-- AddForeignKey
ALTER TABLE "ocr_documents" ADD CONSTRAINT "ocr_documents_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
