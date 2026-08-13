import SwiftUI
import CoreLocation

enum Screen {
    case welcome, login, measure, manualMode, condition, location, cafes, detail(CafeCard), profile
}

struct ContentView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var sync: SyncManager

    @State private var stack: [Screen] = [.welcome]
    @State private var condition: ConditionResult?
    @State private var cafes: [CafeCard] = []
    @State private var cafesLoading = false
    @State private var cafesError: String? = nil
    @State private var radius: RadiusOption = .km1
    @State private var lastLocation: (lat: Double, lng: Double)?

    private var current: Screen { stack.last ?? .welcome }

    var body: some View {
        ZStack {
            switch current {
            case .welcome:
                WelcomeView(onLogin: { push(.login) })
                    .transition(.opacity)

            case .login:
                LoginView(onBack: pop)
                    .environmentObject(auth)
                    .transition(.move(edge: .trailing))
                    .onChange(of: auth.isSignedIn) { _, signed in
                        if signed { push(.measure) }
                    }

            case .measure:
                MeasureView(
                    onDone: { result in
                        condition = result
                        push(.condition)
                    },
                    onManualSelect: { push(.manualMode) },
                    healthKit: sync.healthKit
                )
                .transition(.opacity)

            case .manualMode:
                ManualModeView(onSelect: { result in
                    condition = result
                    push(.condition)
                })
                .transition(.move(edge: .trailing))

            case .condition:
                ConditionView(condition: condition, onBack: pop, onRecommend: { push(.location) })
                    .transition(.move(edge: .trailing))

            case .location:
                LocationView(onBack: pop, onLocation: fetchCafes)
                    .transition(.move(edge: .trailing))

            case .cafes:
                CafeListView(
                    cafes: cafes,
                    isLoading: cafesLoading,
                    error: cafesError,
                    condition: condition,
                    onSelect: { cafe in push(.detail(cafe)) },
                    onProfile: { push(.profile) },
                    onRemeasure: { remeasure() }
                )
                .transition(.move(edge: .trailing))

            case .detail(let cafe):
                CafeDetailView(cafe: cafe, onBack: pop)
                    .transition(.move(edge: .trailing))

            case .profile:
                ProfileView(
                    condition: condition,
                    onBack: {
                        pop()
                        if let loc = lastLocation {
                            fetchCafes(lat: loc.lat, lng: loc.lng)
                        }
                    },
                    onSignOut: {
                        Task {
                            await auth.signOut()
                            stack = [.welcome]
                        }
                    },
                    radius: $radius
                )
                .environmentObject(auth)
                .transition(.move(edge: .trailing))
                .onChange(of: radius) { _, newRadius in
                    Task { try? await APIClient.shared.updateRadius(radiusKm: newRadius.km) }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stack.count)
        .onAppear {
            if auth.isSignedIn { push(.measure) }
        }
    }

    private func push(_ screen: Screen) {
        stack.append(screen)
    }

    private func pop() {
        guard stack.count > 1 else { return }
        stack.removeLast()
    }

    private func remeasure() {
        condition = nil
        cafes = []
        cafesError = nil
        stack = stack.filter { screen in
            if case .welcome = screen { return true }
            if case .login = screen { return true }
            return false
        }
        push(.measure)
    }

    private func fetchCafes(lat: Double, lng: Double) {
        lastLocation = (lat, lng)
        if case .cafes = current {} else { push(.cafes) }
        cafesLoading = true
        cafesError = nil
        Task {
            do {
                let result = try await withTimeout(seconds: 15) {
                    try await APIClient.shared.recommendCafes(lat: lat, lng: lng, radiusKm: radius.km, mode: condition?.mode)
                }
                cafes = result.cafes
            } catch is TimeoutError {
                cafes = []
                cafesError = "서버 응답이 너무 늦어요. 잠시 후 다시 시도해주세요."
            } catch {
                cafes = []
                cafesError = error.localizedDescription
            }
            cafesLoading = false
        }
    }
}
