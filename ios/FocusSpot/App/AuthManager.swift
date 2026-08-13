import SwiftUI
import GoogleSignIn

@MainActor
class AuthManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userImageURL: URL? = nil

    init() {
        isSignedIn = UserDefaults.standard.string(forKey: "focusspot_token") != nil
        userName = UserDefaults.standard.string(forKey: "user_name") ?? ""
        userEmail = UserDefaults.standard.string(forKey: "user_email") ?? ""
        if let urlStr = UserDefaults.standard.string(forKey: "user_image") {
            userImageURL = URL(string: urlStr)
        }
    }

    func signIn(presenting viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }
        try await APIClient.shared.loginWithGoogle(idToken: idToken)

        let profile = result.user.profile
        userName = profile?.name ?? ""
        userEmail = profile?.email ?? ""
        userImageURL = profile?.imageURL(withDimension: 128)

        UserDefaults.standard.set(userName, forKey: "user_name")
        UserDefaults.standard.set(userEmail, forKey: "user_email")
        UserDefaults.standard.set(userImageURL?.absoluteString, forKey: "user_image")

        isSignedIn = true
    }

    func signOut() async {
        GIDSignIn.sharedInstance.signOut()
        await APIClient.shared.logout()
        isSignedIn = false
    }

    func restorePreviousSignIn() async {
        guard UserDefaults.standard.string(forKey: "focusspot_token") != nil else { return }
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            // idToken 갱신 후 백엔드 재로그인
            try await user.refreshTokensIfNeeded()
            guard let idToken = user.idToken?.tokenString else {
                await APIClient.shared.logout()
                isSignedIn = false
                return
            }
            try await APIClient.shared.loginWithGoogle(idToken: idToken)
            isSignedIn = true
        } catch {
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
