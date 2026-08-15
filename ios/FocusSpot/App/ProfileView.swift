import SwiftUI

enum RadiusOption: Int, CaseIterable {
    case m500 = 500
    case km1 = 1000
    case km2 = 2000

    var label: String {
        switch self {
        case .m500: return "500m"
        case .km1:  return "1km"
        case .km2:  return "2km"
        }
    }

    var km: Double {
        Double(rawValue) / 1000
    }
}


struct ProfileView: View {
    let condition: ConditionResult?
    let onBack: () -> Void
    let onSignOut: () -> Void
    @Binding var radius: RadiusOption

    @EnvironmentObject private var auth: AuthManager

    private let modeMeta: [String: (color: Color, bg: Color, icon: String, desc: String)] = [
        "focus":     (C.greenDeep, C.lavender,             "scope",            "수면·심박 모두 안정적이에요. 지금이 가장 집중하기 좋은 상태예요."),
        "drowsy":    (Color(hex: "#7C5CB8"), Color(hex: "#F0EBF8"), "moon.fill","수면이 조금 부족해 보여요. 밝고 약간 소음 있는 카페가 도움돼요."),
        "fatigue":   (C.rose,      C.pinkBg,               "waveform.path.ecg","심박이 높고 피로도가 쌓여 있어요. 조용하고 편안한 공간을 추천해요."),
        "energized": (Color(hex: "#D48A00"), Color(hex: "#FFF6DC"), "bolt.fill","에너지가 넘쳐요! 활기차고 사람 많은 카페도 잘 맞아요."),
        "recovery":  (Color(hex: "#2E8B6A"), Color(hex: "#E6F5EE"), "shield.fill","불규칙한 패턴이 감지됐어요. 조용하고 개인 공간 있는 곳을 찾아보세요."),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            C.surface.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: 프로필
                    HStack(spacing: 16) {
                        AsyncImageView(url: auth.userImageURL)
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(C.line, lineWidth: 2))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(auth.userName.isEmpty ? "사용자" : auth.userName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(C.ink)
                            Text(auth.userEmail.isEmpty ? "FocusSpot" : auth.userEmail)
                                .font(.system(size: 13))
                                .foregroundColor(C.sub)
                        }
                    }
                    .padding(.top, 100)

                    // MARK: 현재 컨디션
                    sectionBlock("현재 내 상태") {
                        if let condition, let meta = modeMeta[condition.mode] {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 13)
                                            .fill(Color.white.opacity(0.6))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: meta.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(meta.color)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(condition.label)
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(meta.color)
                                        Text(meta.desc)
                                            .font(.system(size: 13))
                                            .foregroundColor(C.sub)
                                            .lineSpacing(2)
                                    }
                                }

                                // 신뢰도 바
                                VStack(spacing: 6) {
                                    HStack {
                                        Text("측정 신뢰도")
                                            .font(.system(size: 12))
                                            .foregroundColor(C.sub)
                                        Spacer()
                                        Text("\(condition.confidence)%")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(meta.color)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 99)
                                                .fill(Color.black.opacity(0.07))
                                                .frame(height: 6)
                                            RoundedRectangle(cornerRadius: 99)
                                                .fill(meta.color)
                                                .frame(width: geo.size.width * CGFloat(condition.confidence) / 100, height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                }

                                // 건강 수치
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    if let hr = condition.heartRate {
                                        healthCard(value: "\(Int(hr))", unit: "BPM", color: meta.color)
                                    }
                                    if let sleep = condition.sleepHours {
                                        healthCard(value: String(format: "%.1f", sleep), unit: "수면(h)", color: meta.color)
                                    }
                                    if let spo2 = condition.spo2 {
                                        healthCard(value: "\(Int(spo2))", unit: "SpO2 %", color: meta.color)
                                    }
                                    if let steps = condition.stepCount {
                                        healthCard(value: "\(steps.formatted())", unit: "걸음", color: meta.color)
                                    }
                                }
                            }
                            .padding(20)
                            .background(meta.bg)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(meta.color.opacity(0.13), lineWidth: 1))
                        } else {
                            HStack(spacing: 14) {
                                Image(systemName: "person.fill.questionmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(C.faint)
                                Text("아직 컨디션 측정 전이에요.\n측정 후 여기서 상태를 확인할 수 있어요.")
                                    .font(.system(size: 14))
                                    .foregroundColor(C.sub)
                                    .lineSpacing(3)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(C.card)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(C.line, lineWidth: 1))
                        }
                    }

                    // MARK: 기기 연결
                    sectionBlock("건강 데이터") {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(condition != nil ? C.lavender : Color(hex: "#F5F5F5"))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(condition != nil ? C.greenDeep : C.faint)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("HealthKit")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(C.ink)
                                Text(condition != nil ? "연동됨 · 데이터 읽는 중" : "데이터 없음 · 측정이 필요해요")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(condition != nil ? C.greenDeep : C.faint)
                            }
                            Spacer()
                            Circle()
                                .fill(condition != nil ? C.green : Color(hex: "#D0CDD0"))
                                .frame(width: 10, height: 10)
                                .shadow(color: condition != nil ? C.green.opacity(0.4) : .clear, radius: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(C.card)
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(C.line, lineWidth: 1))
                    }

                    // MARK: 검색 반경
                    sectionBlock("검색 반경") {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(C.sub)
                                Text("주변 카페를 찾을 거리를 설정하세요")
                                    .font(.system(size: 14))
                                    .foregroundColor(C.sub)
                            }
                            HStack(spacing: 8) {
                                ForEach(RadiusOption.allCases, id: \.rawValue) { option in
                                    Button(action: { radius = option }) {
                                        Text(option.label)
                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                            .foregroundColor(radius == option ? C.greenDeep : C.sub)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 42)
                                            .background(radius == option ? C.lavender : C.surface)
                                            .cornerRadius(13)
                                            .overlay(RoundedRectangle(cornerRadius: 13)
                                                .stroke(radius == option ? C.green : C.line, lineWidth: 1.5))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(C.card)
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(C.line, lineWidth: 1))
                    }

                    // MARK: 약관
                    sectionBlock("약관 및 정책") {
                        VStack(spacing: 0) {
                            legalRow(icon: "doc.text.fill", label: "개인정보처리방침", url: "https://focusspot-web.vercel.app/privacy")
                            Divider().padding(.horizontal, 20)
                            legalRow(icon: "doc.fill", label: "서비스 이용약관", url: "https://focusspot-web.vercel.app/terms")
                        }
                        .background(C.card)
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(C.line, lineWidth: 1))
                    }

                    // MARK: 계정
                    sectionBlock("계정") {
                        Button(action: onSignOut) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                    .foregroundColor(C.rose)
                                Text("로그아웃")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(C.rose)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(C.faint)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(C.card)
                            .cornerRadius(18)
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(C.line, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

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

    @ViewBuilder
    private func legalRow(icon: String, label: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(C.sub)
                    Text(label)
                        .font(.system(size: 15))
                        .foregroundColor(C.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(C.faint)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    @ViewBuilder
    private func sectionBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(C.faint)
                .kerning(1.5)
                .textCase(.uppercase)
            content()
        }
    }

    private func healthCard(value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(C.sub)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.65))
        .cornerRadius(14)
    }
}

// MARK: - AsyncImageView
struct AsyncImageView: View {
    let url: URL?

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    fallbackAvatar
                }
            }
        } else {
            fallbackAvatar
        }
    }

    private var fallbackAvatar: some View {
        ZStack {
            Circle().fill(C.grad)
            Text("U")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
