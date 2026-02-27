import SwiftUI

private enum CalmTheme {
    static let bgTop = Color(red: 0.94, green: 0.97, blue: 0.99)
    static let bgBottom = Color(red: 0.87, green: 0.93, blue: 0.97)
    static let card = Color.white.opacity(0.82)
    static let stroke = Color.white.opacity(0.55)
    static let title = Color(red: 0.10, green: 0.20, blue: 0.30)
    static let secondary = Color(red: 0.35, green: 0.48, blue: 0.60)
    static let accent = Color(red: 0.16, green: 0.47, blue: 0.68)
}

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore
    @State private var quickAddText: String = ""
    @State private var status: String = ""
    @State private var showingNewReminder = false

    var body: some View {
        #if os(iOS)
        iosView
        #else
        watchView
        #endif
    }

    private var iosView: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [CalmTheme.bgTop, CalmTheme.bgBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        headerCard
                        templatesCard
                        quickAddCard
                        quietModeCard
                        remindersCard
                        scheduleCard
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Watch Notify")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewReminder = true
                    } label: {
                        Label("New", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title3)
                    }
                }
            }
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

    private var watchView: some View {
        NavigationStack {
            Form {
                Section("Templates") {
                    ForEach(ReminderTemplate.defaults) { template in
                        Button(template.name) {
                            store.addTemplate(template)
                            status = "Added template: \(template.text)"
                        }
                    }
                }

                Section("Reminders") {
                    ForEach(store.reminders) { reminder in
                        NavigationLink {
                            ReminderEditorView(initial: reminder) { updated in
                                store.update(updated)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reminder.text).font(.headline)
                                Text(reminder.descriptionLine).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: store.remove)
                }

                Section {
                    Button("New Reminder") { showingNewReminder = true }
                    Button("Reschedule Notifications") { Task { await rescheduleNow() } }
                }
            }
            .navigationTitle("Watch Notify")
            .sheet(isPresented: $showingNewReminder) {
                NavigationStack {
                    ReminderEditorView(initial: nil) { newReminder in
                        store.add(newReminder)
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("Focused reminders, beautifully timed")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CalmTheme.title)

                HStack(spacing: 10) {
                    statPill(title: "Active", value: "\(store.reminders.filter { $0.isEnabled }.count)")
                    statPill(title: "Total", value: "\(store.reminders.count)")
                    statPill(title: "Quiet", value: store.quietMode.isEnabled ? "On" : "Off")
                }
            }
        }
    }

    private var templatesCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("One-tap Templates")
                    .font(.headline)
                    .foregroundStyle(CalmTheme.title)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(ReminderTemplate.defaults) { template in
                        Button {
                            store.addTemplate(template)
                            status = "Added template: \(template.text)"
                        } label: {
                            Text(template.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(CalmTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var quickAddCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick Add")
                    .font(.headline)
                    .foregroundStyle(CalmTheme.title)

                TextField("Remind me walk every 45 minutes during daytime", text: $quickAddText)
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button("Parse & Add") { addQuickReminder() }
                    .buttonStyle(.borderedProminent)
                    .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var quietModeCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Context-aware Quiet Mode", isOn: Binding(
                    get: { store.quietMode.isEnabled },
                    set: { newValue in
                        var q = store.quietMode
                        q.isEnabled = newValue
                        store.quietMode = q
                    }
                ))
                .foregroundStyle(CalmTheme.title)

                if store.quietMode.isEnabled {
                    DatePicker("Quiet starts", selection: Binding(
                        get: { dateFromMinute(store.quietMode.quietStartMinute) },
                        set: { newDate in
                            var q = store.quietMode
                            q.quietStartMinute = minuteOfDay(newDate)
                            store.quietMode = q
                        }
                    ), displayedComponents: .hourAndMinute)

                    DatePicker("Quiet ends", selection: Binding(
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
            }
        }
    }

    private var remindersCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Reminders")
                        .font(.headline)
                        .foregroundStyle(CalmTheme.title)
                    Spacer()
                    Button("New") { showingNewReminder = true }
                        .font(.subheadline.weight(.semibold))
                }

                if store.reminders.isEmpty {
                    Text("No reminders yet")
                        .foregroundStyle(CalmTheme.secondary)
                } else {
                    ForEach(store.reminders) { reminder in
                        NavigationLink {
                            ReminderEditorView(initial: reminder) { updated in
                                store.update(updated)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(reminder.text)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(CalmTheme.title)
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { reminder.isEnabled },
                                        set: { store.toggle(id: reminder.id, isEnabled: $0) }
                                    ))
                                    .labelsHidden()
                                }
                                Text(reminder.descriptionLine)
                                    .font(.caption)
                                    .foregroundStyle(CalmTheme.secondary)
                                Text(reminder.dateRangeLabel)
                                    .font(.caption2)
                                    .foregroundStyle(CalmTheme.secondary)
                            }
                            .padding(10)
                            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var scheduleCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Button("Reschedule Notifications") { Task { await rescheduleNow() } }
                    .buttonStyle(.bordered)

                if !status.isEmpty {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(CalmTheme.secondary)
                }
            }
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(CalmTheme.title)
            Text(title)
                .font(.caption2)
                .foregroundStyle(CalmTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func cardContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack { content() }
            .padding(14)
            .background(CalmTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(CalmTheme.stroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
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
