import Foundation

enum NaturalLanguageParser {
    static func parse(_ input: String) -> Reminder? {
        let lowered = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard lowered.contains("remind me") else { return nil }

        let withoutPrefix = lowered.replacingOccurrences(of: "remind me", with: "").trimmingCharacters(in: .whitespaces)

        // Split around "every"
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

        var startHour: Int?
        var endHour: Int?

        if rest.contains("daytime") {
            startHour = 8
            endHour = 20
        }

        guard !message.isEmpty, intervalMinutes > 0 else { return nil }
        return Reminder(text: message, intervalMinutes: intervalMinutes, startHour: startHour, endHour: endHour)
    }
}
