import Foundation

public enum PrayerPace: String, CaseIterable, Identifiable, Equatable {
    case slow   = "slow"
    case medium = "medium"
    case fast   = "fast"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .slow:   return "Slow"
        case .medium: return "Medium"
        case .fast:   return "Fast"
        }
    }

    /// Pause in seconds between prayer utterances in .motion phases
    public var pauseDuration: Double {
        switch self {
        case .slow:   return 4.0
        case .medium: return 2.5
        case .fast:   return 1.0
        }
    }
}
