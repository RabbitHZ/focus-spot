import SwiftUI

enum C {
    static let ink        = Color(hex: "#33272E")
    static let sub        = Color(hex: "#7A6E75")
    static let faint      = Color(hex: "#B4A9AF")
    static let surface    = Color(hex: "#F8F3F5")
    static let card       = Color.white
    static let lavender   = Color(hex: "#F4E9EF")
    static let line       = Color(hex: "#EFE3E9")
    static let green      = Color(hex: "#46B97A")
    static let greenDeep  = Color(hex: "#34A267")
    static let rose       = Color(hex: "#CE4A78")
    static let roseSoft   = Color(hex: "#E0608A")
    static let pink       = Color(hex: "#F3A0BE")
    static let pinkBg     = Color(hex: "#FCE3EC")

    static let grad = LinearGradient(
        colors: [Color(hex: "#5FBE82"), Color(hex: "#E6CBD6"), Color(hex: "#E0608A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8)  & 0xFF) / 255
        let b = Double( val        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct PrimaryButton: View {
    let label: String
    var icon: String? = nil
    var bg: Color = C.ink
    var fgColor: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
                Text(label).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(bg)
            .foregroundColor(fgColor)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.18), radius: 13, y: 5)
        }
    }
}

struct KickLabel: View {
    let text: String
    var color: Color = C.faint

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .kerning(2)
            .textCase(.uppercase)
            .foregroundColor(color)
    }
}
