import Foundation

enum PrayerPosition: String, Codable, CaseIterable, Identifiable, Equatable {
    case standing = "Qiyam"
    case bowing = "Ruku"
    case prostration = "Sujud"
    case sitting = "Jalsa"
    case unknown = "Unknown"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var emoji: String {
        switch self {
        case .standing: return "🧍"
        case .bowing: return "🫄"
        case .prostration: return "🙇"
        case .sitting: return "🧎"
        case .unknown: return "❓"
        }
    }

    // Placeholder thresholds — spike will derive real values from logged data
    static func classify(pitch: Double, roll: Double) -> PrayerPosition {
        .unknown
    }
}
