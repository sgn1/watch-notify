import Foundation
import UserNotifications

enum NotificationScheduler {
    static func requestPermission() async throws {
        _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func reschedule(reminders: [Reminder], quietMode: QuietModeSettings) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let horizon = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now.addingTimeInterval(7 * 24 * 3600)

        var requests: [UNNotificationRequest] = []
        for reminder in reminders where reminder.isEnabled {
            let fireDates = nextFireDates(for: reminder, from: now, until: horizon, maxCount: 80, quietMode: quietMode)
            for fireDate in fireDates {
                let content = UNMutableNotificationContent()
                content.title = "Watch Notify"
                content.body = reminder.text
                content.sound = .default

                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let id = "\(reminder.id.uuidString)-\(Int(fireDate.timeIntervalSince1970))"
                requests.append(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }

        for req in requests.sorted(by: { $0.identifier < $1.identifier }).prefix(64) {
            do {
                try await center.add(req)
            } catch {
                print("Failed adding notification \(req.identifier): \(error)")
            }
        }
    }

    private static func nextFireDates(for reminder: Reminder, from start: Date, until end: Date, maxCount: Int, quietMode: QuietModeSettings) -> [Date] {
        guard reminder.intervalMinutes > 0 else { return [] }
        let interval = TimeInterval(reminder.intervalMinutes * 60)
        let cal = Calendar.current

        let effectiveStart = max(start, reminder.startDate)
        var date = alignedDate(from: effectiveStart, anchor: reminder.startDate, intervalMinutes: reminder.intervalMinutes)

        var output: [Date] = []
        while date <= end, output.count < maxCount {
            if let endDate = reminder.endDate, date > endDate { break }
            if isAllowed(date: date, reminder: reminder, calendar: cal, quietMode: quietMode) {
                output.append(date)
            }
            date = date.addingTimeInterval(interval)
        }
        return output
    }

    private static func alignedDate(from candidate: Date, anchor: Date, intervalMinutes: Int) -> Date {
        let diff = candidate.timeIntervalSince(anchor)
        if diff <= 0 { return anchor }
        let step = Double(intervalMinutes * 60)
        let hops = ceil(diff / step)
        return anchor.addingTimeInterval(hops * step)
    }

    private static func isAllowed(date: Date, reminder: Reminder, calendar: Calendar, quietMode: QuietModeSettings) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        guard reminder.weekdays.contains(weekday) else { return false }

        if quietMode.isEnabled {
            if quietMode.pauseOnWeekends, weekday == 1 || weekday == 7 { return false }
            let comps = calendar.dateComponents([.hour, .minute], from: date)
            let minute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            if minuteInsideWindow(minute, start: quietMode.quietStartMinute, end: quietMode.quietEndMinute) {
                return false
            }
        }

        guard let startMinute = reminder.windowStartMinute, let endMinute = reminder.windowEndMinute else {
            return true
        }

        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return minuteInsideWindow(minute, start: startMinute, end: endMinute)
    }

    private static func minuteInsideWindow(_ minute: Int, start: Int, end: Int) -> Bool {
        if start <= end {
            return minute >= start && minute <= end
        } else {
            return minute >= start || minute <= end
        }
    }
}
