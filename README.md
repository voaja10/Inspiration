# Purchase Session Manager (Flutter)

Production-oriented local-first Android Flutter app for:
- purchase sessions (open/closed)
- invoices in RMB with post-delivery corrections
- payments entered in MGA with immutable exchange rate conversion to RMB
- audit logging of critical edits
- compressed photo attachments for invoices and payments
- local backup/restore (database + attachments)
- printable A4 PDF reporting

## Architecture

- `lib/models` domain entities and business rule helpers
- `lib/data` SQLite setup and schema
- `lib/repositories` repository + business logic + audit pipeline
- `lib/services` attachments, backup/restore, PDF generation
- `lib/providers` Riverpod dependency and state providers
- `lib/screens` Android-first UI screens
- `lib/widgets` reusable widgets
- `lib/utils` formatting and utility helpers

## Run

1. Install Flutter SDK (stable) and Android SDK.
2. In this folder run:
   - `flutter pub get`
   - `flutter run`
3. Build release APK:
   - `flutter build apk --release`
   - output: `build/app/outputs/flutter-apk/app-release.apk`

## Core Business Rules Implemented

1. `finalInvoiceAmount = amountInitialRmb + sum(corrections)`
2. `totalInvoices = sum(all final invoice amounts in session)`
3. `totalPayments = sum(all payment amountRmbComputed in session)`
4. `remainingBalance = totalInvoices - totalPayments`
5. Each payment stores and preserves its own `exchangeRate` and `amountRmbComputed`
6. Closed session guard blocks normal financial changes
7. Meaningful data writes are logged in `audit_logs`

## Backup/Restore

- Export creates ZIP with:
  - SQLite database
  - attachments directory tree
- Import validates archive contains required DB file
- Restore writes database and attachments back to app storage

## PDF

- A4 printable layout
- Session header
- Invoice table with correction totals and final RMB
- Payment table with date, MGA, rate, RMB
- Session totals and remaining balance

## Test Cases Included

- invoice no correction
- invoice positive correction
- invoice negative correction
- multiple payments, different exchange rates
- closed session behavior
- remaining balance computation

## Notes

- Flutter tooling is required locally to compile and build APK.
- This codebase is structured to be extended with:
  - advanced form validation
  - richer edit/confirmation flows
  - encrypted backup files
  - role-based protection for closed sessions
