import SwiftUI

private enum CalmTheme {
    static let top = Color(red: 0.90, green: 0.96, blue: 0.98)
    static let mid = Color(red: 0.85, green: 0.92, blue: 0.95)
    static let bottom = Color(red: 0.81, green: 0.89, blue: 0.93)
    static let accent = Color(red: 0.23, green: 0.52, blue: 0.67)
}

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @State private var quickAddText: String = ""
    @State private var status: String = ""
    @State private var showingNewReminder = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [CalmTheme.top, CalmTheme.mid, CalmTheme.bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Form {
                    Section {
                        ForEach(ReminderTemplate.defaults) { template in
                            Button(template.name) {
                                store.addTemplate(template)
                                status = "Added template: \(template.text)"
                            }
                        }
                    } header: {
                        Text("One-tap Templates")
                    } footer: {
                        Text("Quickly add calm, practical defaults for breathing, walk, hydration, and posture.")
                    }

                    Section("Quick Add") {
                        TextField("Remind me walk every 45 minutes during daytime", text: $quickAddText)
                            .textInputAutocapitalization(.never)

                        Button("Parse & Add") { addQuickReminder() }
                            .buttonStyle(.borderedProminent)
                            .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Section {
                        Toggle("Enable quiet mode", isOn: Binding(
                            get: { store.quietMode.isEnabled },
                            set: { newValue in
                                var q = store.quietMode
                                q.isEnabled = newValue
                                store.quietMode = q
                            }
                        ))

                        if store.quietMode.isEnabled {
                            DatePicker("Quiet start", selection: Binding(
                                get: { dateFromMinute(store.quietMode.quietStartMinute) },
                                set: { newDate in
                                    var q = store.quietMode
                                    q.quietStartMinute = minuteOfDay(newDate)
                                    store.quietMode = q
                                }
                            ), displayedComponents: .hourAndMinute)

                            DatePicker("Quiet end", selection: Binding(
                                get: { dateFromMinute(store.quietMode.quietEndMinute) },
                                set: { newDate in
                                    var q = store.quietMode
                                    q.quietEndMinute = minuteOfDay(newDate)
                                    store.quietMode = q
                                }
                            ), displayedComponents: .hourAndMinute)

                            Toggle("Pause on weekends", isOn: Binding(
                                get: { store.quietMode.pauseOnWeekends },
                                set: { newValue in
                                    var q = store.quietMode
                                    q.pauseOnWeekends = newValue
                                    store.quietMode = q
                                }
                            ))
                        }
                    } header: {
                        Text("Context-aware Quiet Mode")
                    } footer: {
                        Text("Context-aware mode suppresses notifications during quiet hours and optionally weekends.")
                    }

                    Section {
                        Button("New Reminder") { showingNewReminder = true }
                    }

                    Section("Reminders") {
                        if store.reminders.isEmpty {
                            Text("No reminders yet").foregroundStyle(.secondary)
                        } else {
                            ForEach(store.reminders) { reminder in
                                NavigationLink {
                                    ReminderEditorView(initial: reminder) { updated in
                                        store.update(updated)
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(reminder.text).font(.headline)
                                            Spacer()
                                            Toggle("", isOn: Binding(
                                                get: { reminder.isEnabled },
                                                set: { store.toggle(id: reminder.id, isEnabled: $0) }
                                            ))
                                            .labelsHidden()
                                        }

                                        Text(reminder.descriptionLine).font(.caption2).foregroundStyle(.secondary)
                                        Text(reminder.dateRangeLabel).font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .onDelete(perform: store.remove)
                        }
                    }

                    Section {
                        Button("Reschedule Notifications") { Task { await rescheduleNow() } }
                            .buttonStyle(.bordered)
                    } footer: {
                        Text("Re-applies current rules by clearing pending notifications and scheduling the next upcoming ones.")
                    }

                    if !status.isEmpty {
                        Section { Text(status).font(.caption2).foregroundStyle(.secondary) }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Watch Notify")
            .tint(CalmTheme.accent)
            .sheet(isPresented: $showingNewReminder) {
                NavigationStack {
                    ReminderEditorView(initial: nil) { newReminder in
                        store.add(newReminder)
                    }
                }
            }
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
            await NotificationScheduler.reschedule(reminders: store.reminders, quietMode: store.quietMode)
            status = "Rescheduled upcoming notifications"
        } catch {
            status = "Notification permission denied"
        }
    }

    private func minuteOfDay(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private func dateFromMinute(_ minute: Int) -> Date {
        var comps = DateComponents()
        comps.hour = max(0, min(23, minute / 60))
        comps.minute = max(0, min(59, minute % 60))
        return Calendar.current.date(from: comps) ?? Date()
    }
}
