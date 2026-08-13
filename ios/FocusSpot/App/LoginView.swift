import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var isLoading = false
    @State private var errorMessage: String?
    let onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            C.card.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Image("logo_gem_final")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .padding(.bottom, 26)

                    Text("FocusSpot 시작하기")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(C.ink)
                        .padding(.bottom, 12)

                    Text("구글 계정으로 간편하게 로그인하세요.\n별도 비밀번호는 필요 없어요.")
                        .font(.system(size: 15.5))
                        .foregroundColor(C.sub)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.bottom, 22)

                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(C.greenDeep)
                        Text("FocusSpot은 비밀번호를 저장하지 않아요")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(C.greenDeep)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(C.lavender)
                    .cornerRadius(99)
                }

                Spacer()

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }

                VStack(spacing: 14) {
                    Button(action: signIn) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView().tint(Color(hex: "#1F1F1F"))
                            } else {
                                GoogleGIcon()
                            }
                            Text("Google로 로그인")
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#1F1F1F"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(C.line, lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    }
                    .disabled(isLoading)

                    Text("다른 로그인 방법은 제공하지 않아요")
                        .font(.system(size: 12.5))
                        .foregroundColor(C.faint)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 44)
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
