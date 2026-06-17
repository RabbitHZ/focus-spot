import Foundation

actor APIClient {
    static let shared = APIClient(baseURL: "http://localhost:8000")

    private let baseURL: URL
    private let session: URLSession
    private var token: String?

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(baseURL: String) {
        self.baseURL = URL(string: baseURL)!
        self.session = URLSession.shared
        self.token = UserDefaults.standard.string(forKey: "focusspot_token")
    }

    var isAuthenticated: Bool { token != nil }

    // MARK: - Auth

    func loginWithGoogle(idToken: String) async throws {
        struct Body: Encodable { let id_token: String }
        struct Response: Decodable { let access_token: String }
        let res: Response = try await post("/api/auth/google", body: Body(id_token: idToken), requiresAuth: false)
        self.token = res.access_token
        UserDefaults.standard.set(res.access_token, forKey: "focusspot_token")
    }

    func logout() {
        token = nil
        UserDefaults.standard.removeObject(forKey: "focusspot_token")
    }

    // MARK: - Health sync

    func syncHealth(_ snapshot: HealthSnapshot) async throws {
        try await postVoid("/api/health/sync", body: snapshot)
    }

    // MARK: - HTTP helpers

    private func post<B: Encodable, R: Decodable>(_ path: String, body: B, requiresAuth: Bool = true) async throws -> R {
        let req = try buildRequest(path: path, method: "POST", body: body, requiresAuth: requiresAuth)
        let (data, response) = try await session.data(for: req)
        try validateResponse(response, data: data)
        return try decoder.decode(R.self, from: data)
    }

    private func postVoid<B: Encodable>(_ path: String, body: B) async throws {
        let req = try buildRequest(path: path, method: "POST", body: body, requiresAuth: true)
        let (data, response) = try await session.data(for: req)
        try validateResponse(response, data: data)
    }

    private func buildRequest<B: Encodable>(path: String, method: String, body: B, requiresAuth: Bool) throws -> URLRequest {
        var req = URLRequest(url: baseURL.appending(path: path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requiresAuth, let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try encoder.encode(body)
        return req
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            struct ErrorBody: Decodable { let detail: String? }
            let detail = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.detail ?? "알 수 없는 오류"
            throw APIError.serverError(statusCode: http.statusCode, message: detail)
        }
    }
}

enum APIError: LocalizedError {
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .serverError(let code, let msg):
            return "서버 오류 (\(code)): \(msg)"
        }
    }
}
