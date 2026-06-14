import Foundation

struct APIClient {
    private let baseURL: URL
    private let session: URLSession
    private var token: String?

    init(baseURL: String = "https://api.focusspot.app") {
        self.baseURL = URL(string: baseURL)!
        self.session = URLSession.shared
    }

    mutating func setToken(_ token: String) {
        self.token = token
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> String {
        struct Body: Encodable { let email, password: String }
        struct Response: Decodable { let access_token: String }
        let res: Response = try await post("/api/auth/login", body: Body(email: email, password: password))
        return res.access_token
    }

    // MARK: - Health sync

    func syncHealth(_ snapshot: HealthSnapshot) async throws {
        _ = try await postRaw("/api/health/sync", body: snapshot)
    }

    // MARK: - HTTP helpers

    private func post<B: Encodable, R: Decodable>(_ path: String, body: B) async throws -> R {
        var req = URLRequest(url: baseURL.appending(path: path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode(R.self, from: data)
    }

    private func postRaw<B: Encodable>(_ path: String, body: B) async throws -> Data {
        var req = URLRequest(url: baseURL.appending(path: path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        req.httpBody = try encoder.encode(body)
        let (data, _) = try await session.data(for: req)
        return data
    }
}
