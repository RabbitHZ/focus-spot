import SwiftUI
import GoogleSignIn

@MainActor
class AuthManager: ObservableObject {
    @Published var isSignedIn: Bool = false

    init() {
        isSignedIn = UserDefaults.standard.string(forKey: "focusspot_token") != nil
    }

    func signIn(presenting viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }
        try await APIClient.shared.loginWithGoogle(idToken: idToken)
        isSignedIn = true
    }

    func signOut() async {
        GIDSignIn.sharedInstance.signOut()
        await APIClient.shared.logout()
        isSignedIn = false
    }

    func restorePreviousSignIn() async {
        guard UserDefaults.standard.string(forKey: "focusspot_token") != nil else { return }
        // 저장된 토큰이 있으면 GIDSignIn도 복구 시도
        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        } catch {
            // 복구 실패 시 토큰 삭제
            await APIClient.shared.logout()
            isSignedIn = false
        }
    }
}

enum AuthError: LocalizedError {
    case missingToken

    var errorDescription: String? {
        "Google 로그인에서 ID 토큰을 가져올 수 없습니다."
    }
}
