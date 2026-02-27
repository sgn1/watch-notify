import SwiftUI

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let initial: Reminder?
    let onSave: (Reminder) -> Void

    @State private var text: String = ""
    @State private var intervalMinutes: Int = 15
    @State private var useWindow = false
    @State private var windowStart = Date()
    @State private var windowEnd = Date()
    @State private var selectedWeekdays: Set<Int> = Set(1...7)
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var isEnabled = true

    init(initial: Reminder?, onSave: @escaping (Reminder) -> Void) {
        self.initial = initial
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Reminder") {
                TextField("Message", text: $text)
                Stepper("Every \(intervalMinutes) min", value: $intervalMinutes, in: 1...720)
                Toggle("Enabled", isOn: $isEnabled)
            }

            Section("Time Window") {
                Toggle("Use daily time window", isOn: $useWindow)
                if useWindow {
                    DatePicker("Start", selection: $windowStart, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $windowEnd, displayedComponents: .hourAndMinute)
                }
            }

            Section("Days of Week") {
                ForEach(1...7, id: \.self) { day in
                    Toggle(weekdayName(day), isOn: Binding(
                        get: { selectedWeekdays.contains(day) },
                        set: { value in
                            if value { selectedWeekdays.insert(day) } else { selectedWeekdays.remove(day) }
                        }
                    ))
                }
            }

            Section("Date Range") {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Set end date", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
            }

            Section {
                Button(initial == nil ? "Add Reminder" : "Save Changes") {
                    save()
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedWeekdays.isEmpty)
            }
        }
        .navigationTitle(initial == nil ? "New Reminder" : "Edit Reminder")
        .onAppear(perform: hydrate)
    }

    private func hydrate() {
        guard let reminder = initial else {
            text = ""
            intervalMinutes = 15
            useWindow = false
            selectedWeekdays = Set(1...7)
            startDate = Calendar.current.startOfDay(for: Date())
            endDate = Calendar.current.startOfDay(for: Date())
            hasEndDate = false
            return
        }

        text = reminder.text
        intervalMinutes = reminder.intervalMinutes
        useWindow = reminder.windowStartMinute != nil && reminder.windowEndMinute != nil
        if let start = reminder.windowStartMinute { windowStart = dateFromMinute(start) }
        if let end = reminder.windowEndMinute { windowEnd = dateFromMinute(end) }
        selectedWeekdays = reminder.weekdays
        startDate = reminder.startDate
        if let endDateValue = reminder.endDate {
            hasEndDate = true
            endDate = endDateValue
        }
        isEnabled = reminder.isEnabled
    }

    private func save() {
        let reminder = Reminder(
            id: initial?.id ?? UUID(),
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            intervalMinutes: intervalMinutes,
            windowStartMinute: useWindow ? minuteOfDay(windowStart) : nil,
            windowEndMinute: useWindow ? minuteOfDay(windowEnd) : nil,
            weekdays: selectedWeekdays,
            startDate: Calendar.current.startOfDay(for: startDate),
            endDate: hasEndDate ? Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: endDate) : nil,
            isEnabled: isEnabled
        )
        onSave(reminder)
        dismiss()
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

    private func weekdayName(_ day: Int) -> String {
        Calendar.current.weekdaySymbols[max(0, min(6, day - 1))]
    }
}
