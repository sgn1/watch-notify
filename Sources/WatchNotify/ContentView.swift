import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @State private var quickAddText: String = ""
    @State private var status: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                TextField("Remind me walk every 45 minutes during daytime", text: $quickAddText)
                    .textInputAutocapitalization(.never)

                Button("Quick Add") {
                    if let reminder = NaturalLanguageParser.parse(quickAddText) {
                        store.add(reminder)
                        quickAddText = ""
                        status = "Added reminder"
                    } else {
                        status = "Could not parse"
                    }
                }
                .buttonStyle(.borderedProminent)

                List {
                    ForEach(store.reminders) { reminder in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.text)
                                .font(.headline)
                            Text(reminder.descriptionLine)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: store.remove)
                }

                Button("Reschedule") {
                    Task {
                        do {
                            try await NotificationScheduler.requestPermission()
                            await NotificationScheduler.reschedule(reminders: store.reminders)
                            status = "Rescheduled next 24h"
                        } catch {
                            status = "Permission denied"
                        }
                    }
                }
                .buttonStyle(.bordered)

                if !status.isEmpty {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Watch Notify")
            .padding(.horizontal, 8)
        }
    }
}
