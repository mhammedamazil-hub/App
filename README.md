# TaskFlow — an advanced to-do list app

TaskFlow is a full-featured, offline-first to-do list built with **Flutter/Dart**.
It ships with **zero third-party dependencies**: persistence is implemented with
`dart:io` on desktop/mobile and browser `localStorage` on the web, so it builds
and runs even without network access.

## Features

- **Smart lists** — Inbox, Today, Upcoming (14 days), Overdue, Completed, All tasks
- **Projects** with custom colors and icons, per-project progress and counts
- **Kanban board** per project (To Do / In Progress / Done) with drag & drop
- **Subtasks** with live progress chips
- **Priorities** (none/low/medium/high), **tags**, **pinning**
- **Due dates & times** with relative labels and overdue highlighting
- **Repeating tasks** — daily, weekdays, weekly, monthly, yearly (next occurrence
  is spawned automatically when you complete the task)
- **Reminders** — in-app banner when a reminder fires while the app is open
- **Swipe actions** — swipe right to complete, swipe left to delete (undoable)
- **Search** across titles, notes and tags (Ctrl+K)
- **Stats dashboard** — completion rate, day streak, 7-day chart, per-project and
  per-priority breakdowns
- **Undo** for deletes, imports and clears
- **Backup & restore** — JSON export/import (file on desktop, download/upload on
  web, clipboard on mobile)
- **Light / dark / system theme** with 8 accent colors (Material 3)
- **Keyboard shortcuts** — `Ctrl+N` new task, `Ctrl+K` search, `Esc` clear search
- Fully **responsive** — sidebar on wide screens, drawer + bottom bar on phones

## Getting started

Requires the Flutter SDK (3.27 or newer, tested with 3.35).

```bash
flutter pub get
flutter run            # pick a device: chrome, linux, macos, windows, android…
```

Platform notes:

- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` scaffolding is
  included. If your local Flutter version differs a lot, run
  `flutter create .` once to refresh platform files (your `lib/` code is
  untouched).
- Storage location per platform:
  - Android/iOS: app documents directory (`taskflow_data.json`) via a small
    platform channel in `MainActivity.kt` / `AppDelegate.swift`
  - Linux: `$XDG_DATA_HOME/taskflow/` or `~/.local/share/taskflow/`
  - macOS: `~/Library/Application Support/taskflow/`
  - Windows: `%APPDATA%/taskflow/`
  - Web: browser `localStorage`

## Tests

```bash
flutter test
```

Unit tests cover model serialization, repeat scheduling (including end-of-month
and leap-day edge cases), overdue logic, queries, streaks, undo, import/export
and persistence.

## Optional: build & publish a web preview

`tool/github-pages-workflow.yml` is a ready-made GitHub Actions workflow that
runs `flutter analyze`, `flutter test` and `flutter build web --release`, then
publishes the build to the `gh-pages` branch. To enable it, copy the file to
`.github/workflows/build-web.yml` in this repository (GitHub requires workflow
files to be added by a human account). You can then host the app with GitHub
Pages (build with `flutter build web --base-href "/App/"` if your repo is
served from a sub-path).

## Project layout

```
lib/
  main.dart                     app entry, theming
  theme.dart                    Material 3 themes, accent seeds
  models/
    task.dart                   Task, Subtask, priorities, repeat logic
    project.dart                Project
    settings.dart               theme/accent preferences
    app_state.dart              state, persistence, undo, queries, stats
  services/
    storage*.dart               storage abstraction (io / web)
    backup*.dart                export/import (file / download / clipboard)
  utils/                        dates & id helpers
  widgets/                      sidebar, task tiles, badges, banners, charts
  screens/                      shell, views, editor, kanban, settings, stats
test/                           unit tests
```

## 📱 Download the Android app (APK)

Every push to this repository automatically builds the Android app and
publishes the APKs as a GitHub Release:

- **Release page:** https://github.com/mhammedamazil-hub/App/releases/latest
- **Universal APK (works on any phone):**
  https://github.com/mhammedamazil-hub/App/releases/latest/download/taskflow-universal.apk
- **Modern phones (arm64):**
  https://github.com/mhammedamazil-hub/App/releases/latest/download/taskflow-arm64-v8a.apk

To install: open the downloaded APK on your Android phone and allow
"install from unknown sources" when prompted.

The build pipeline (`tool/build-apk-workflow.yml`) runs the unit tests, then
builds universal + per-ABI release APKs and attaches them to a rolling
`latest` release. The APK is signed with the Flutter debug key — perfect for
sideloading; for the Play Store you would add your own signing keystore.
