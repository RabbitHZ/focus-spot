import SwiftUI

struct CafeDetailView: View {
    let cafe: CafeCard
    let onBack: () -> Void

    @State private var detail: CafeDetail? = nil
    @State private var isLoadingDetail = true

    var body: some View {
        ZStack(alignment: .bottom) {
            C.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // 헤더
                ZStack(alignment: .bottomTrailing) {
                    C.grad.frame(height: 210)
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 78))
                        .foregroundColor(C.ink.opacity(0.55))
                        .padding(.bottom, 18)
                        .padding(.trailing, 22)
                }
                .frame(maxWidth: .infinity)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // 이름 + 주소 + 거리
                        Text(cafe.name)
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(C.ink)
                            .padding(.bottom, 6)

                        HStack(spacing: 8) {
                            Text(cafe.address)
                                .font(.system(size: 14))
                                .foregroundColor(C.sub)
                            Rectangle().fill(C.line).frame(width: 1, height: 14)
                            Text(cafe.distanceM < 1000
                                 ? "\(cafe.distanceM)m"
                                 : String(format: "%.1fkm", Double(cafe.distanceM) / 1000))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(C.greenDeep)
                        }
                        .padding(.bottom, 14)

                        // 평점 / 리뷰 수 / 전화번호 (상세 API)
                        if isLoadingDetail {
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(C.line)
                                    .frame(width: 80, height: 18)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(C.line)
                                    .frame(width: 60, height: 18)
                            }
                            .padding(.bottom, 16)
                        } else {
                            HStack(spacing: 14) {
                                if let rating = detail?.rating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#D48A00"))
                                        Text(String(format: "%.1f", rating))
                                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                            .foregroundColor(C.ink)
                                        if let count = detail?.reviewCount {
                                            Text("(\(count))")
                                                .font(.system(size: 13))
                                                .foregroundColor(C.sub)
                                        }
                                    }
                                }
                                if let phone = detail?.phone, !phone.isEmpty {
                                    Button {
                                        if let url = URL(string: "tel://\(phone.filter { $0.isNumber })") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "phone.fill")
                                                .font(.system(size: 12))
                                            Text(phone)
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(C.greenDeep)
                                    }
                                }
                            }
                            .padding(.bottom, 16)
                        }

                        // 매칭 카드
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 10) {
                                VStack(spacing: 2) {
                                    Text("\(cafe.matchPct)")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(C.rose)
                                    Text("MATCH %")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(C.rose)
                                        .kerning(0.3)
                                }
                                .frame(width: 46, height: 46)
                                .background(C.pinkBg)
                                .cornerRadius(12)

                                Text("지금 당신에게\n\(cafe.matchPct)% 잘 맞아요")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(C.ink)
                                    .lineSpacing(2)
                            }

                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(C.green)
                                    .padding(.top, 1)
                                Text(cafe.recommendationReason)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(C.greenDeep)
                                    .lineSpacing(3)
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(C.lavender)
                            .cornerRadius(13)
                        }
                        .padding(16)
                        .background(C.card)
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(C.line, lineWidth: 1))
                        .padding(.bottom, 16)

                        // 공간 / 조명 (상세 API)
                        if !isLoadingDetail, detail?.spaceType != nil || detail?.lighting != nil {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("공간 & 분위기")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(C.faint)
                                    .kerning(1.2)
                                    .textCase(.uppercase)

                                HStack(spacing: 8) {
                                    if let space = detail?.spaceType, let meta = spaceTypeMeta[space] {
                                        InfoChip(icon: meta.icon, label: meta.label)
                                    }
                                    if let light = detail?.lighting, let meta = lightingMeta[light] {
                                        InfoChip(icon: meta.icon, label: meta.label)
                                    }
                                }
                            }
                            .padding(.bottom, 16)
                        }

                        // 태그 (카드 데이터 + 상세 API 통합)
                        let allTags: [(icon: String, label: String)] = {
                            var tags: [(icon: String, label: String)] = []
                            let noiseKey = detail?.noiseLevel ?? cafe.noiseLevel
                            if let nl = noiseKey, let meta = workTagMeta[nl] {
                                tags.append(meta)
                            }
                            let allWorkTags = detail != nil ? (detail?.workTags ?? []) : cafe.workTags
                            for t in allWorkTags.prefix(5) {
                                if let meta = workTagMeta[t] { tags.append(meta) }
                            }
                            return tags
                        }()

                        if !allTags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(Array(allTags.enumerated()), id: \.offset) { _, meta in
                                    TagBadge(icon: meta.icon, label: meta.label)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }

            // 하단 버튼
            VStack(spacing: 0) {
                LinearGradient(colors: [C.surface.opacity(0), C.surface], startPoint: .top, endPoint: .bottom)
                    .frame(height: 40)
                HStack(spacing: 12) {
                    let urlStr = detail?.kakaoUrl ?? cafe.kakaoUrl
                    if let urlStr, let url = URL(string: urlStr) {
                        Link(destination: url) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 20))
                                .foregroundColor(C.ink)
                                .frame(width: 56, height: 56)
                                .background(C.card)
                                .cornerRadius(18)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(C.line, lineWidth: 1))
                        }
                    }
                    PrimaryButton(label: "길찾기 시작", icon: "location.fill") {
                        let urlStr = detail?.kakaoUrl ?? cafe.kakaoUrl
                        if let urlStr, let url = URL(string: urlStr) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .background(C.surface)
            }
        }
        .overlay(alignment: .topLeading) {
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
        .ignoresSafeArea(edges: .top)
        .task {
            detail = try? await APIClient.shared.getCafeDetail(id: cafe.id)
            isLoadingDetail = false
        }
    }
}

private struct InfoChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(C.ink)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(C.card)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(C.line, lineWidth: 1))
    }
}

private let workTagMeta: [String: (icon: String, label: String)] = {
    var dict = [String: (icon: String, label: String)]()
    for t in cafeFilterTags { dict[t.key] = (t.icon, t.label) }
    dict["quiet"]          = ("speaker.slash.fill",  "조용함")
    dict["moderate-noise"] = ("speaker.wave.2.fill", "보통")
    dict["lively"]         = ("speaker.wave.3.fill", "활기참")
    return dict
}()

private let spaceTypeMeta: [String: (icon: String, label: String)] = [
    "spacious":      ("rectangle.expand.vertical", "넓은 공간"),
    "cozy":          ("house.fill",                "아늑함"),
    "private-booth": ("person.crop.square",        "개인 부스"),
    "counter-seat":  ("chair",                     "카운터석"),
]

private let lightingMeta: [String: (icon: String, label: String)] = [
    "bright":        ("sun.max.fill",    "밝은 조명"),
    "dim":           ("moon.fill",       "은은한 조명"),
    "natural-light": ("light.min",       "자연광"),
]
