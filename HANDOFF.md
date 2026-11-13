# RemindMe — engineering handoff

## Audit repairs made

- Corrected alarm cancellation so the PendingIntent action/identity matches the one used when scheduling; cancellation removes cached schedule entries and associated notifications.
- Persisted scheduled payloads and restore them after boot, package replacement, manual time changes and time-zone changes.
- Repaired monthly scheduling for dates such as the 29th–31st, last-day-of-month and Nth-weekday calculations; interval repeats use elapsed milliseconds.
- Added independent snooze scheduling for repeating reminders, normalized reminder notification-ID groups, enforced the configured snooze limit and avoided advancing the same repeating occurrence twice when a snoozed alarm is skipped.
- Queued every native occurrence and reconciled fired-count / next-fire state back into Drift. Native notification actions are consumed when the app resumes as well as on cold start.
- Reset snooze count on a new regular repeating occurrence and preserve a final scheduled snooze even when the repeat rule has no later regular occurrence.
- Replaced permission-screen placeholders with native checks/settings intents for notifications, exact alarms, full-screen access and battery optimization.
- Implemented validated JSON import/export and CSV export; JSON backup now exports/imports category and reminder metadata; import accepts the current versioned envelope and early plain-list backups.
- Pinned direct package versions, aligned Gradle / Kotlin / Java settings, added build-time code generation and made analyze/tests blocking CI steps.

## Build and verification

- Flutter stable 3.50.0 / Dart 3.14; Java 17; Gradle 8.13; Android Gradle Plugin 8.13.2; Kotlin Gradle plugin 2.2.20.
- Run `flutter pub get`, `flutter gen-l10n`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`, then `flutter build apk --release`.
- Drift and localization generated files are intentionally not committed; the workflow generates them before analysis/build.
- The authoring environment did not contain Flutter or Dart executables, so `flutter analyze`, `flutter test` and an APK build could not be executed here. Tests cover recurrence, occurrence generation and entity JSON serialization only; editor widget tests and automated Android scheduler tests are still missing. XML, path/import references and project configuration were checked statically; Android device behaviour remains unverified.

## Known product gaps

- The current UI is an MVP subset. Several database fields do not yet have complete editor controls or user flows.
- No voice-note recording, media attachment manager, PIN/biometric lock, quiet hours, active-window enforcement, DND bypass, full-screen brand setup wizard, click sounds, all requested filters/bulk actions, or full Bangla localization.
- The challenge value labelled as shake uses three taps; true accelerometer shake handling is not present.
- Backup includes category/reminder metadata and attachment paths but not the media file bytes.
- System fonts are used; Inter and Hind Siliguri files are not included.
- Minimum SDK follows Flutter 3.50's API 24 baseline rather than API 23.
- Timezone-change receivers restore cached absolute timestamps; they do not yet recalculate every alarm from its original local wall-clock rule after travelling to another timezone. DST and OEM alarm behaviour still require physical-device verification.
- Database schema is currently version 1; the upgrade hook is ready but there are no historical migrations yet.

## Recommended next verification on device

Install the CI APK, create both one-shot and daily/monthly repeating alarms, try Done/Snooze/Skip from notification and lock screen, kill the app, reboot, change the time zone, and confirm that snooze counts and repeat end conditions remain correct. Repeat on Xiaomi/Oppo/Vivo/Samsung devices with vendor battery controls both enabled and disabled.
