import Foundation

@MainActor
final class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = [] {
        didSet {
            guard !applyingRemoteUpdate else { return }
            save()
            sync.onSend(reminders: reminders)
        }
    }

    private var sync: AnyReminderSync
    private var applyingRemoteUpdate = false

    private let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("reminders.json")
    }()

    init() {
        self.sync = AnyReminderSync(ReminderSyncService.shared)
        load()
        self.sync.onReceive = { [weak self] incoming in
            self?.applyIncoming(incoming)
        }
        self.sync.start()
        self.sync.onSend(reminders: reminders)
    }

    func add(_ reminder: Reminder) {
        reminders.append(reminder)
    }

    func update(_ reminder: Reminder) {
        guard let idx = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[idx] = reminder
    }

    func remove(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
    }

    func toggle(id: UUID, isEnabled: Bool) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].isEnabled = isEnabled
    }

    private func applyIncoming(_ incoming: [Reminder]) {
        guard incoming != reminders else { return }
        applyingRemoteUpdate = true
        reminders = incoming
        applyingRemoteUpdate = false
        save()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            reminders = try JSONDecoder().decode([Reminder].self, from: data)
        } catch {
            let start = Calendar.current.startOfDay(for: Date())
            reminders = [
                Reminder(text: "jap", intervalMinutes: 15, windowStartMinute: nil, windowEndMinute: nil, weekdays: Set(1...7), startDate: start, endDate: nil),
                Reminder(text: "anu lol vilom", intervalMinutes: 60, windowStartMinute: nil, windowEndMinute: nil, weekdays: Set(1...7), startDate: start, endDate: nil),
                Reminder(text: "walk", intervalMinutes: 45, windowStartMinute: 8 * 60, windowEndMinute: 20 * 60, weekdays: Set(2...6), startDate: start, endDate: nil)
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

@MainActor
struct AnyReminderSync {
    var onReceive: (([Reminder]) -> Void)? {
        didSet { base.onReceive = onReceive }
    }

    private var base: ReminderSyncing

    init(_ base: ReminderSyncing) {
        self.base = base
    }

    func start() { base.start() }
    func onSend(reminders: [Reminder]) { base.push(reminders: reminders) }
}
