/**
 * Seeds the Firestore emulator or a real dev project with sample
 * students and flags, so the team has realistic data to build against
 * without hand-typing it into the console.
 *
 * NOTE: this does NOT create matching Firebase Auth accounts or
 * users/{uid} profiles — those come from actually signing up through
 * the app's Signup screen. Sign up as a teacher first, then edit
 * TEACHER_UID/TEACHER_NAME below to match, before running this.
 *
 * Setup:
 *   npm install firebase-admin
 *
 * Run against a real project:
 *   1. Download a service account key from
 *      Firebase Console > Project Settings > Service Accounts
 *   2. GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json node scripts/seed_firestore.js
 *
 * Run against the local emulator instead (safer for repeated testing):
 *   firebase emulators:start --only firestore
 *   FIRESTORE_EMULATOR_HOST=localhost:8080 node scripts/seed_firestore.js
 */

const admin = require('firebase-admin');

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  admin.initializeApp({ credential: admin.credential.applicationDefault() });
} else {
  admin.initializeApp({ projectId: 'ijisho-dev' });
}

const db = admin.firestore();

// Replace with a real signed-up teacher's uid + name (see note above).
const TEACHER_UID = 'REPLACE_WITH_REAL_TEACHER_UID';
const TEACHER_NAME = 'Musoni Godfrey';

const students = [
  { fullName: 'Habimana Jean Paul', gradeSection: 'Grade 10 - Science A' },
  { fullName: 'Mutesi Alice', gradeSection: 'Grade 9 - Basic' },
  { fullName: 'Mugisha Jean', gradeSection: 'Grade 10 - Science A' },
  { fullName: 'Uwera Marie', gradeSection: 'Grade 10 - Science Section (S4)' },
  { fullName: 'Iradukunda Divine', gradeSection: 'Senior 6 - HEG' },
  { fullName: 'Nshuti Kevin', gradeSection: 'Grade 9 - Basic' },
];

const flags = [
  {
    studentName: 'Uwera Marie',
    gradeSection: 'Grade 10 - Science Section (S4)',
    category: 'financial',
    severity: 'urgent',
    status: 'reported',
    note: 'Student has missed three consecutive tuition payments. Parents unavailable by phone.',
    flagCountThisTerm: 3,
  },
  {
    studentName: 'Mugisha Jean',
    gradeSection: 'Grade 10 - Science A',
    category: 'attendance',
    severity: 'urgent',
    status: 'underReview',
    note: 'Attended only 2 out of 5 days this week. Previous record of high attendance.',
    flagCountThisTerm: 2,
  },
  {
    studentName: 'Iradukunda Divine',
    gradeSection: 'Senior 6 - HEG',
    category: 'behavioral',
    severity: 'warning',
    status: 'resolved',
    note: 'Student showing signs of extreme fatigue and withdrawal during morning lectures.',
    flagCountThisTerm: 1,
  },
  {
    studentName: 'Habimana Jean Paul',
    gradeSection: 'Grade 10 - Science A',
    category: 'absent',
    severity: 'warning',
    status: 'reported',
    note: '',
    flagCountThisTerm: 1,
  },
  {
    studentName: 'Mutesi Alice',
    gradeSection: 'Grade 9 - Basic',
    category: 'struggling',
    severity: 'fine',
    status: 'reported',
    note: '',
    flagCountThisTerm: 1,
  },
];

async function seed() {
  const batch = db.batch();

  for (const student of students) {
    const ref = db.collection('students').doc();
    batch.set(ref, student);
  }

  const now = Date.now();
  flags.forEach((flag, i) => {
    const ref = db.collection('flags').doc();
    batch.set(ref, {
      ...flag,
      teacherUid: TEACHER_UID,
      teacherName: TEACHER_NAME,
      // stagger timestamps so ordering looks realistic
      createdAt: admin.firestore.Timestamp.fromMillis(now - i * 86400000),
    });
  });

  await batch.commit();
  console.log(`Seeded ${students.length} students and ${flags.length} flags.`);
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
