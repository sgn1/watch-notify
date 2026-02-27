import Foundation

enum NaturalLanguageParser {
    static func parse(_ input: String) -> Reminder? {
        let lowered = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard lowered.contains("remind me") else { return nil }

        let withoutPrefix = lowered.replacingOccurrences(of: "remind me", with: "").trimmingCharacters(in: .whitespaces)
        let parts = withoutPrefix.components(separatedBy: " every ")
        guard parts.count >= 2 else { return nil }

        let message = parts[0].trimmingCharacters(in: .whitespaces)
        let rest = parts[1]

        let intervalMinutes: Int
        if let match = rest.range(of: #"(\d+)\s*(minute|minutes|min|m)"#, options: .regularExpression) {
            let token = String(rest[match])
            intervalMinutes = Int(token.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
        } else if let match = rest.range(of: #"(\d+)\s*(hour|hours|hr|h)"#, options: .regularExpression) {
            let token = String(rest[match])
            intervalMinutes = (Int(token.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0) * 60
        } else {
            return nil
        }

        var startMinute: Int?
        var endMinute: Int?
        if rest.contains("daytime") {
            startMinute = 8 * 60
            endMinute = 20 * 60
        }

        guard !message.isEmpty, intervalMinutes > 0 else { return nil }
        return Reminder(
            text: message,
            intervalMinutes: intervalMinutes,
            windowStartMinute: startMinute,
            windowEndMinute: endMinute,
            weekdays: Set(1...7),
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: nil,
            isEnabled: true
        )
    }
}
