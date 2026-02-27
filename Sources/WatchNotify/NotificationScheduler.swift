import Foundation
import UserNotifications

enum NotificationScheduler {
    static func requestPermission() async throws {
        _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func reschedule(reminders: [Reminder]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(24 * 3600)

        var requests: [UNNotificationRequest] = []

        for reminder in reminders where reminder.isEnabled {
            let fireDates = nextFireDates(for: reminder, from: now, until: end)
            for fireDate in fireDates.prefix(20) {
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

        for req in requests.prefix(64) {
            do {
                try await center.add(req)
            } catch {
                print("Failed adding notification \(req.identifier): \(error)")
            }
        }
    }

    private static func nextFireDates(for reminder: Reminder, from start: Date, until end: Date) -> [Date] {
        guard reminder.intervalMinutes > 0 else { return [] }
        let interval = TimeInterval(reminder.intervalMinutes * 60)

        var date = start
        var output: [Date] = []

        while date < end {
            date = date.addingTimeInterval(interval)
            if isWithinWindow(date: date, reminder: reminder) {
                output.append(date)
            }
        }

        return output
    }

    private static func isWithinWindow(date: Date, reminder: Reminder) -> Bool {
        guard let startHour = reminder.startHour, let endHour = reminder.endHour else {
            return true
        }

        let hour = Calendar.current.component(.hour, from: date)
        if startHour <= endHour {
            return hour >= startHour && hour < endHour
        }
        return hour >= startHour || hour < endHour
    }
}
