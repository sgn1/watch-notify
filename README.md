# watch-notify

A lightweight watchOS app to create recurring reminders with custom frequency and optional daily time windows.

Examples:
- `Remind me jap every 15 minutes`
- `Remind me anu lol vilom every 1 hour`
- `Remind me walk every 45 minutes during daytime`

## What it does

- Create reminder rules with:
  - Message text
  - Frequency (e.g., every 15m / 1h)
  - Optional time window (start/end, like daytime)
- Schedules local watch notifications so each reminder vibrates once when fired.
- Includes a quick-add parser for natural phrases.

## Tech

- SwiftUI (watchOS)
- UserNotifications for local scheduling
- `xcodegen` project config (`project.yml`)

## Generate and run

1. Install xcodegen (if needed):
   ```bash
   brew install xcodegen
   ```
2. Generate Xcode project:
   ```bash
   xcodegen generate
   ```
3. Open project:
   ```bash
   open WatchNotify.xcodeproj
   ```
4. Run on Apple Watch simulator or paired device.

## Notes

- iOS/watchOS typically allows up to 64 pending local notifications per app.
- The app schedules a rolling 24-hour window of reminders based on your rules.
- Open the app and tap **Reschedule** after editing reminders.
