import Foundation

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var intervalMinutes: Int
    var startHour: Int?
    var endHour: Int?
    var isEnabled: Bool = true

    var intervalLabel: String {
        if intervalMinutes >= 60, intervalMinutes % 60 == 0 {
            let hours = intervalMinutes / 60
            return hours == 1 ? "Every 1 hour" : "Every \(hours) hours"
        }
        return intervalMinutes == 1 ? "Every 1 minute" : "Every \(intervalMinutes) minutes"
    }

    var windowLabel: String {
        guard let startHour, let endHour else { return "Any time" }
        return "\(formatHour(startHour))–\(formatHour(endHour))"
    }

    var descriptionLine: String {
        "\(intervalLabel) • \(windowLabel)"
    }

    private func formatHour(_ hour: Int) -> String {
        let normalized = ((hour % 24) + 24) % 24
        switch normalized {
        case 0: return "12 AM"
        case 12: return "12 PM"
        case 13...23: return "\(normalized - 12) PM"
        default: return "\(normalized) AM"
        }
    }
}
