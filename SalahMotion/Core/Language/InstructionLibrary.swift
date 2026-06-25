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
}

// MARK: - Instruction Library
// Source of truth: SalahMotion/Resources/instructions.json
// Spec: docs/guided/instructions.md
// Spoken movement guidance (entry / reprompt) for the guided prayer sequence.
// English-only by design — these are instructions, not prayers (no Language param).
// To add or edit an instruction, update instructions.json only — no Swift changes needed.
// To add a new ID, add one case to InstructionID above and one entry in instructions.json.

enum InstructionLibrary {

    private struct Entry: Decodable {
        let id: String
        let instruction: String
    }

    private struct Payload: Decodable {
        let instructions: [Entry]
    }

    private static let cache: [String: String] = {
        guard
            let url  = Bundle.main.url(forResource: "instructions", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else {
            assertionFailure("instructions.json missing or malformed")
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: payload.instructions.map { ($0.id, $0.instruction) })
    }()

    static func text(_ id: InstructionID) -> String {
        guard let instruction = cache[id.rawValue] else {
            assertionFailure("Instruction \(id.rawValue) not found in instructions.json")
            return ""
        }
        return instruction
    }

    /// Resolves a templated instruction (e.g. `I-25` "Give your niyet for {prayer}"),
    /// substituting `prayer` for the `{prayer}` placeholder.
    static func text(_ id: InstructionID, prayer: String) -> String {
        text(id).replacingOccurrences(of: "{prayer}", with: prayer)
    }
}
