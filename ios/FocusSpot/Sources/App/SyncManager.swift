import Foundation
import BackgroundTasks

@MainActor
class SyncManager: ObservableObject {
    static let backgroundTaskID = "app.focusspot.health-sync"

    @Published var lastSyncedAt: Date? = {
        UserDefaults.standard.object(forKey: "last_synced_at") as? Date
    }()
    @Published var syncError: String?

    private let healthKit: HealthKitManager

    init(healthKit: HealthKitManager) {
        self.healthKit = healthKit
    }

    // MARK: - Manual sync

    func sync() async {
        syncError = nil
        do {
            let snapshot = try await healthKit.fetchSnapshot()
            try await APIClient.shared.syncHealth(snapshot)
            lastSyncedAt = snapshot.recordedAt
            UserDefaults.standard.set(snapshot.recordedAt, forKey: "last_synced_at")
        } catch {
            syncError = error.localizedDescription
        }
    }

    // MARK: - Background task registration

    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskID, using: nil) { task in
            Self.handleBackgroundSync(task: task as! BGAppRefreshTask)
        }
    }

    static func scheduleNextBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30분
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleBackgroundSync(task: BGAppRefreshTask) {
        scheduleNextBackgroundSync()

        let syncTask = Task { @MainActor in
            let hk = HealthKitManager()
            do {
                let snapshot = try await hk.fetchSnapshot()
                try await APIClient.shared.syncHealth(snapshot)
                UserDefaults.standard.set(snapshot.recordedAt, forKey: "last_synced_at")
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = { syncTask.cancel() }
    }
}
