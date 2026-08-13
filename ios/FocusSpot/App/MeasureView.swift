import SwiftUI

struct MeasureView: View {
    let onDone: (ConditionResult?) -> Void
    let onManualSelect: () -> Void
    let healthKit: HealthKitManager
    @State private var bpm: Int? = nil
    @State private var progress: CGFloat = 0.0
    @State private var statusText = "HealthKit 권한 요청 중…"
    @State private var failed = false

    var body: some View {
        ZStack {
            Color(hex: "#33272E").ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    KickLabel(text: "측정 중 · MEASURING", color: .white.opacity(0.55))
                    Text("심박을 읽고 있어요")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 110)

                Spacer()

                VStack(spacing: 30) {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Color(hex: "#46B97A").opacity(0.35), .clear],
                                                center: .center, startRadius: 0, endRadius: 110))
                            .frame(width: 220, height: 220)

                        Circle()
                            .stroke(Color(hex: "#E0608A").opacity(0.4), lineWidth: 1.5)
                            .frame(width: 180, height: 180)

                        ZStack {
                            Circle()
                                .fill(C.grad)
                                .frame(width: 132, height: 132)
                                .shadow(color: Color(hex: "#E0608A").opacity(0.5), radius: 25)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 50))
                                .foregroundColor(C.ink)
                        }
                    }

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        if let bpm {
                            Text("\(bpm)")
                                .font(.system(size: 52, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .transition(.opacity)
                        } else {
                            Text("--")
                                .font(.system(size: 52, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Text("BPM")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundColor(C.pink)
                    }
                    .animation(.easeInOut(duration: 0.3), value: bpm)
                }

                Spacer()

                VStack(spacing: 12) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.14))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(C.grad)
                                .frame(width: geo.size.width * progress, height: 5)
                                .animation(.linear(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 5)

                    if failed {
                        Text("데이터를 가져오지 못했어요. 잠시 후 다시 시도해주세요.")
                            .font(.system(size: 12.5))
                            .foregroundColor(C.rose)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(statusText)
                            .font(.system(size: 12.5, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                            .kerning(0.5)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 46)
            }
        }
        .onAppear { startMeasuring() }
    }

    private func startMeasuring() {
        Task {
            do {
                try await healthKit.requestAuthorization()
            } catch {}
            setProgress(0.2, status: "건강 데이터 읽는 중…")

            // 데이터 신선도 체크
            let freshness = await healthKit.checkDataFreshness()
            let dataIsStale = !freshness.hasHeartRate || !freshness.hasSleep

            if dataIsStale {
                print("[MeasureView] stale data: hasHR=\(freshness.hasHeartRate) hasSleep=\(freshness.hasSleep)")
                setProgress(1.0, status: "완료!")
                try? await Task.sleep(nanoseconds: 300_000_000)
                onManualSelect()
                return
            }

            let snapshot = await healthKit.fetchSnapshot()
            if let hr = snapshot.restingHeartRate {
                bpm = Int(hr)
            } else if let hr = snapshot.avgHeartRate {
                bpm = Int(hr)
            }
            setProgress(0.6, status: "컨디션 분석 중…")

            let result: ConditionResult?
            do {
                result = try await APIClient.shared.analyzeCondition(snapshot)
                print("[MeasureView] analyzeCondition success: \(result?.mode ?? "nil")")
            } catch {
                print("[MeasureView] analyzeCondition failed: \(error)")
                result = nil
            }
            setProgress(1.0, status: "완료!")

            try? await Task.sleep(nanoseconds: 400_000_000)
            onDone(result)
        }
    }

    private func setProgress(_ value: CGFloat, status: String) {
        progress = value
        statusText = status
    }
}
