import SwiftUI

struct AsyncProfileImage: View {
    let url: URL?
    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Circle().fill(C.grad)
                }
            }
        } else {
            Circle().fill(C.grad)
        }
    }
}

private let tagMeta: [String: (label: String, icon: String)] = {
    var dict = [String: (label: String, icon: String)]()
    for t in cafeFilterTags { dict[t.key] = (t.label, t.icon) }
    dict["quiet"]          = ("조용함", "speaker.slash.fill")
    dict["moderate-noise"] = ("보통",   "speaker.wave.2.fill")
    dict["lively"]         = ("활기참", "speaker.wave.3.fill")
    return dict
}()

struct CafeListView: View {
    let cafes: [CafeCard]
    let isLoading: Bool
    var error: String? = nil
    let condition: ConditionResult?
    let onSelect: (CafeCard) -> Void
    let onProfile: () -> Void
    let onRemeasure: () -> Void
    @EnvironmentObject private var auth: AuthManager

    private var modeLabel: String {
        switch condition?.mode {
        case "focus":     return "집중"
        case "drowsy":    return "졸림"
        case "fatigue":   return "피로"
        case "energized": return "활기"
        default:          return "회복"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("추천 카페")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(C.ink)
                    Text("지금 컨디션에 딱 맞는 곳")
                        .font(.system(size: 14))
                        .foregroundColor(C.sub)
                }
                Spacer()
                HStack(spacing: 10) {
                    if condition != nil {
                        HStack(spacing: 7) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundColor(C.rose)
                            Text(modeLabel)
                                .font(.system(size: 12.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(C.rose)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(C.pinkBg)
                        .cornerRadius(99)
                    }
                    Button(action: onRemeasure) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(C.sub)
                            .frame(width: 36, height: 36)
                            .background(C.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(C.line, lineWidth: 1))
                    }
                    Button(action: onProfile) {
                        AsyncProfileImage(url: auth.userImageURL)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)
            .padding(.bottom, 18)
            .background(C.card)
            .overlay(Rectangle().fill(C.line).frame(height: 1), alignment: .bottom)

            if isLoading {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(C.green)
                    Text("SEARCHING…")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(C.faint)
                        .kerning(1)
                }
                Spacer()
            } else if let error {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(C.rose)
                    Text("카페를 불러오지 못했어요")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(C.ink)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(C.sub)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else if cafes.isEmpty {
                Spacer()
                Text("주변 카페를 찾지 못했어요.\n반경을 넓혀보세요.")
                    .font(.system(size: 15))
                    .foregroundColor(C.sub)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 13) {
                        ForEach(Array(cafes.enumerated()), id: \.element.id) { i, cafe in
                            CafeCardRow(cafe: cafe, isBest: i == 0)
                                .onTapGesture { onSelect(cafe) }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(C.surface.ignoresSafeArea())
    }
}

struct CafeCardRow: View {
    let cafe: CafeCard
    let isBest: Bool

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isBest ? AnyShapeStyle(C.grad) : AnyShapeStyle(C.lavender))
                    .frame(width: 64, height: 64)
                CoffeeIcon(color: isBest ? C.ink : C.greenDeep, size: 26)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(cafe.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(C.ink)
                    if isBest {
                        Text("BEST")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(C.green)
                            .cornerRadius(6)
                    }
                }
                Text(cafe.distanceM < 1000 ? "\(cafe.distanceM)m" : String(format: "%.1fkm", Double(cafe.distanceM)/1000))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(C.faint)

                HStack(spacing: 6) {
                    if let nl = cafe.noiseLevel, let meta = tagMeta[nl] {
                        EmojiTagBadge(icon: meta.icon, label: meta.label)
                    }
                    ForEach(cafe.workTags.prefix(2), id: \.self) { tag in
                        if let meta = tagMeta[tag] {
                            EmojiTagBadge(icon: meta.icon, label: meta.label)
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(cafe.matchPct)")
                    .font(.system(size: 19, weight: .bold, design: .monospaced))
                    .foregroundColor(C.rose)
                Text("MATCH %")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(C.faint)
                    .kerning(0.4)
            }
        }
        .padding(14)
        .background(C.card)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(isBest ? C.green : C.line, lineWidth: 1))
        .shadow(color: isBest ? C.green.opacity(0.16) : .clear, radius: 13, y: 5)
    }
}

struct CoffeeIcon: View {
    var color: Color = C.greenDeep
    var size: CGFloat = 26

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width / 24
            let stroke = GraphicsContext.Shading.color(color)
            let lw: CGFloat = 1.8 * (size / 24)

            func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) {
                var p = Path()
                p.move(to: CGPoint(x: x1 * s, y: y1 * s))
                p.addLine(to: CGPoint(x: x2 * s, y: y2 * s))
                ctx.stroke(p, with: stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round))
            }

            // 컵 본체: M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z
            var cup = Path()
            cup.move(to: CGPoint(x: 2 * s, y: 8 * s))
            cup.addLine(to: CGPoint(x: 18 * s, y: 8 * s))
            cup.addLine(to: CGPoint(x: 18 * s, y: 17 * s))
            cup.addQuadCurve(to: CGPoint(x: 14 * s, y: 21 * s), control: CGPoint(x: 18 * s, y: 21 * s))
            cup.addLine(to: CGPoint(x: 6 * s, y: 21 * s))
            cup.addQuadCurve(to: CGPoint(x: 2 * s, y: 17 * s), control: CGPoint(x: 2 * s, y: 21 * s))
            cup.closeSubpath()
            ctx.stroke(cup, with: stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))

            // 손잡이: M18 8h1a4 4 0 0 1 0 8h-1
            var handle = Path()
            handle.move(to: CGPoint(x: 18 * s, y: 8 * s))
            handle.addLine(to: CGPoint(x: 19 * s, y: 8 * s))
            handle.addQuadCurve(to: CGPoint(x: 19 * s, y: 16 * s), control: CGPoint(x: 23 * s, y: 12 * s))
            handle.addLine(to: CGPoint(x: 18 * s, y: 16 * s))
            ctx.stroke(handle, with: stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))

            // 김 세 줄
            line(6, 1, 6, 4)
            line(10, 1, 10, 4)
            line(14, 1, 14, 4)
        }
        .frame(width: size, height: size)
    }
}

struct TagBadge: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(label).font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(C.greenDeep)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(C.lavender)
        .cornerRadius(7)
    }
}

struct EmojiTagBadge: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(C.greenDeep)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(C.lavender)
        .cornerRadius(7)
    }
}
