import Foundation

struct HealthSnapshot: Codable {
    var sleepDurationHours: Double?
    var deepSleepHours: Double?
    var remSleepHours: Double?
    var lightSleepHours: Double?
    var restingHeartRate: Double?
    var avgHeartRate: Double?
    var respiratoryRate: Double?
    var spo2: Double?
    var stepCount: Int?
    var recordedAt: Date

    enum CodingKeys: String, CodingKey {
        case sleepDurationHours = "sleep_duration_hours"
        case deepSleepHours = "deep_sleep_hours"
        case remSleepHours = "rem_sleep_hours"
        case lightSleepHours = "light_sleep_hours"
        case restingHeartRate = "resting_heart_rate"
        case avgHeartRate = "avg_heart_rate"
        case respiratoryRate = "respiratory_rate"
        case spo2
        case stepCount = "step_count"
        case recordedAt = "recorded_at"
    }
}
