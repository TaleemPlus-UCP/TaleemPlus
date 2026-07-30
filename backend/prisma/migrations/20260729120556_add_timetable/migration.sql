-- CreateTable
CREATE TABLE "timetable_slots" (
    "id" TEXT NOT NULL,
    "academy_id" TEXT NOT NULL,
    "is_break" BOOLEAN NOT NULL DEFAULT false,
    "offering_id" TEXT,
    "day_of_week" INTEGER NOT NULL,
    "start_minutes" INTEGER NOT NULL,
    "end_minutes" INTEGER NOT NULL,
    "room" TEXT,
    "semester" TEXT,
    "effective_from" DATE NOT NULL,
    "effective_to" DATE,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "timetable_slots_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "timetable_slots_academy_id_idx" ON "timetable_slots"("academy_id");

-- CreateIndex
CREATE INDEX "timetable_slots_offering_id_idx" ON "timetable_slots"("offering_id");

-- CreateIndex
CREATE INDEX "timetable_slots_academy_id_day_of_week_idx" ON "timetable_slots"("academy_id", "day_of_week");

-- AddForeignKey
ALTER TABLE "timetable_slots" ADD CONSTRAINT "timetable_slots_academy_id_fkey" FOREIGN KEY ("academy_id") REFERENCES "academies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "timetable_slots" ADD CONSTRAINT "timetable_slots_offering_id_fkey" FOREIGN KEY ("offering_id") REFERENCES "class_offerings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
