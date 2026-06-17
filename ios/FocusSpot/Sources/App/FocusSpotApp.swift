import SwiftUI
import GoogleSignIn

@main
struct FocusSpotApp: App {
    @StateObject private var auth = AuthManager()
    @StateObject private var healthKit = HealthKitManager()
    @StateObject private var sync: SyncManager

    init() {
        SyncManager.registerBackgroundTask()
        let hk = HealthKitManager()
        _healthKit = StateObject(wrappedValue: hk)
        _sync = StateObject(wrappedValue: SyncManager(healthKit: hk))
        _auth = StateObject(wrappedValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(sync)
                .task {
                    await auth.restorePreviousSignIn()
                    try? await healthKit.requestAuthorization()
                    SyncManager.scheduleNextBackgroundSync()
                }
                .onOpenURL { url in
                    // Google Sign-In redirect URL 처리
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
