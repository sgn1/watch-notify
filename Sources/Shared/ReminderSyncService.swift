import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
protocol ReminderSyncing {
    var onReceive: (([Reminder]) -> Void)? { get set }
    func start()
    func push(reminders: [Reminder])
}

@MainActor
final class ReminderSyncService: NSObject, ReminderSyncing {
    static let shared = ReminderSyncService()
    var onReceive: (([Reminder]) -> Void)?

    private let key = "remindersData"

    func start() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        #endif
    }

    func push(reminders: [Reminder]) {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        do {
            let data = try JSONEncoder().encode(reminders)
            try? session.updateApplicationContext([key: data])
            session.transferUserInfo([key: data])
        } catch {
            print("Sync encode failed: \(error)")
        }
        #endif
    }

    private func consume(payload: [String: Any]) {
        guard let data = payload[key] as? Data else { return }
        do {
            let reminders = try JSONDecoder().decode([Reminder].self, from: data)
            onReceive?(reminders)
        } catch {
            print("Sync decode failed: \(error)")
        }
    }
}

#if canImport(WatchConnectivity)
extension ReminderSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { print("WC activate error: \(error)") }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            self.consume(payload: applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            self.consume(payload: userInfo)
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
#endif
