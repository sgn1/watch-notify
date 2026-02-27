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

## Install on Apple Watch (real device)

1. Install Xcode + XcodeGen:
   ```bash
   xcode-select --install
   brew install xcodegen
   ```
2. Generate and open the project:
   ```bash
   xcodegen generate
   open WatchNotify.xcodeproj
   ```
3. In Xcode, set signing:
   - Select target **WatchNotify** → **Signing & Capabilities**
   - Choose your Apple ID team under **Team**
   - Keep bundle identifier unique (e.g. `com.suraj.watchnotify`)
4. Pair your iPhone + Apple Watch and enable **Developer Mode** on the watch.
5. In Xcode toolbar, choose your **Apple Watch** as run destination and press **Run**.
6. On first launch, allow Notifications, then tap **Reschedule Notifications**.

> If build fails with “requires a development team,” signing is not configured yet (Step 3).

## Simulator run (optional)

1. `xcodegen generate`
2. `open WatchNotify.xcodeproj`
3. Select a watchOS simulator destination
4. Run, then test quick-add and reschedule flow

## Notes

- iOS/watchOS typically allows up to 64 pending local notifications per app.
- The app schedules a rolling 24-hour window of reminders based on your rules.
- Open the app and tap **Reschedule** after editing reminders.
