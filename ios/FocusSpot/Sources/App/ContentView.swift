import SwiftUI

struct ContentView: View {
    @StateObject private var healthKit = HealthKitManager()
    @State private var status: String = "준비 중..."
    @State private var isSyncing = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("FocusSpot")
                .font(.title.bold())

            Text(status)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: sync) {
                Label(isSyncing ? "동기화 중..." : "건강 데이터 동기화", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isSyncing)
        }
        .padding(32)
        .task {
            do {
                try await healthKit.requestAuthorization()
                status = "HealthKit 연결됨"
            } catch {
                status = error.localizedDescription
            }
        }
    }

    private func sync() {
        isSyncing = true
        Task {
            defer { isSyncing = false }
            do {
                let snapshot = try await healthKit.fetchSnapshot()
                // TODO: APIClient.syncHealth(snapshot) 호출
                status = "마지막 동기화: \(snapshot.recordedAt.formatted(date: .omitted, time: .shortened))"
            } catch {
                status = "동기화 실패: \(error.localizedDescription)"
            }
        }
    }
}
