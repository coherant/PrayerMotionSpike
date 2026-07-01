import Foundation

public enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"
    case arabic  = "ar"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .arabic:  return "عربي"
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }

    /// BCP-47 code passed to AVSpeechSynthesisVoice
    public var voiceCode: String {
        switch self {
        case .arabic:  return "ar-SA"
        case .turkish: return "tr-TR"
        case .english: return "en-US"
        }
    }
}
