import Foundation

struct ConditionResult: Decodable {
    let mode: String
    let label: String
    let confidence: Int
    let cafeHint: String
    let heartRate: Double?
    let sleepHours: Double?
    let spo2: Double?
    let stepCount: Int?

    enum CodingKeys: String, CodingKey {
        case mode, label, confidence
        case cafeHint = "cafe_hint"
        case heartRate = "heart_rate"
        case sleepHours = "sleep_hours"
        case spo2
        case stepCount = "step_count"
    }
}

struct CafeCard: Decodable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let distanceM: Int
    let noiseLevel: String?
    let workTags: [String]
    let kakaoUrl: String?
    let recommendationReason: String
    let matchPct: Int

    enum CodingKeys: String, CodingKey {
        case id, name, address
        case distanceM = "distance_m"
        case noiseLevel = "noise_level"
        case workTags = "work_tags"
        case kakaoUrl = "kakao_url"
        case recommendationReason = "recommendation_reason"
        case matchPct = "match_pct"
    }
}

struct CafeDetail: Decodable {
    let id: Int
    let name: String
    let address: String
    let phone: String?
    let kakaoUrl: String?
    let noiseLevel: String?
    let lighting: String?
    let spaceType: String?
    let workTags: [String]
    let rating: Double?
    let reviewCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, address, phone
        case kakaoUrl = "kakao_url"
        case noiseLevel = "noise_level"
        case lighting
        case spaceType = "space_type"
        case workTags = "work_tags"
        case rating
        case reviewCount = "review_count"
    }
}

struct RecommendResponse: Decodable {
    let mode: String
    let modeLabel: String
    let cafes: [CafeCard]

    enum CodingKeys: String, CodingKey {
        case mode
        case modeLabel = "mode_label"
        case cafes
    }
}
