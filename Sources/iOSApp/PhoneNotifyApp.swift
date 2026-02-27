import SwiftUI

@main
struct PhoneNotifyApp: App {
    @StateObject private var store = ReminderStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
