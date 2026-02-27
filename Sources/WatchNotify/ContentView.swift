import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @State private var quickAddText: String = ""
    @State private var status: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Add") {
                    TextField("Remind me walk every 45 minutes during daytime", text: $quickAddText)
                        .textInputAutocapitalization(.never)

                    Button("Add Reminder") {
                        addQuickReminder()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Text("Examples: jap every 15m, anu lol vilom every 1h")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Reminders") {
                    if store.reminders.isEmpty {
                        Text("No reminders yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.reminders) { reminder in
                            VStack(alignment: .leading, spacing: 4) {
                                Toggle(isOn: Binding(
                                    get: { reminder.isEnabled },
                                    set: { store.toggle(id: reminder.id, isEnabled: $0) }
                                )) {
                                    Text(reminder.text)
                                        .font(.headline)
                                }

                                Text(reminder.descriptionLine)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete(perform: store.remove)
                    }
                }

                Section {
                    Button("Reschedule Notifications") {
                        Task { await rescheduleNow() }
                    }
                    .buttonStyle(.bordered)
                }

                if !status.isEmpty {
                    Section {
                        Text(status)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Watch Notify")
        }
    }

    private func addQuickReminder() {
        guard let reminder = NaturalLanguageParser.parse(quickAddText) else {
            status = "Could not parse reminder"
            return
        }

        store.add(reminder)
        quickAddText = ""
        status = "Added \"\(reminder.text)\""
    }

    private func rescheduleNow() async {
        do {
            try await NotificationScheduler.requestPermission()
            await NotificationScheduler.reschedule(reminders: store.reminders)
            status = "Rescheduled next 24 hours"
        } catch {
            status = "Notification permission denied"
        }
    }
}
