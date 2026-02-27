import SwiftUI

private enum AppTheme {
    static let top = Color(red: 0.93, green: 0.96, blue: 0.99)
    static let mid = Color(red: 0.87, green: 0.92, blue: 0.97)
    static let bottom = Color(red: 0.82, green: 0.89, blue: 0.95)

    static let accent = Color(red: 0.20, green: 0.50, blue: 0.72)
    static let accentSoft = Color(red: 0.20, green: 0.50, blue: 0.72).opacity(0.14)
    static let cardStroke = Color.white.opacity(0.45)
}

private struct BannerStatus {
    enum Kind {
        case info
        case success
        case error

        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .success: return "checkmark.circle"
            case .error: return "exclamationmark.triangle"
            }
        }
    }

    let kind: Kind
    let message: String
}

struct ContentView: View {
    @EnvironmentObject private var store: ReminderStore

    @State private var quickAddText = ""
    @State private var status: BannerStatus?
    @State private var showingNewReminder = false
    @State private var editingReminder: Reminder?
    @State private var reminderPendingDeletion: Reminder?
    @State private var showingDeleteConfirmation = false
    @State private var isRescheduling = false

    var body: some View {
        #if os(iOS)
        iOSBody
        #else
        watchBody
        #endif
    }

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [AppTheme.top, AppTheme.mid, AppTheme.bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        heroCard
                        templatesCard
                        quickAddCard
                        quietModeCard
                        remindersCard

                        if let status {
                            statusPill(status)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Watch Notify")
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .sheet(isPresented: $showingNewReminder) {
                NavigationStack {
                    ReminderEditorView(initial: nil) { newReminder in
                        store.add(newReminder)
                        status = BannerStatus(kind: .success, message: "Added \"\(newReminder.text)\"")
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingReminder) { reminder in
                NavigationStack {
                    ReminderEditorView(initial: reminder) { updated in
                        store.update(updated)
                        status = BannerStatus(kind: .success, message: "Updated \"\(updated.text)\"")
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Delete reminder?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: reminderPendingDeletion
            ) { reminder in
                Button("Delete \"\(reminder.text)\"", role: .destructive) {
                    remove(reminder)
                }
                Button("Cancel", role: .cancel) {}
            } message: { reminder in
                Text("This removes the reminder from iPhone and Watch after sync.")
            }
            .onChange(of: store.reminders) { _, _ in
                Task { await autoRescheduleSilently() }
            }
            .onChange(of: store.quietMode) { _, _ in
                Task { await autoRescheduleSilently() }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calm reminders,")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("beautifully synced")
                        .font(.system(.title2, design: .rounded, weight: .bold))

                    Text("Manage reminders on iPhone and Watch with one shared schedule.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(AppTheme.accentSoft)
                        .frame(width: 54, height: 54)
                    Image(systemName: "applewatch.radiowaves.left.and.right")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            HStack(spacing: 10) {
                statPill(icon: "bell.badge.fill", title: "Active", value: "\(activeReminderCount)")
                statPill(icon: "moon.zzz.fill", title: "Quiet", value: store.quietMode.isEnabled ? "On" : "Off")
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private func statPill(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.65))
        )
    }

    private var templatesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle("Quick Templates", icon: "sparkles")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ReminderTemplate.defaults) { template in
                        Button {
                            applyTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("Every \(template.intervalMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(width: 145, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppTheme.accentSoft)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var quickAddCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle("Quick Add", icon: "bolt.fill")

            TextField("Remind me walk every 45 minutes during daytime", text: $quickAddText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.75))
                )

            Button {
                addQuickReminder()
            } label: {
                Label("Parse & Add", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(16)
        .background(cardBackground)
    }

    private var quietModeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                cardTitle("Quiet Mode", icon: "moon.stars.fill")
                Spacer()
                Toggle("", isOn: quietModeEnabledBinding)
                    .labelsHidden()
                    .tint(AppTheme.accent)
            }

            if store.quietMode.isEnabled {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: quietStartBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("End")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: quietEndBinding, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Toggle("Pause reminders on weekends", isOn: quietPauseWeekendsBinding)
                    .tint(AppTheme.accent)
            } else {
                Text("Reminders are allowed all day unless each reminder has its own time window.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                cardTitle("Reminders", icon: "list.bullet.rectangle")
                Spacer()
                Text("\(store.reminders.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.7)))
            }

            if store.reminders.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bell.slash")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("No reminders yet")
                        .font(.subheadline)
                    Text("Add one from Quick Add, Templates, or New Reminder.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.reminders) { reminder in
                        reminderRow(reminder)
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(reminder.text)
                        .font(.headline)
                    Text(reminder.descriptionLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { store.toggle(id: reminder.id, isEnabled: $0) }
                ))
                .labelsHidden()
                .tint(AppTheme.accent)
            }

            Text(reminder.dateRangeLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    editingReminder = reminder
                } label: {
                    Label("Edit", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(role: .destructive) {
                    reminderPendingDeletion = reminder
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }

    private func statusPill(_ status: BannerStatus) -> some View {
        Label(status.message, systemImage: status.kind.icon)
            .font(.footnote)
            .foregroundStyle(status.kind.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.8))
            )
    }

    private var actionBar: some View {
        VStack(spacing: 9) {
            if isRescheduling {
                ProgressView("Applying latest schedule…")
                    .font(.caption)
            }

            HStack(spacing: 10) {
                Button {
                    showingNewReminder = true
                } label: {
                    Label("New Reminder", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)

                Button {
                    Task { await rescheduleNow() }
                } label: {
                    Label("Reschedule", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRescheduling)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.58))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
    }

    private func cardTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private var activeReminderCount: Int {
        store.reminders.filter(\.isEnabled).count
    }
    #endif

    // Watch UI keeps the same capability set, tuned for compact screens.
    private var watchBody: some View {
        NavigationStack {
            Form {
                Section("Templates") {
                    ForEach(ReminderTemplate.defaults) { template in
                        Button(template.name) {
                            applyTemplate(template)
                        }
                    }
                }

                Section("Quick Add") {
                    TextField("Remind me walk every 45 minutes", text: $quickAddText)
                        .textInputAutocapitalization(.never)
                    Button("Parse & Add") { addQuickReminder() }
                        .disabled(quickAddText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Quiet Mode") {
                    Toggle("Enable quiet mode", isOn: quietModeEnabledBinding)

                    if store.quietMode.isEnabled {
                        DatePicker("Quiet start", selection: quietStartBinding, displayedComponents: .hourAndMinute)
                        DatePicker("Quiet end", selection: quietEndBinding, displayedComponents: .hourAndMinute)
                        Toggle("Pause weekends", isOn: quietPauseWeekendsBinding)
                    }
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

                                    Text(reminder.descriptionLine)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .onDelete(perform: store.remove)
                    }
                }

                Section {
                    Button("Reschedule Notifications") {
                        Task { await rescheduleNow() }
                    }
                    .disabled(isRescheduling)
                }

                if let status {
                    Section {
                        Text(status.message)
                            .font(.caption2)
                            .foregroundStyle(status.kind.color)
                    }
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
            .onChange(of: store.reminders) { _, _ in
                Task { await autoRescheduleSilently() }
            }
            .onChange(of: store.quietMode) { _, _ in
                Task { await autoRescheduleSilently() }
            }
        }
    }

    private var quietModeEnabledBinding: Binding<Bool> {
        Binding(
            get: { store.quietMode.isEnabled },
            set: { newValue in
                var mode = store.quietMode
                mode.isEnabled = newValue
                store.quietMode = mode
            }
        )
    }

    private var quietPauseWeekendsBinding: Binding<Bool> {
        Binding(
            get: { store.quietMode.pauseOnWeekends },
            set: { newValue in
                var mode = store.quietMode
                mode.pauseOnWeekends = newValue
                store.quietMode = mode
            }
        )
    }

    private var quietStartBinding: Binding<Date> {
        Binding(
            get: { dateFromMinute(store.quietMode.quietStartMinute) },
            set: { newDate in
                var mode = store.quietMode
                mode.quietStartMinute = minuteOfDay(newDate)
                store.quietMode = mode
            }
        )
    }

    private var quietEndBinding: Binding<Date> {
        Binding(
            get: { dateFromMinute(store.quietMode.quietEndMinute) },
            set: { newDate in
                var mode = store.quietMode
                mode.quietEndMinute = minuteOfDay(newDate)
                store.quietMode = mode
            }
        )
    }

    private func applyTemplate(_ template: ReminderTemplate) {
        store.addTemplate(template)
        status = BannerStatus(kind: .success, message: "Added template: \(template.text)")
    }

    private func addQuickReminder() {
        guard let reminder = NaturalLanguageParser.parse(quickAddText) else {
            status = BannerStatus(kind: .error, message: "Could not parse reminder")
            return
        }

        store.add(reminder)
        quickAddText = ""
        status = BannerStatus(kind: .success, message: "Added \"\(reminder.text)\"")
    }

    @MainActor
    private func rescheduleNow() async {
        isRescheduling = true
        defer { isRescheduling = false }

        do {
            try await NotificationScheduler.requestPermission()
            await NotificationScheduler.reschedule(reminders: store.reminders, quietMode: store.quietMode)
            status = BannerStatus(kind: .success, message: "Rescheduled upcoming notifications")
        } catch {
            status = BannerStatus(kind: .error, message: "Notification permission denied")
        }
    }

    @MainActor
    private func autoRescheduleSilently() async {
        guard !isRescheduling else { return }
        do {
            try await NotificationScheduler.requestPermission()
            await NotificationScheduler.reschedule(reminders: store.reminders, quietMode: store.quietMode)
        } catch {
            // Keep silent for automatic flows; manual button reports errors.
        }
    }

    private func remove(_ reminder: Reminder) {
        guard let idx = store.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        store.reminders.remove(at: idx)
        status = BannerStatus(kind: .info, message: "Removed \"\(reminder.text)\"")
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
