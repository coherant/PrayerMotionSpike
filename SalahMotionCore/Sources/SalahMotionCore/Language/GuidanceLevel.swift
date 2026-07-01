import Foundation

public enum GuidanceLevel: String, CaseIterable, Identifiable {
    case full   = "full"
    case prayer = "prayer"
    case silent = "silent"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .full:   return "Full guidance"
        case .prayer: return "Prayer only"
        case .silent: return "Silent guiding"
        }
    }

    public var subtitle: String {
        switch self {
        case .full:   return "Instructions + prayers"
        case .prayer: return "Recitation, no cues"
        case .silent: return "Gentle motion only"
        }
    }

    /// Whether the reprompt countdown pie should be shown
    public var showsTimer: Bool { self != .silent }

    /// Whether entry speech (movement instructions) plays
    public var playsEntryGuidance: Bool { self == .full }

    /// Whether prayer utterances play
    public var playsPrayers: Bool { self != .silent }
}
