import SwiftUI

@main
struct WatchNotifyApp: App {
    @StateObject private var store = ReminderStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
