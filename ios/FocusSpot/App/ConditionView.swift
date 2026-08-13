import SwiftUI

private let modeMeta: [String: (color: Color, bg: Color, icon: String)] = [
    "focus":     (C.greenDeep, C.lavender,            "scope"),
    "drowsy":    (Color(hex: "#7C5CB8"), Color(hex: "#F0EBF8"), "moon.fill"),
    "fatigue":   (C.rose,      C.pinkBg,              "waveform.path.ecg"),
    "energized": (Color(hex: "#D48A00"), Color(hex: "#FFF6DC"), "bolt.fill"),
    "recovery":  (Color(hex: "#2E8B6A"), Color(hex: "#E6F5EE"), "shield.fill"),
]

struct ConditionView: View {
    let condition: ConditionResult?
    let onBack: () -> Void
    let onRecommend: () -> Void

    private var meta: (color: Color, bg: Color, icon: String) {
        modeMeta[condition?.mode ?? "focus"] ?? (C.greenDeep, C.lavender, "scope")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    C.grad.ignoresSafeArea(edges: .top)
                    VStack(alignment: .leading, spacing: 10) {
                        KickLabel(text: "지금 당신은", color: C.ink.opacity(0.6))
                        Text(condition?.label ?? "집중하기 좋은 상태예요 ✦")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(C.ink)
                            .lineSpacing(2)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 108)
                    .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 10) {
                    MetricCard(value: condition?.heartRate.map { "\(Int($0))" } ?? "--",
                               unit: "BPM",
                               tag: condition?.heartRate.map { hr in
                                   hr < 50 ? "낮음" : hr <= 80 ? "안정" : "높음"
                               } ?? "--")
                    MetricCard(value: condition?.sleepHours.map { String(format: "%.1f", $0) } ?? "--",
                               unit: "수면(h)",
                               tag: condition?.sleepHours.map { h in
                                   h >= 7 ? "충분" : h >= 5.5 ? "보통" : "부족"
                               } ?? "--")
                    MetricCard(value: condition.map { "\($0.confidence)" } ?? "--",
                               unit: "집중점수",
                               tag: condition.map { c in
                                   c.confidence >= 75 ? "좋음" : c.confidence >= 55 ? "보통" : "낮음"
                               } ?? "--")
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(C.greenDeep)
                    Text(condition?.cafeHint ?? "지금 컨디션에 맞는 카페를 찾아드려요")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(C.greenDeep)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(C.lavender)
                .cornerRadius(14)
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Spacer()

                PrimaryButton(label: "카페 추천 보기", action: onRecommend)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
            .background(C.surface.ignoresSafeArea())

            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(C.ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(13)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
            .padding(.leading, 18)
            .padding(.top, 44)
        }
    }
}

private struct MetricCard: View {
    let value: String
    let unit: String
    let tag: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(C.ink)
            Text(unit)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(C.faint)
            Text(tag)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(C.rose)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(C.pinkBg)
                .cornerRadius(8)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(C.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(C.line, lineWidth: 1))
    }
}
