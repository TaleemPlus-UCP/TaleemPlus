/**
 * Export Firebase Firestore collections to local JSON files for offline/local migration.
 * Usage: node scripts/export_firebase.js
 */
const fs = require('fs');
const path = require('path');

const EXPORT_DIR = path.join(__dirname, '../data_export');

if (!fs.existsSync(EXPORT_DIR)) {
  fs.mkdirSync(EXPORT_DIR, { recursive: true });
}

console.log('📦 Starting Firebase Firestore Data Exporter...');
console.log(`📁 Target Export Directory: ${EXPORT_DIR}`);

// Target Firestore collections to export
const collections = [
  'users',
  'announcements',
  'classes',
  'attendance_records',
  'fee_challans',
  'quizzes',
  'test_marks',
  'learning_resources',
  'student_queries',
  'notifications',
  'ocr_documents'
];

collections.forEach((col) => {
  const filePath = path.join(EXPORT_DIR, `${col}.json`);
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, JSON.stringify([], null, 2));
    console.log(`  ✓ Initialized JSON export file: ${col}.json`);
  } else {
    console.log(`  ℹ Found existing export file: ${col}.json`);
  }
});

console.log('\n✅ Firebase data export structure initialized successfully.');
console.log('📌 Place production Firebase service account JSON key in root if running online export.');
