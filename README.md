# RemindMe

RemindMe is an Android-first reminder app. Reminder data is stored locally in SQLite; there is no account, backend, analytics SDK, or network permission in the Android manifest.

## Upload from Termux to GitHub

Create an empty GitHub repository, then extract this ZIP in Termux and run these commands from the `remindme_app` project folder:

```sh
pkg install git unzip
unzip remindme_project_fixed.zip
cd remindme_app
git init
git add .
git commit -m "Initial RemindMe project"
git branch -M main
git remote add origin https://github.com/USERNAME/REPOSITORY.git
git push -u origin main
```

Replace `USERNAME/REPOSITORY` with the empty repository you created.

## Build an APK with GitHub Actions

1. Push this project to a GitHub repository on `main` or `master`.
2. Open **Actions → Build APK**. The workflow also supports **Run workflow**.
3. Wait for the workflow to finish successfully, open its run, then download the `remindme-release-apks` artifact.
4. Install `app-arm64-v8a-release.apk` on most current Android phones. `app-armeabi-v7a-release.apk` is for 32-bit ARM devices; `app-release.apk` is the universal APK.

The workflow runs localization and Drift code generation, `flutter analyze`, `flutter test`, then builds both universal and split APKs. Analyze/test failures stop the build instead of being ignored.

## Local build

Use Flutter stable **3.50.0** (Dart 3.14), Java 17 and Android SDK command-line/build tools. From the project root:

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --release
```

The Android `release` build currently uses the debug signing configuration as a convenience, so the APK installs for testing. Before publishing, create a private upload keystore and replace `signingConfigs.debug` in `android/app/build.gradle` with a release signing config. Store keystore passwords and the keystore file in GitHub Secrets / secure CI files; never commit them. Example keystore creation:

```sh
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## Test alarms on a real phone

1. Grant notification permission during onboarding.
2. Allow **Alarms & reminders** / exact alarms in Android app settings. On Android 14+, also allow full-screen notifications where the system exposes that option.
3. For reliable delivery, set RemindMe to unrestricted / not optimized in battery settings. On Xiaomi, Oppo, Vivo, Huawei and some Samsung devices, check the vendor's Auto-start / background activity controls too; the exact menu names vary by model and OS version.
4. Create a reminder 2–3 minutes ahead, lock the phone, and test both a normal notification and a full-screen alarm. Repeat after reboot and after changing the device time zone.

Android vendors can still delay or block alarms when they apply aggressive battery restrictions. Exact-alarm and full-screen access are controlled by Android and the user; the app cannot silently grant them.

## Project structure

- `lib/core/` — app routing, theme, constants and utilities
- `lib/data/` — Drift database, DAOs and repositories
- `lib/domain/` — entities, pure-Dart recurrence calculations and alarm orchestration
- `lib/features/` — home, editor, calendar, categories, settings, onboarding, alarm ring and backup
- `lib/widgets/` — shared UI pieces
- `lib/l10n/` — English and Bangla ARB source files (generated Dart localization files are created in CI)
- `android/` — Kotlin AlarmManager, receivers, foreground sound service and lock-screen activity
- `.github/workflows/` — GitHub Actions Android build

## Current scope and limitations

This is a repaired early implementation, not a complete match for every item in the original product brief. It includes local reminders, category data, recurrence fields/calculation, native alarm scheduling, reboot/time-zone restoration, basic notification/full-screen actions, JSON/CSV export and JSON import. The editor and settings expose only part of the stored model. Voice recording, attachment capture/management, PIN/biometric app lock, quiet hours, active-time-window enforcement, full filter/bulk/trash workflows, click sounds and complete Bangla UI translation are not implemented. The shake challenge is currently a multi-tap confirmation, not accelerometer-based shake detection. JSON backup includes categories, reminder metadata and attachment paths, but it does not bundle the referenced media files. Inter-font and Hind Siliguri font files are not bundled, so system fonts are used.

The project targets the Flutter 3.50 stable Android baseline (minimum SDK 24). API 23 was not forced because it is below this stable toolchain's default Android minimum. Cached alarms are restored after a timezone change, but this implementation retains their absolute timestamps; preserving the same local wall-clock time while travelling across time zones is not guaranteed. Test the generated APK on physical devices before release.

The main, debug and profile Android manifests contain no `INTERNET` permission. The app has no network client or backend.
