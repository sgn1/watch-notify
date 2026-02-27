import Foundation

private struct PersistedState: Codable {
    var reminders: [Reminder]
    var quietMode: QuietModeSettings
}

@MainActor
final class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = [] {
        didSet { publishChangesIfNeeded() }
    }

    @Published var quietMode: QuietModeSettings = .default {
        didSet { publishChangesIfNeeded() }
    }

    private var sync: AnyReminderSync
    private var applyingRemoteUpdate = false
    private var lastModifiedAt: Date = .distantPast

    private let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("app-state.json")
    }()

    init() {
        self.sync = AnyReminderSync(ReminderSyncService.shared)
        load()
        self.sync.onReceive = { [weak self] envelope in
            self?.applyIncoming(envelope)
        }
        self.sync.start()
        self.sync.onSend(envelope: ReminderSyncEnvelope(modifiedAt: lastModifiedAt, reminders: reminders, quietMode: quietMode))
    }

    func add(_ reminder: Reminder) { reminders.append(reminder) }

    func addTemplate(_ template: ReminderTemplate) {
        reminders.append(template.toReminder())
    }

    func update(_ reminder: Reminder) {
        guard let idx = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[idx] = reminder
    }

    func remove(at offsets: IndexSet) { reminders.remove(atOffsets: offsets) }

    func toggle(id: UUID, isEnabled: Bool) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].isEnabled = isEnabled
    }

    private func publishChangesIfNeeded() {
        guard !applyingRemoteUpdate else { return }
        lastModifiedAt = Date()
        save()
        sync.onSend(envelope: ReminderSyncEnvelope(modifiedAt: lastModifiedAt, reminders: reminders, quietMode: quietMode))
    }

    private func applyIncoming(_ incoming: ReminderSyncEnvelope) {
        guard incoming.modifiedAt > lastModifiedAt else { return }
        guard incoming.reminders != reminders || incoming.quietMode != quietMode else { return }
        applyingRemoteUpdate = true
        reminders = incoming.reminders
        quietMode = incoming.quietMode
        applyingRemoteUpdate = false
        lastModifiedAt = incoming.modifiedAt
        save()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            let state = try JSONDecoder().decode(PersistedState.self, from: data)
            reminders = state.reminders
            quietMode = state.quietMode
            lastModifiedAt = Date()
            return
        } catch {
            // migration fallback
            if let oldData = try? Data(contentsOf: saveURL.deletingLastPathComponent().appendingPathComponent("reminders.json")),
               let oldReminders = try? JSONDecoder().decode([Reminder].self, from: oldData) {
                reminders = oldReminders
                quietMode = .default
                lastModifiedAt = Date()
                return
            }
        }

        let start = Calendar.current.startOfDay(for: Date())
        reminders = [
            Reminder(text: "jap", intervalMinutes: 15, windowStartMinute: nil, windowEndMinute: nil, weekdays: Set(1...7), startDate: start, endDate: nil),
            Reminder(text: "anu lol vilom", intervalMinutes: 60, windowStartMinute: nil, windowEndMinute: nil, weekdays: Set(1...7), startDate: start, endDate: nil),
            Reminder(text: "walk", intervalMinutes: 45, windowStartMinute: 8 * 60, windowEndMinute: 20 * 60, weekdays: Set(2...6), startDate: start, endDate: nil)
        ]
        quietMode = .default
        lastModifiedAt = Date()
    }

    private func save() {
        do {
            let state = PersistedState(reminders: reminders, quietMode: quietMode)
            let data = try JSONEncoder().encode(state)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Failed to save state: \(error)")
        }
    }
}

@MainActor
struct AnyReminderSync {
    var onReceive: ((ReminderSyncEnvelope) -> Void)? {
        didSet { base.onReceive = onReceive }
    }

    private var base: ReminderSyncing

    init(_ base: ReminderSyncing) {
        self.base = base
    }

    func start() { base.start() }
    func onSend(envelope: ReminderSyncEnvelope) { base.push(envelope: envelope) }
}
