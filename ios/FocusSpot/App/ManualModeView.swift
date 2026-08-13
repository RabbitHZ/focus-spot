import SwiftUI

private struct ModeOption {
    let mode: String
    let label: String
    let description: String
    let icon: String
    let color: Color
    let bg: Color
}

private let options: [ModeOption] = [
    ModeOption(mode: "focus",     label: "집중 모드",  description: "맑고 에너지 있어요",       icon: "scope",              color: Color(hex: "#34A267"), bg: Color(hex: "#F4E9EF")),
    ModeOption(mode: "energized", label: "활기 모드",  description: "몸이 가볍고 의욕 넘쳐요",  icon: "bolt.fill",           color: Color(hex: "#D48A00"), bg: Color(hex: "#FFF6DC")),
    ModeOption(mode: "drowsy",    label: "졸림 모드",  description: "좀 나른하고 졸려요",       icon: "moon.fill",           color: Color(hex: "#7C5CB8"), bg: Color(hex: "#F0EBF8")),
    ModeOption(mode: "fatigue",   label: "피로 모드",  description: "몸이 무겁고 피곤해요",     icon: "waveform.path.ecg",   color: Color(hex: "#CE4A78"), bg: Color(hex: "#FCE3EC")),
    ModeOption(mode: "recovery",  label: "회복 모드",  description: "쉬어야 할 것 같아요",      icon: "shield.fill",         color: Color(hex: "#2E8B6A"), bg: Color(hex: "#E6F5EE")),
]

struct ManualModeView: View {
    let onSelect: (ConditionResult) -> Void

    var body: some View {
        ZStack {
            C.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    KickLabel(text: "직접 선택 · MANUAL", color: C.faint)
                        .padding(.bottom, 2)
                    Text("지금 컨디션이\n어떠신가요?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(C.ink)
                        .lineSpacing(3)
                    Text("오늘 HealthKit 데이터가 부족해 직접 선택합니다.")
                        .font(.system(size: 13.5))
                        .foregroundColor(C.sub)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 100)
                .padding(.bottom, 28)

                VStack(spacing: 12) {
                    ForEach(options, id: \.mode) { opt in
                        Button(action: { select(opt) }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(opt.bg)
                                        .frame(width: 46, height: 46)
                                    Image(systemName: opt.icon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(opt.color)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(opt.label)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(C.ink)
                                    Text(opt.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(C.sub)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(C.faint)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(C.card)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(C.line, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }

    private func select(_ opt: ModeOption) {
        let labels: [String: String] = [
            "focus":     "집중하기 좋은 상태예요 ✦",
            "energized": "활기차고 에너지 넘쳐요 ⚡",
            "drowsy":    "좀 졸리고 나른한 상태예요 🌙",
            "fatigue":   "피곤하고 지쳐있는 상태예요",
            "recovery":  "몸이 회복이 필요한 상태예요",
        ]
        let hints: [String: String] = [
            "focus":     "조용하고 집중하기 좋은 카페를 찾아드릴게요",
            "energized": "활기차고 사람 많은 카페가 잘 맞아요",
            "drowsy":    "적당한 소음과 밝은 조명이 도움돼요",
            "fatigue":   "조용하고 편안한 분위기 카페를 추천해요",
            "recovery":  "개인 공간이 있는 조용한 카페가 좋아요",
        ]
        let defaultConfidence: [String: Int] = [
            "focus":     82,
            "energized": 85,
            "drowsy":    65,
            "fatigue":   75,
            "recovery":  60,
        ]
        let result = ConditionResult(
            mode: opt.mode,
            label: labels[opt.mode] ?? opt.label,
            confidence: defaultConfidence[opt.mode] ?? 70,
            cafeHint: hints[opt.mode] ?? "",
            heartRate: nil,
            sleepHours: nil,
            spo2: nil,
            stepCount: nil
        )
        onSelect(result)
    }
}
