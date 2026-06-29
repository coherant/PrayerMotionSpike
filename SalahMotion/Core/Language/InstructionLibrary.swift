import Foundation

// MARK: - Instruction ID

enum InstructionID: String {
    case i1  = "I-1"
    case i2  = "I-2"
    case i3  = "I-3"
    case i4  = "I-4"
    case i5  = "I-5"
    case i6  = "I-6"
    case i7  = "I-7"
    case i8  = "I-8"
    case i9  = "I-9"
    case i10 = "I-10"
    case i11 = "I-11"
    case i12 = "I-12"
    case i13 = "I-13"
    case i14 = "I-14"
    case i15 = "I-15"
    case i16 = "I-16"
    case i17 = "I-17"
    case i18 = "I-18"
    case i19 = "I-19"
    case i20 = "I-20"
    case i21 = "I-21"
    case i22 = "I-22"
    case i23 = "I-23"
    case i24 = "I-24"
    case i25 = "I-25"

    // Calibration coaching (entry / exit "get ready" / reprompt / hold). Same
    // movement-guidance family as I-1…I-25; previously hardcoded in the calibration
    // sequence. See PrayerSequence.CalibrationSequenceGenerator.
    case i26 = "I-26", i27 = "I-27", i28 = "I-28", i29 = "I-29", i30 = "I-30"
    case i31 = "I-31", i32 = "I-32", i33 = "I-33", i34 = "I-34", i35 = "I-35"
    case i36 = "I-36", i37 = "I-37", i38 = "I-38", i39 = "I-39", i40 = "I-40"
    case i41 = "I-41", i42 = "I-42", i43 = "I-43", i44 = "I-44", i45 = "I-45"
    case i46 = "I-46", i47 = "I-47", i48 = "I-48", i49 = "I-49", i50 = "I-50"
    case i51 = "I-51", i52 = "I-52"
}

// MARK: - Instruction Library
// Source of truth: SalahMotion/Resources/instructions.json
// Spec: docs/guided/instructions.md
// Spoken movement guidance (entry / reprompt) for the guided prayer sequence.
// Language-aware: English is the canonical base; turkish/arabic fall back to English
// when a translation is absent. (German is carried in the data for the recording brief
// but has no `Language` case yet.) To add or edit an instruction, update instructions.json.
// To add a new ID, add one case to InstructionID above and one entry in instructions.json.

enum InstructionLibrary {

    private struct Entry: Decodable {
        let id: String
        let instruction: String   // English (canonical base)
        let arabic: String?
        let turkish: String?
        let german: String?
    }

    private struct Payload: Decodable {
        let instructions: [Entry]
    }

    private static let cache: [String: Entry] = {
        guard
            let url  = Bundle.main.url(forResource: "instructions", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else {
            assertionFailure("instructions.json missing or malformed")
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: payload.instructions.map { ($0.id, $0) })
    }()

    /// Guidance text in the chosen language (defaults English). tr/ar fall back to
    /// English when a translation is absent.
    static func text(_ id: InstructionID, _ language: Language = UserPreferences.shared.guidanceLanguage) -> String {
        guard let e = cache[id.rawValue] else {
            assertionFailure("Instruction \(id.rawValue) not found in instructions.json")
            return ""
        }
        switch language {
        case .english: return e.instruction
        case .turkish: return e.turkish ?? e.instruction
        case .arabic:  return e.arabic ?? e.instruction
        }
    }

    /// Templated instruction (e.g. `I-25` "Give your niyet for {prayer}").
    static func text(_ id: InstructionID, _ language: Language = UserPreferences.shared.guidanceLanguage, prayer: String) -> String {
        text(id, language).replacingOccurrences(of: "{prayer}", with: prayer)
    }

    // Reverse map for audio resolution: spoken text → id, per language. Built from the
    // SAME source as text(_:_:), so any string produced by text(id, lang) maps back to
    // id (drift-free). Templated text (I-25 after {prayer} substitution) won't round-trip
    // → nil → TTS, which is correct (it can't be a single recording).
    private static let reverse: [String: [String: String]] = {   // [langRaw: [text: id]]
        var map: [String: [String: String]] = [:]
        for lang in Language.allCases {
            var m: [String: String] = [:]
            for id in cache.keys {
                guard let iid = InstructionID(rawValue: id) else { continue }
                m[text(iid, lang)] = id
            }
            map[lang.rawValue] = m
        }
        return map
    }()

    /// The instruction id whose `text(_, language)` equals `spoken`, if any — lets the
    /// speaker resolve a recorded guidance clip from already-rendered speech.
    static func instructionID(matching spoken: String, _ language: Language) -> InstructionID? {
        reverse[language.rawValue]?[spoken].flatMap(InstructionID.init(rawValue:))
    }
}
