# watch-notify

A lightweight **iPhone + Apple Watch** reminder app for recurring prompts with custom frequency and optional time windows.

Examples:
- `Remind me jap every 15 minutes`
- `Remind me anu lol vilom every 1 hour`
- `Remind me walk every 45 minutes during daytime`

## Features

- Configure reminders on **phone or watch**
- Reminder fields:
  - Message text
  - Frequency (minutes/hours)
  - Optional daily window (e.g. daytime)
  - Enabled/disabled state
- Quick-add natural language parser
- Local notification scheduling (rolling next 24 hours)

## Project structure

- `PhoneNotify` (iOS target)
- `WatchNotify` (watchOS target)
- Shared app logic in `Sources/Shared`

## Tech

- SwiftUI
- UserNotifications
- XcodeGen (`project.yml`)

## Setup

```bash
cd /Users/openclaw/git/watch-notify
brew install xcodegen
xcodegen generate
open WatchNotify.xcodeproj
```

## Run on iPhone

1. Select scheme **PhoneNotify**
2. Set signing in **Signing & Capabilities**:
   - Team: your Apple ID team
   - Unique bundle ID (example: `com.suraj.phonenotify`)
3. Choose iPhone simulator or physical iPhone
4. Run
5. Allow notifications, then tap **Reschedule Notifications**

## Run on Apple Watch

1. Select scheme **WatchNotify**
2. Set signing in **Signing & Capabilities**:
   - Team: your Apple ID team
   - Unique bundle ID (example: `com.suraj.watchnotify`)
3. Choose paired Apple Watch (or watch simulator)
4. Run
5. Allow notifications, then tap **Reschedule Notifications**

> If you see "requires a development team", signing is not configured yet.

## Notes

- iOS/watchOS typically allow up to 64 pending local notifications per app.
- Reminders are currently local to each app target (phone and watch each keep their own saved reminders).
- Next enhancement: sync reminders between phone and watch via WatchConnectivity + shared model.
