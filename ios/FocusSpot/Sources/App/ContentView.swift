import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var sync: SyncManager

    var body: some View {
        if auth.isSignedIn {
            MainView()
        } else {
            LoginView()
        }
    }
}

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 64))
                .foregroundColor(.brown)

            Text("FocusSpot")
                .font(.largeTitle.bold())

            Text("내 컨디션에 맞는\n집중하기 좋은 카페를 찾아드려요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: signIn) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView().tint(.primary)
                    } else {
                        Image("google_logo") // Assets에 추가 필요
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Text("Google로 로그인")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .disabled(isLoading)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func signIn() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let vc = scene.windows.first?.rootViewController else { return }
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                try await auth.signIn(presenting: vc)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Main

struct MainView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var sync: SyncManager
    @State private var isSyncing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // 동기화 상태
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.red)

                    if let lastSync = sync.lastSyncedAt {
                        Text("마지막 동기화")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                    } else {
                        Text("아직 동기화된 데이터가 없어요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)

                if let error = sync.syncError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // 동기화 버튼
                Button(action: syncNow) {
                    HStack {
                        if isSyncing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isSyncing ? "동기화 중..." : "지금 동기화")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(isSyncing)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .navigationTitle("FocusSpot")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("로그아웃") {
                        Task { await auth.signOut() }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private func syncNow() {
        isSyncing = true
        Task {
            defer { isSyncing = false }
            await sync.sync()
        }
    }
}
