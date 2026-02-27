import Foundation

final class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = [] {
        didSet { save() }
    }

    private let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("reminders.json")
    }()

    init() {
        load()
    }

    func add(_ reminder: Reminder) {
        reminders.append(reminder)
    }

    func remove(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
    }

    private func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            reminders = try JSONDecoder().decode([Reminder].self, from: data)
        } catch {
            reminders = [
                Reminder(text: "jap", intervalMinutes: 15, startHour: nil, endHour: nil),
                Reminder(text: "anu lol vilom", intervalMinutes: 60, startHour: nil, endHour: nil),
                Reminder(text: "walk", intervalMinutes: 45, startHour: 8, endHour: 20)
            ]
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(reminders)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Failed to save reminders: \(error)")
        }
    }
}
