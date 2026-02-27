import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

struct ReminderSyncEnvelope: Codable {
    let modifiedAt: Date
    let reminders: [Reminder]
}

@MainActor
protocol ReminderSyncing {
    var onReceive: ((ReminderSyncEnvelope) -> Void)? { get set }
    func start()
    func push(envelope: ReminderSyncEnvelope)
}

@MainActor
final class ReminderSyncService: NSObject, ReminderSyncing {
    static let shared = ReminderSyncService()
    var onReceive: ((ReminderSyncEnvelope) -> Void)?

    private let key = "remindersData"

    func start() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        #endif
    }

    func push(envelope: ReminderSyncEnvelope) {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        do {
            let data = try JSONEncoder().encode(envelope)
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
            let envelope = try JSONDecoder().decode(ReminderSyncEnvelope.self, from: data)
            onReceive?(envelope)
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
