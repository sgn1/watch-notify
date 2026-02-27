import Foundation

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var intervalMinutes: Int
    var startHour: Int?
    var endHour: Int?
    var isEnabled: Bool = true

    var descriptionLine: String {
        let interval = intervalMinutes >= 60 && intervalMinutes % 60 == 0
            ? "every \(intervalMinutes / 60)h"
            : "every \(intervalMinutes)m"

        if let startHour, let endHour {
            return "\(text) • \(interval) • \(startHour):00-\(endHour):00"
        }
        return "\(text) • \(interval)"
    }
}
