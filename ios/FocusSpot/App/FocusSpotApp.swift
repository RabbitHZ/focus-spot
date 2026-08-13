import SwiftUI
import GoogleSignIn

@main
struct FocusSpotApp: App {
    @StateObject private var auth = AuthManager()
    @StateObject private var sync: SyncManager
    @State private var showSplash = true

    init() {
        SyncManager.registerBackgroundTask()
        let hk = HealthKitManager()
        _sync = StateObject(wrappedValue: SyncManager(healthKit: hk))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(auth)
                    .environmentObject(sync)
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
