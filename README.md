# watch-notify

A **paired iPhone + Apple Watch** reminder app with minute-level scheduling and cross-device sync.

## What it supports

- Configure reminders on **phone or watch**
- Auto-sync reminder list between iPhone and Watch (WatchConnectivity)
- Minute-granularity controls:
  - Frequency (`every N minutes`)
  - Time window start/end (`HH:MM`)
- Day-of-week selection (Sun-Sat)
- Start date + optional end date
- Enable/disable per reminder
- Quick natural-language add for simple inputs

## What “Reschedule Notifications” means

When tapped, the app:
1. Clears currently pending local notifications
2. Recomputes upcoming fire times from your latest rules
3. Schedules the next rolling batch (within iOS/watchOS pending limits)

Use it after edits to immediately apply changes.

## Tech

- SwiftUI (shared UI + logic)
- UserNotifications
- WatchConnectivity sync
- XcodeGen (`project.yml`)

## Targets

- `PhoneNotify` (iOS)
- `WatchNotify` (watchOS)
- Shared logic in `Sources/Shared`

## Setup

```bash
cd /Users/openclaw/git/watch-notify
brew install xcodegen
xcodegen generate
open WatchNotify.xcodeproj
```

## Run (iPhone)

1. Select scheme **PhoneNotify**
2. Set signing team + unique bundle ID
3. Run on iPhone simulator/device
4. Allow notifications

## Run (Apple Watch)

1. Select scheme **WatchNotify**
2. Set signing team + unique bundle ID
3. Run on watch simulator or paired real watch
4. Allow notifications

## Notes

- Keep both apps installed for the best sync experience.
- Local notification pending limits still apply per platform.
