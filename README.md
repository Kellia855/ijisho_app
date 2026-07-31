# IJISHO Mobile Application

IJISHO is a Flutter mobile app that helps Rwandan schools identify and support students at risk of dropping out. Teachers flag student concerns in real time; principals review cases, assign interventions and track outcomes through an analytics dashboard — all backed by Firebase.

---

## Features

### Teacher Portal
- Log student issues across four categories: Absent, No Uniform, No Lunch, Struggling in Class
- Set urgency level (Urgent / Warning / Fine) per flag
- View personal flagging history with search and category filters
- Browse the full student roster with photos

### Principal Portal
- Live dashboard of all flags school-wide, with severity badges
- Case details view showing flag history per student
- Assign interventions (counselling, fee waiver, etc)
- Mark cases as resolved
- Analytics screen: dropout risk pie chart, issue breakdown by category, at-risk counts

### Both Roles
- Email/password sign-in and Google Sign-In
- Role-aware routing — teachers and principals land on their own dashboard automatically after login
- Profile screen with photo upload to Firebase Storage
- Student profile screen showing full flag history for any individual student
- Partial Kinyarwanda / English toggle (role select, dashboards, nav)
- School-scoped data isolation - each school only sees its own students and flags

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3 / Dart 3.11 |
| State management | Riverpod 3 (family providers for school-scoped streams) |
| Auth | Firebase Auth — email/password + Google Sign-In |
| Database | Cloud Firestore |
| File storage | Firebase Storage |
| Charts | fl_chart |
| Fonts / Icons | Google Fonts, Font Awesome Flutter |
| Image picking | image_picker |

---

## Getting Started

### Prerequisites

Before you begin, make sure you have the following installed:

- **Flutter SDK** (3.x or later) — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** 3.11+ (comes bundled with Flutter)
- **Android Studio** or **VS Code** with the Flutter and Dart plugins
- **Git**
- **Node.js** (v18+) and **npm** — needed for the Firebase CLI and seed script
- **A Firebase account** — [console.firebase.google.com](https://console.firebase.google.com)

Verify your Flutter setup:
```bash
flutter doctor
```
All checkmarks should be green before continuing.

---

### 1. Clone the repository

```bash
git clone https://github.com/Kellia855/ijisho_app.git
cd ijisho_app
```

---

### 2. Install Flutter dependencies

```bash
flutter pub get
```

---

### 3. Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and click **Add project**
2. Give it a name (e.g. `ijisho-dev`) and follow the setup wizard
3. Inside the project, enable the following services:

**Authentication**
- Go to **Build → Authentication → Get started**
- Enable **Email/Password** under Sign-in providers
- Enable **Google** under Sign-in providers (you'll need a support email)

**Firestore Database**
- Go to **Build → Firestore Database → Create database**
- Start in **production mode** (the rules in this repo will handle access)
- Choose a region close to Rwanda (e.g. `europe-west1`)

**Storage**
- Go to **Build → Storage → Get started**
- Start in **production mode**
- Use the same region as Firestore

---

### 4. Connect Firebase to the app

Install the FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

Run the configuration command from the project root:
```bash
flutterfire configure
```

- Select the Firebase project you just created
- Select the platforms you want to support (Android, iOS, etc.)

This generates `lib/firebase_options.dart` with your project's credentials. This file is gitignored — **never commit it**.

For Android, also make sure `android/app/google-services.json` is present (FlutterFire places it automatically). This file is also gitignored.

---

### 5. Install the Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

Link the project folder to your Firebase project:
```bash
firebase use --add
```
Pick the same project you used in step 3.

---

### 6. Deploy Firestore rules and indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

This deploys:
- `firestore.rules` — security rules that enforce teacher/principal access boundaries
- `firestore.indexes.json` — composite indexes required for school-scoped queries

> Indexes take a few minutes to finish building in the Firebase console after deploying. Queries will fail with a "requires an index" error until they're ready.

Deploy Storage rules separately:
```bash
firebase deploy --only storage
```

---

### 7. Seed sample data (optional but recommended)

The seed script creates sample students and flags so you have real data to work with during development.

Install the admin SDK:
```bash
npm install firebase-admin
```

**Option A — Local emulator (recommended, won't touch real data):**
```bash
firebase emulators:start --only firestore
FIRESTORE_EMULATOR_HOST=localhost:8080 node scripts/seed_firestore.js
```

**Option B — Real dev project:**
- Go to Firebase Console → Project Settings → Service Accounts → Generate new private key
- Save the file as `serviceAccountKey.json` in the project root (it's gitignored)
```bash
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json node scripts/seed_firestore.js
```

> Sign up as a teacher in the app first, then paste that account's UID into `TEACHER_UID` at the top of `scripts/seed_firestore.js` — the seeded flags need a real `teacherUid` to satisfy the security rules.

---

### 8. Run the app

```bash
flutter run
```

For a specific device:
```bash
flutter run -d <device-id>
```

List available devices:
```bash
flutter devices
```

---

### Building a release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Install directly to a connected device:
```bash
flutter install --release
```

---

## Project Structure

```
lib/
  main.dart                          # Firebase init, ProviderScope, MaterialApp
  firebase_options.dart              # generated by flutterfire configure (gitignored)
  theme/
    app_theme.dart                   # brand colors, shared ThemeData
  models/
    app_user.dart                    # AppUser, UserRole
    flag.dart                        # StudentFlag, FlagCategory/Severity/Status
    student.dart                     # Student
  services/
    auth_service.dart                # Firebase Auth + Firestore user profiles
    flag_service.dart                # Firestore CRUD for flags and students
    storage_service.dart             # Firebase Storage photo uploads
  providers/
    service_providers.dart           # AuthService / FlagService providers
    stream_providers.dart            # studentsStreamProvider / allFlagsStreamProvider (family)
    language_provider.dart           # Kinyarwanda / English toggle
  localization/
    app_strings.dart                 # translated strings
  widgets/
    app_bottom_nav.dart              # shared bottom nav bar
    pill_badge.dart                  # URGENT / WARNING / FINE, REPORTED / etc.
  screens/
    role_select_screen.dart          # entry point — pick Teacher or Principal
    login_screen.dart                # email + Google sign-in
    signup_screen.dart               # create account with role-specific fields
    google_role_picker_screen.dart   # role + school picker for new Google users
    teacher/
      teacher_home_screen.dart       # teacher dashboard
      flagging_history_screen.dart   # full flag history with search/filter
      log_issue_sheet.dart           # bottom sheet to submit a flag
    principal/
      principal_home_screen.dart     # principal dashboard
      case_details_screen.dart       # single flag detail + intervention picker
      select_intervention_screen.dart
      intervention_screen.dart       # intervention management list
      analytics_screen.dart          # charts and stats
    common/
      students_screen.dart           # full student roster
      student_profile_screen.dart    # per-student flag history
      add_student_screen.dart        # add a new student (principal only)
      profile_screen.dart            # user profile + photo upload
```

---

## Data Model

### `users/{uid}`
```json
{
  "fullName": "Musoni Godfrey",
  "email": "godfrey@school.rw",
  "role": "teacher",
  "employeeId": "TCH-2024-001",
  "schoolName": "GS Kacyiru",
  "photoUrl": "https://..."
}
```
`role` is written once at signup and cannot be changed by the user (enforced by Firestore rules).

### `students/{id}`
```json
{
  "fullName": "Habimana Jean Paul",
  "gradeSection": "Grade 10 - Science A",
  "schoolName": "GS Kacyiru",
  "photoUrl": "https://..."
}
```

### `flags/{id}`
```json
{
  "studentName": "Habimana Jean Paul",
  "gradeSection": "Grade 10 - Science A",
  "category": "absent",
  "severity": "warning",
  "status": "reported",
  "note": "Missed three afternoon sessions this week.",
  "teacherName": "Musoni Godfrey",
  "teacherUid": "abc123",
  "schoolName": "GS Kacyiru",
  "createdAt": "<timestamp>",
  "flagCountThisTerm": 1,
  "interventionType": "Fee Waiver",
  "studentPhotoUrl": "https://..."
}
```

**Category values:** `absent` | `noUniform` | `noLunch` | `struggling` | `financial` | `academic` | `attendance` | `behavioral`  
**Severity values:** `urgent` | `warning` | `fine`  
**Status values:** `reported` → `underReview` → `resolved`

---

## Firestore Security Rules Summary

| Collection | Read | Write |
|---|---|---|
| `users/{uid}` | Any signed-in user | Owner only; `role` is immutable after signup |
| `students/{id}` | Any signed-in user | Principals only |
| `flags/{id}` | Any signed-in user | Teachers create (own `teacherUid`, `status: reported`); principals update `status` and `interventionType` only |

---

## Platform Notes

### Android
- `android:enableOnBackInvokedCallback="true"` is set in `AndroidManifest.xml` to silence predictive-back warnings.
- Gallery access works out of the box on modern Android via scoped storage. For API < 33 you may need `READ_EXTERNAL_STORAGE` in the manifest.

### iOS
- Add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist` for gallery access.

---

## Known Limitations

| Area | Status |
|---|---|
| Kinyarwanda coverage | Role select, dashboards, and nav are translated. Login/signup, case details, analytics still English only — extend by adding entries to `lib/localization/app_strings.dart` |
| `flagCountThisTerm` | Always `1` on creation — no logic yet to increment it when the same student is flagged again in the same term |
| Student photo on flags | Denormalized at flag-creation time — if a student's photo changes later, older flags keep the old photo |
| Profile photo live update | New photo shows on the Profile screen immediately but other screens need a logout/login to reflect it |
| Attendance Trend / Geographic Distribution | Use placeholder data on the Analytics screen — needs an attendance-taking feature before real data can flow in |
| Class scoping | All teachers see the full student roster — add a `classId` to `Student` and the teacher profile to scope each teacher to their own class |
| Offline support | Explicitly out of scope for now |

---

## Running Tests

```bash
flutter test
```

The widget test renders `RoleSelectScreen` in isolation (no Firebase init required) wrapped in `ProviderScope`.

---

## Contributors

**Kellia Kamikazi**
**Oriane Uwineza**
**Emanuele Shema**
**Aurore Umumararungu**
**Kudakwashe Chikovo**
