import SwiftUI

struct WelcomeView: View {
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            C.grad.ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 220, height: 220)
                .offset(x: 90, y: -180)

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 0) {
                    Image("logo_gem_final")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .cornerRadius(22)
                        .padding(.bottom, 32)

                    KickLabel(text: "FOCUSSPOT", color: C.ink.opacity(0.6))
                        .padding(.bottom, 16)

                    Text("오늘의 컨디션에\n맞는 카페를\n찾아드려요.")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(C.ink)
                        .lineSpacing(4)
                        .padding(.bottom, 18)

                    Text("HealthKit의 건강 데이터를 읽어\n지금 집중하기 좋은 공간을 추천해요.")
                        .font(.system(size: 16))
                        .foregroundColor(C.ink.opacity(0.65))
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 34)

                Spacer()

                VStack(spacing: 14) {
                    Button(action: onLogin) {
                        HStack(spacing: 12) {
                            GoogleGIcon()
                            Text("Google로 계속하기")
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#1F1F1F"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.18), radius: 13, y: 5)
                    }

                    Text("계속하면 FocusSpot의 **약관**과 **개인정보 처리방침**에 동의하게 됩니다.")
                        .font(.system(size: 12.5))
                        .foregroundColor(C.ink.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct GoogleGIcon: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 24, height: 24)
            Text("G")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#4285F4"))
        }
    }
}
