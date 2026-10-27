# SkillBridge

**Show it. Prove it. Grow it.**

A Flutter app that connects skilled Zambian workers (welders, tailors,
carpenters, plumbers, hairdressers and more) with clients who need their
services. Workers show their skills, prove them with reviews, badges and
certification guidance, and grow their reputation by winning work.

## Status

- `flutter analyze` — **no issues**
- `flutter test` — **28 tests, all passing**
- `flutter build apk` — **debug and release builds succeed**
- Exercised on an Android 17 (API 37) x86_64 emulator: onboarding, role
  selection, registration/sign in, demo mode, client and worker dashboards,
  search, profiles, jobs, bookings, messaging, quizzes and badges.

## Requirements

- Flutter 3.24 or newer (Dart 3.5 or newer, see `pubspec.yaml`)
- Android SDK and an emulator or phone (Android is the delivery target)

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Flutter's `.gitignore` keeps the Gradle wrapper out of version control. If a
fresh clone cannot sync in Android Studio, restore the platform files once:

```bash
flutter create --platforms=android --project-name skillbridge .
```

The command only recreates missing platform files; it does not change `lib/`.

## What the app does

Two experiences in one app, chosen at role selection and switchable in
**Profile → Demo role**:

### Client

- Dashboard with search, promo carousel, 12 trade categories, workers near the
  selected town, recently viewed workers, own job posts and suggested
  professionals.
- Browse trades and search with text plus filters (trade, town, availability,
  minimum rating, verified only, maximum price) and five sort modes.
- Public worker profiles: about, skills, portfolio, reviews and rating
  distribution, with self-declared skills kept visibly apart from badges and
  verified history.
- Favourites, service requests that become bookings, booking status tracking.
- Post a job (3 steps), review applicants, accept/decline, track jobs and
  bookings in active/pending/completed/cancelled buckets.
- Messaging with per-role unread counts, and reviews gated to completed jobs or
  bookings (one review per job).

### Worker

- Six-step profile wizard: personal details, trade and skills, location,
  portfolio, availability and pricing, preview. Drafts are saved on every step.
- Dashboard with profile completion, availability toggle, rating, reviews,
  badges, recommended jobs, client enquiries and recent activity.
- Find jobs, apply or withdraw, and track work in My Work.
- Portfolio manager with real photos from the gallery (copied into app storage).
- Five competency quizzes; scoring 80% or more earns a quiz badge (eight badges
  in total, including experience, portfolio and review milestones).
- Certification guidance: the TEVETA website plus questions to ask providers.
  Badges are labelled as app achievements, never as formal qualifications.

### Both

- Local accounts with a salted SHA-256 password hash; passwords themselves are
  never stored or sent.
- Everything persists on the device: profiles, portfolio, favourites, jobs,
  applications, bookings, messages, reviews, quiz attempts and settings.
- Offline banner when the phone reports no network, and an explicit "saved on
  this device only" change list. Nothing claims to have been synchronised.

## Demo data

"Continue as demo" opens fictional sample data:

| Role   | Name          | Sample content                                                   |
| ------ | ------------- | ---------------------------------------------------------------- |
| Worker | David Mwamba  | Plumbing profile, portfolio, 24 historic reviews, 4 badges, jobs, enquiries |
| Client | Natasha Phiri | Posted jobs, two applications, bookings in each state, messages, notifications |

All sample people, phone numbers and reviews are fictional. Data is seeded once
and stable ids mean relaunching never duplicates it.

## Architecture

```
lib/
  main.dart, app.dart
  core/        palette and design tokens, routing (GoRouter), validators, format helpers, shared widgets
  models/      typed models with JSON (de)serialisation
  data/
    demo/      fictional seed data with stable ids
    content/   quiz questions and certification content
    local/     LocalStore (SharedPreferences) and MediaStore (photos)
    repositories/  auth, search and sync interfaces, plus pure business rules
  state/       Riverpod AppController: the single place that changes and saves data
  features/    one folder per area; widgets read state and call the controller
```

- **State:** Riverpod `NotifierProvider`. Every change is written to local
  storage straight away.
- **Routing:** GoRouter with named routes and a `StatefulShellRoute` for the five
  bottom tabs. The middle tabs depend on role (Browse / Post Job for clients,
  Find Jobs / My Work for workers).
- **Replaceable services:** `AuthRepository`, `WorkerSearchRepository`,
  `SyncService`, `LocalStore`, `MediaStore`. Swap a provider override to plug in
  a backend.
- **Business rules** (ratings, badges, booking transitions, quiz scoring, search)
  are plain Dart in `data/repositories/rules.dart` and are unit tested.
- **Authentication:** `DemoAuthRepository` stores a salted SHA-256 hash of the
  password and checks it at sign in. Demo accounts bypass the password.

## Theme and branding

The brand uses a deep navy (`#0B2447`) with an amber accent (`#F2A93B`) and
Plus Jakarta Sans, applied through `lib/core/app_theme.dart`.

App icons and the native splash are generated from `assets/branding/`, which is
rendered from the in-app `BrandLogo` widget so everything stays consistent:

```bash
flutter test tool/generate_branding.dart   # render assets/branding/*.png
dart run flutter_launcher_icons            # app icons
dart run flutter_native_splash:create      # native splash screens
```

## Tests

```bash
flutter test
```

- `test/rules_test.dart` — phone parsing, quiz integrity and scoring, badge
  rules, booking transitions, seed integrity, search, filters and sorting.
- `test/state_test.dart` — seeding without duplicates, job → application →
  review flow, duplicate blocking, quiz badges, persistence across launches,
  duplicate accounts, password hashing and verification, clearing data.
- `test/widget_test.dart` — validators, splash → onboarding, and the demo client
  reaching the dashboard.

## Trust rules built into the app

- No profile shows an official credential. Seeded workers have none.
- Profiles keep four things visibly apart: self-declared skills, SkillBridge
  quiz badges, verified work history (demo data) and official qualifications.
- Quiz badges are app achievements, never certificates. Questions are original
  and are not TEVETA material.
- The only external link is the TEVETA website. Other resource links are
  intentionally unset placeholders.
- Reviews require a completed job or booking with that worker, and only one
  review per job is allowed.

## Known limitations

- **No backend.** No real marketplace, multi-device messaging, push
  notifications, payments or SMS. Jobs, requests and messages exist only on the
  phone that created them.
- **Prototype authentication.** Accounts and password hashes are local to the
  device. There is no server-side validation, session expiry or account
  recovery.
- **Storage.** SharedPreferences holds all structured data. That is fine at
  prototype size; a larger version should move to Hive, Isar or SQLite.
- **No local notification reminders.** In-app notifications only.
- **Share** copies a profile summary to the clipboard (no share-sheet package).
- **Video:** workers can attach a link or note to a project. Playback and
  recording are not implemented.
- **Distance:** only town-level matching is available. No distances are invented.
- **Platforms:** Android is the delivery target. iOS/web/desktop folders exist
  from the original scaffold, but photo storage uses `dart:io`.
- Demo phone numbers are fictional.

## Future backend integration points

- `AuthRepository` for secure sign in and sessions.
- `WorkerSearchRepository` for server-side search.
- `SyncService` and the `pending` change list for synchronisation.
- `MediaStore` for protected cloud storage of photos.
- Messaging: replace the conversation methods in `AppController` with a
  WebSocket client.
- Production needs access control, server-side validation, abuse reporting and a
  real privacy policy.

## Project sections

The app was built as a five-part team brief:

| Section | Scope                                                     | Status      |
| ------- | --------------------------------------------------------- | ----------- |
| 1       | App entry, onboarding, authentication, session handover    | Complete    |
| 2       | Worker and client dashboards                               | Complete    |
| 3       | Worker discovery, profiles and portfolio                   | Complete    |
| 4       | Jobs, bookings and communication                           | Complete    |
| 5       | Skills verification, certification and final integration   | Complete    |

Section 1 established `AppUser`, `UserRole`, `WorkerProfile`, validation and
branding. The later sections added the seeded marketplace, discovery, jobs,
bookings, messaging, reviews, quizzes, badges and certification guidance, then
integrated them behind one state controller.
