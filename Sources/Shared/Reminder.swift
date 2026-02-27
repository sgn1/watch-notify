import Foundation

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var intervalMinutes: Int
    var windowStartMinute: Int?
    var windowEndMinute: Int?
    var weekdays: Set<Int> = Set(1...7) // 1=Sun ... 7=Sat
    var startDate: Date
    var endDate: Date?
    var isEnabled: Bool = true

    var intervalLabel: String {
        intervalMinutes == 1 ? "Every minute" : "Every \(intervalMinutes) minutes"
    }

    var windowLabel: String {
        guard let windowStartMinute, let windowEndMinute else { return "Any time" }
        return "\(formatMinute(windowStartMinute))–\(formatMinute(windowEndMinute))"
    }

    var weekdayLabel: String {
        if weekdays.count == 7 { return "Every day" }
        let symbols = Calendar.current.shortWeekdaySymbols
        let ordered = weekdays.sorted().map { symbols[max(0, min(6, $0 - 1))] }
        return ordered.joined(separator: ", ")
    }

    var dateRangeLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        if let endDate {
            return "\(f.string(from: startDate)) → \(f.string(from: endDate))"
        }
        return "Starts \(f.string(from: startDate))"
    }

    var descriptionLine: String {
        "\(intervalLabel) • \(windowLabel) • \(weekdayLabel)"
    }

    private func formatMinute(_ total: Int) -> String {
        let h = ((total / 60) % 24 + 24) % 24
        let m = ((total % 60) + 60) % 60
        var comps = DateComponents()
        comps.hour = h
        comps.minute = m
        let date = Calendar.current.date(from: comps) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct QuietModeSettings: Codable, Equatable {
    var isEnabled: Bool = false
    var quietStartMinute: Int = 22 * 60
    var quietEndMinute: Int = 7 * 60
    var pauseOnWeekends: Bool = false

    static let `default` = QuietModeSettings()
}

struct ReminderTemplate: Identifiable {
    var id: String { name }
    let name: String
    let intervalMinutes: Int
    let text: String
    let startMinute: Int?
    let endMinute: Int?
    let weekdays: Set<Int>

    func toReminder() -> Reminder {
        Reminder(
            text: text,
            intervalMinutes: intervalMinutes,
            windowStartMinute: startMinute,
            windowEndMinute: endMinute,
            weekdays: weekdays,
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: nil,
            isEnabled: true
        )
    }

    static let defaults: [ReminderTemplate] = [
        ReminderTemplate(name: "🧘 Breath", intervalMinutes: 60, text: "Anulom Vilom", startMinute: 6 * 60, endMinute: 21 * 60, weekdays: Set(1...7)),
        ReminderTemplate(name: "🚶 Walk", intervalMinutes: 45, text: "Walk break", startMinute: 8 * 60, endMinute: 20 * 60, weekdays: Set(2...6)),
        ReminderTemplate(name: "💧 Hydrate", intervalMinutes: 30, text: "Drink water", startMinute: 8 * 60, endMinute: 22 * 60, weekdays: Set(1...7)),
        ReminderTemplate(name: "🧍 Posture", intervalMinutes: 50, text: "Check posture", startMinute: 9 * 60, endMinute: 18 * 60, weekdays: Set(2...6))
    ]
}
