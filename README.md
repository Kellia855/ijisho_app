# IJISHO  Flutter App

This covers the full flow from the Figma prototype: **role select → login
→ signup → teacher dashboard → flagging history → principal dashboard →
case details → select intervention → analytics**, wired to Firebase Auth
+ Firestore, matching the original colors (blue role-select, green
Teacher portal, purple Principal portal, plus the red/orange/yellow/purple
issue-category colors).

## What's included

```
firebase.json                              # Firebase CLI config
firestore.rules                            # security rules (teacher/principal only)
firestore.indexes.json                     # composite index for flag history query
scripts/seed_firestore.js                  # sample data seed script
lib/
  main.dart                                # entry point, Firebase init
  firebase_options.dart                    # PLACEHOLDER — see setup below
  theme/app_theme.dart                     # brand + category colors, shared styling
  models/
    app_user.dart                          # AppUser, UserRole
    flag.dart                              # StudentFlag, FlagCategory/Severity/Status
    student.dart                           # Student (for the Select Student dropdown)
  services/
    auth_service.dart                      # Firebase Auth + Firestore user profile
    flag_service.dart                      # Firestore reads/writes for flags & students
  widgets/
    app_bottom_nav.dart                    # shared Dashboard/Students/Intervention/Profile bar
    pill_badge.dart                        # URGENT/WARNING/FINE, REPORTED/etc. badges
  screens/
    role_select_screen.dart                # Image 1
    login_screen.dart                      # Login as Teacher / Principal
    signup_screen.dart                     # Create account, role-specific fields
    teacher/
      teacher_home_screen.dart             # Image 5  dashboard
      flagging_history_screen.dart         # Image 4  history + search/filter
      log_issue_sheet.dart                 # bottom sheet to submit a flag
    principal/
      principal_home_screen.dart           # Image 6  dashboard
      case_details_screen.dart             # Image 7
      select_intervention_screen.dart      # Image 8
      analytics_screen.dart                # Image 9/10/11  charts (fl_chart)
    common/
      profile_screen.dart                  # placeholder  not designed yet
      students_placeholder_screen.dart     # placeholder  not designed yet
```

## What's real vs. sample data

- **Real, backed by Firestore:** signup/login, the whole flagging loop
  (teacher submits → appears on principal dashboard → case details →
  select intervention writes back), Flagging History, Dropout Risk pie,
  Issue Breakdown, and the Total/At Risk/Urgent stat counts.
- **Sample data (clearly labeled in the UI):** Attendance Trend and
  Geographic Distribution on the Analytics screen there's no
  attendance-taking feature built yet, so these use placeholder numbers
  until that data pipeline exists.

## Setup

1. **Get Flutter running** (skip if already set up):
   ```
   flutter doctor
   ```

2. **Create a Firebase project** at https://console.firebase.google.com
   - Enable **Authentication → Email/Password**
   - Create a **Firestore Database** (start in test mode for now)

3. **Install the FlutterFire CLI and connect your app:**
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This replaces the placeholder `lib/firebase_options.dart` with your
   real project's config for each platform you target.

4. **Install dependencies:**
   ```
   flutter pub get
   ```

5. **Run it:**
   ```
   flutter run
   ```

## Data model

**`users/{uid}`** written on signup:

```json
{
  "fullName": "Musoni Godfrey",
  "email": "godfrey.musoni@school.rw",
  "role": "teacher",           // or "principal"
  "employeeId": "TCH-2024-001" // teacher only
  // "schoolName": "..."        // principal only
}
```

`AuthService.signIn`: reads this doc after Firebase Auth succeeds, so the
app knows which dashboard to route to without a separate role-selection
step at login.

**`students/{id}`**: seed manually in the Firestore console for now,
there's no "add student" screen in the current designs:

```json
{ "fullName": "Habimana Jean Paul", "gradeSection": "Grade 10 - Science A" }
```

**`flags/{id}`**: created when a teacher submits the Log Student Issue
sheet, updated when a principal assigns an intervention:

```json
{
  "studentName": "Habimana Jean Paul",
  "gradeSection": "Grade 10 - Science A",
  "category": "absent",           // absent | noUniform | noLunch | struggling | financial | academic | attendance | behavioral
  "severity": "warning",          // urgent | warning | fine  set to "urgent" manually for now, see below
  "status": "reported",           // reported | underReview | resolved
  "note": "Missed three afternoon sessions...",
  "teacherName": "Musoni Godfrey",
  "teacherUid": "abc123",
  "createdAt": "<timestamp>",
  "flagCountThisTerm": 1,
  "interventionType": "Fee Waiver" // set once a principal picks one
}
```

**Note on severity:** the Log Student Issue sheet now includes a
"How urgent is this?" picker (Urgent/Warning/Fine), defaulting to
Warning. `flagCountThisTerm` is still always `1` on creation though
nothing increments it yet if the same student gets flagged again, so
the "3rd flag this term" repeat-count feature on Case Details won't
reflect reality until that's added.

## Photo uploads (profile + student photos)

Both the Profile screen and Add Student screen now let you tap a photo
circle to pick an image from the gallery and upload it to Firebase
Storage. A few things to know:

- **Deploy `storage.rules` too**, not just Firestore's:
  ```
  firebase deploy --only storage
  ```
  (You'll also need Storage enabled in the console **Build → Storage
  → Get started**  if you haven't used it before.)
- **Platform permissions** `image_picker` needs gallery-access
  permission declared natively:
  - **iOS**: add `NSPhotoLibraryUsageDescription` to `ios/Runner/Info.plist`
  - **Android**: usually works out of the box on modern Android via
    scoped storage, but if you target older API levels you may need
    `READ_MEDIA_IMAGES` (API 33+) or `READ_EXTERNAL_STORAGE` in
    `android/app/src/main/AndroidManifest.xml`
- **Known limitation:** when you update your own profile photo, the
  Profile screen shows it immediately, but other screens (Teacher
  Dashboard's welcome card, dashboard lists) were built with the
  `AppUser` object from login/signup time and won't show the new photo
  until you log out and back in. A proper fix means lifting `AppUser`
  into shared app state (e.g. re-fetching it after any update) rather
  than passing a static copy screen-to-screen — worth doing if this
  becomes annoying.
- Flags **denormalize** the student's photo at the moment they're
  created (`studentPhotoUrl` on `StudentFlag`) rather than looking it up
  live each time simpler, but it means if a student's photo changes
  later, flags created before that change keep showing the old one.

## Firestore setup (rules, indexes, seed data)

This repo includes real Firestore config, not just a data-model sketch:

```
firebase.json              # points the Firebase CLI at the two files below
firestore.rules            # security rules — teacher/principal only, see below
firestore.indexes.json     # composite index the teacher history query needs
scripts/seed_firestore.js  # sample students + flags for development
```

**1. Install the Firebase CLI** (if you don't have it):
```
npm install -g firebase-tools
firebase login
```

**2. Link this folder to your Firebase project:**
```
firebase use --add
```
Pick the same project you ran `flutterfire configure` against.

**3. Deploy the rules and indexes:**
```
firebase deploy --only firestore:rules,firestore:indexes
```
Indexes can take a few minutes to build in the console after deploying.

**4. What the rules enforce** (`firestore.rules`):
- `users/{uid}` : anyone signed in can read (needed to check role after
  login); a user can only create/update their own doc, and can't change
  their `role` after signup.
- `students/{id}` : any signed-in staff member can read; only principals
  can write (there's no student-management screen yet, so seed this
  collection yourself for now).
- `flags/{id}` : any signed-in staff member can read; teachers can only
  create flags with their own `teacherUid` and `status: "reported"`;
  only principals can update, and only the `status`/`interventionType`
  fields so a principal can't silently rewrite a teacher's observation.

**5. Seed sample data** so the team isn't building against an empty
database:
```
npm install firebase-admin
```
Then either against the local emulator (recommended for repeated testing,
since it won't touch real data):
```
firebase emulators:start --only firestore
FIRESTORE_EMULATOR_HOST=localhost:8080 node scripts/seed_firestore.js
```
or against your real dev project, using a service account key from
Firebase Console → Project Settings → Service Accounts:
```
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json node scripts/seed_firestore.js
```
Sign up as a teacher in the app first and paste that account's uid into
`TEACHER_UID` at the top of the script  the seeded flags need a real
`teacherUid` to satisfy the security rules and show up correctly.

## Not yet built

- **Full Kinyarwanda coverage**: the translate icon on Role Select,
  Teacher Dashboard, and Flagging History now actually works and covers
  the most-visible strings (nav labels, headers, buttons). Less-visible
  screens (Case Details, Select Intervention, Analytics, Login/Signup
  body text) still show English only extending coverage is just
  adding entries to `lib/localization/app_strings.dart` and wrapping
  more screens' `build()` in the same `ValueListenableBuilder<AppLanguage>`
  pattern already used elsewhere.
- **Attendance-taking feature**:  needed before Attendance Trend and
  Geographic Distribution on Analytics can use real data instead of
  samples
- **Offline support**:  explicitly out of scope for now
- **Class assignments**: Students tab currently shows the same full
  roster to every teacher and principal; if you want teachers scoped to
  just their own class, that needs a `classId` (or similar) added to
  both `Student` and the teacher's profile, plus a query filter
