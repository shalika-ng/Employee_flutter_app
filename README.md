# attendence_employee

A new Flutter project.

## Holiday calendar

The Calendar tab loads the signed-in employee's monthly calendar from
`GET /employees/me/calendar?month=<month>&year=<year>` using the configured
API base URL. It displays common and employee holidays, pending leave, and
attendance status for the selected day. Use the month arrows to browse and
tap a date or holiday to see its details.

## Payslips

The Payslip tab loads published statements from `GET /payroll/payslips/me`
and allows filtering by calendar year or searching by month and slip ID.
View PDF displays the authenticated PDF in the app, while Save PDF opens
the platform's save dialog. Both use `GET /payroll/payslips/me/:id/download`.
The API does not provide
salary amounts or deduction details in the list response.
Configure an HTTPS API base URL before using real employee credentials or
payslips; the current local HTTP address does not encrypt this sensitive data.
After adding the native PDF and save plugins, rebuild and relaunch the application;
hot reload alone does not register native plugins.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
