// MARK: - Phase mode

enum PhaseMode: String {
    case auto         // speak entry, play prayers, speak exit, advance immediately
    case timed        // speak entry, play prayers with durations, speak exit
    case motion       // speak entry, play prayers, wait indefinitely for motion, speak exit
    case timedMotion  // speak entry, play prayers with durations (motion detection runs throughout), speak exit
}

// MARK: - Motion triggers

enum MotionTrigger: CustomStringConvertible {
    case ruku
    case sujood
    case upright       // standing or sitting — disambiguated by sequence position
    case headTurnRight
    case headTurnLeft

    var description: String {
        switch self {
        case .ruku:          return "ruku"
        case .sujood:        return "sujood"
        case .upright:       return "upright"
        case .headTurnRight: return "head turn right"
        case .headTurnLeft:  return "head turn left"
        }
    }
}

// MARK: - State IDs (15-phase master sequence)

enum PrayerStateID: String {
    case qiyamStart
    case rukuFirst
    case qiyamAfterRukuFirst
    case sujoodFirst
    case julusFirst
    case sujoodSecond
    case qiyamRakat2
    case rukuSecond
    case qiyamAfterRukuSecond
    case sujoodThird
    case julusSecond
    case sujoodFourth
    case julusTashahhud
    case tasleemRight
    case tasleemLeft
}

// MARK: - State definition

struct PrayerState {
    let id: PrayerStateID
    let mode: PhaseMode
    let displayLabel: String
    let entrySpeech: String?
    let prayers: [(utterance: String, duration: Double)]
    let exitSpeech: String?
    let motionTrigger: MotionTrigger?
    let repromptAudio: String?
    let repromptInterval: Double
    let capturesYawBaseline: Bool

    init(
        id: PrayerStateID,
        mode: PhaseMode,
        displayLabel: String,
        entrySpeech: String? = nil,
        prayers: [(utterance: String, duration: Double)] = [],
        exitSpeech: String? = nil,
        motionTrigger: MotionTrigger? = nil,
        repromptAudio: String? = nil,
        repromptInterval: Double = 8,
        capturesYawBaseline: Bool = false
    ) {
        self.id = id
        self.mode = mode
        self.displayLabel = displayLabel
        self.entrySpeech = entrySpeech
        self.prayers = prayers
        self.exitSpeech = exitSpeech
        self.motionTrigger = motionTrigger
        self.repromptAudio = repromptAudio
        self.repromptInterval = repromptInterval
        self.capturesYawBaseline = capturesYawBaseline
    }
}

// MARK: - Sensor smoothing

struct SensorReadings {
    private var pitches: [Double] = []
    private var rolls:   [Double] = []
    private var yaws:    [Double] = []
    private let windowSize: Int

    init(windowSize: Int = 7) { self.windowSize = windowSize }

    mutating func add(pitch: Double, roll: Double, yaw: Double) {
        pitches = Array((pitches + [pitch]).suffix(windowSize))
        rolls   = Array((rolls   + [roll]).suffix(windowSize))
        yaws    = Array((yaws    + [yaw]).suffix(windowSize))
    }

    var smoothedPitch: Double { pitches.isEmpty ? 0 : pitches.reduce(0, +) / Double(pitches.count) }
    var smoothedRoll:  Double { rolls.isEmpty   ? 0 : rolls.reduce(0, +)   / Double(rolls.count) }
    var smoothedYaw:   Double { yaws.isEmpty    ? 0 : yaws.reduce(0, +)    / Double(yaws.count) }
}

// MARK: - Sequence generators

// Calibration profile
// Source: docs/calibration/master-prayer-state-machine.md
//         docs/calibration/prayers-for-each-state-in-state-machine.md
//         docs/prayers/prayers.md

enum PrayerSequenceGenerator {

    static func generate() -> [PrayerState] { masterSequence() }

    private static func masterSequence() -> [PrayerState] { [

        // Position 1
        .init(id: .qiyamStart, mode: .auto,
              displayLabel: "Standing (Qiyam) - Start",
              entrySpeech: "Stand upright for Qiyam.",
              prayers: [("", 4.0)]),

        // Position 2
        .init(id: .rukuFirst, mode: .timedMotion,
              displayLabel: "Bowing (Ruku) - First",
              entrySpeech: "Bow forward into Ruku.",
              prayers: [("", 4.0)],
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku"),

        // Position 3
        .init(id: .qiyamAfterRukuFirst, mode: .timedMotion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 1)",
              entrySpeech: "Return to standing.",
              prayers: [("", 5.0)],
              motionTrigger: .upright,
              repromptAudio: "Please return to standing"),

        // Position 4
        .init(id: .sujoodFirst, mode: .timedMotion,
              displayLabel: "Prostration (Sujood) - First",
              entrySpeech: "Prostrate into Sujood.",
              prayers: [("", 5.0)],
              exitSpeech: "Allahu Akbar",
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood"),

        // Position 5
        .init(id: .julusFirst, mode: .timedMotion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 1)",
              entrySpeech: "Sit upright.",
              prayers: [("", 5.0)],
              exitSpeech: "Allahu Akbar",
              motionTrigger: .upright,
              repromptAudio: "Please sit up"),

        // Position 6
        .init(id: .sujoodSecond, mode: .timedMotion,
              displayLabel: "Prostration (Sujood) - Second",
              entrySpeech: "Prostrate into Sujood again.",
              prayers: [("", 5.0)],
              exitSpeech: "Allahu Akbar",
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again"),

        // Position 7
        .init(id: .qiyamRakat2, mode: .timedMotion,
              displayLabel: "Standing (Qiyam) - Rakat 2",
              entrySpeech: "Stand for the second rakat.",
              prayers: [("", 5.0)],
              exitSpeech: "Allahu Akbar",
              motionTrigger: .upright,
              repromptAudio: "Please stand for the next rakat"),

        // Position 8
        .init(id: .rukuSecond, mode: .timedMotion,
              displayLabel: "Bowing (Ruku) - Second",
              entrySpeech: "Bow forward into Ruku.",
              prayers: [("", 5.0)],
              exitSpeech: "Sami Allahu liman hamidah",
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku"),

        // Position 9 — yaw baseline captured here for Tasleem
        .init(id: .qiyamAfterRukuSecond, mode: .timedMotion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 2)",
              entrySpeech: "Return to standing.",
              prayers: [("", 5.0)],
              exitSpeech: "Allahu Akbar",
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              capturesYawBaseline: true),

        // Position 10
        .init(id: .sujoodThird, mode: .timedMotion,
              displayLabel: "Prostration (Sujood) - Third",
              entrySpeech: "Prostrate into Sujood.",
              prayers: [("", 5.0)],
              exitSpeech: "Allahu Akbar",
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood"),

        // Position 11
        .init(id: .julusSecond, mode: .timedMotion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 2)",
              entrySpeech: "Sit upright.",
              prayers: [("", 5.0)],
              exitSpeech: "Allahu Akbar",
              motionTrigger: .upright,
              repromptAudio: "Please sit up"),

        // Position 12
        .init(id: .sujoodFourth, mode: .timedMotion,
              displayLabel: "Prostration (Sujood) - Fourth",
              entrySpeech: "Prostrate into Sujood again.",
              prayers: [("", 5.0)],
              exitSpeech: "Allahu Akbar",
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again"),

        // Position 13
        .init(id: .julusTashahhud, mode: .timedMotion,
              displayLabel: "Sitting (Julus) - Tashahhud",
              entrySpeech: "Sit for Tashahhud.",
              prayers: [("", 5.0)],
              motionTrigger: .upright,
              repromptAudio: "Please sit for Tashahhud"),

        // Position 14
        .init(id: .tasleemRight, mode: .timedMotion,
              displayLabel: "Tasleem - Look Right",
              entrySpeech: "Turn your head to the right.",
              prayers: [("", 4.0)],
              motionTrigger: .headTurnRight,
              repromptAudio: "Please turn your head to the right"),

        // Position 15
        .init(id: .tasleemLeft, mode: .timedMotion,
              displayLabel: "Tasleem - Look Left",
              entrySpeech: "Turn your head to the left.",
              prayers: [("", 4.0)],
              motionTrigger: .headTurnLeft,
              repromptAudio: "Please turn your head to the left"),
    ] }
}

// Guided profile
// Source: docs/guided/master-prayer-state-machine.md
//         docs/guided/prayers-for-each-state-in-state-machine.md
//         docs/prayers/prayers.md

enum GuidedSequenceGenerator {

    // Prayer library — resolved from docs/prayers/prayers.md
    private static let P0  = "Allah Hoo-ekber"
    private static let P1  = "Glory be to Allah the most great!"
    private static let P2  = "Glory be to Allah the most high!"
    private static let P3  = "Allah hears those who praise him."
    private static let P4  = "O Allah, all praise is due onto you."
    private static let P5  = "O Allah, forgive me."
    private static let P6  = "Pease and blessing be onto you"
    private static let P7  = "All praise be to Allah, the lord of the worlds, the most compationate, the most merciful. Master of the day of judgement. You alone do we worship and you alone do we turn to for help. Guide us on the straight path, the path of those whom you have favoured and not the path of those who earn your anger, nor of those who go astray."
    private static let P8  = "All compliments, prayers and beauitiful expressions are for Allah. Please and blessing be upon you oh muhammad, and Allahs mercy and blessings. Pease be upon us, ans all righteous servants of Allah."
    private static let P9  = "Oh Allah, honor muhammad and muhammads family as you have honoured ismail and ismails family"
    private static let P10 = "Oh Allah, bless muhammad and muhammads family as you have bless ismail and ismails family"

    static func generate() -> [PrayerState] { masterSequence() }

    private static func masterSequence() -> [PrayerState] { [

        // Position 1
        .init(id: .qiyamStart, mode: .auto,
              displayLabel: "Standing (Qiyam) - Start",
              entrySpeech: "Listen to the Athan. Give niyet.",
              prayers: [
                  (P0, 3.0),
                  (P7, 20.0),
              ],
              exitSpeech: P0),

        // Position 2
        .init(id: .rukuFirst, mode: .timedMotion,
              displayLabel: "Bowing (Ruku) - First",
              prayers: [
                  (P1, 3.0),
                  (P1, 3.0),
                  (P1, 3.0),
              ],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku"),

        // Position 3
        .init(id: .qiyamAfterRukuFirst, mode: .timedMotion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 1)",
              prayers: [(P4, 4.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing"),

        // Position 4
        .init(id: .sujoodFirst, mode: .timedMotion,
              displayLabel: "Prostration (Sujood) - First",
              prayers: [
                  (P2, 3.0),
                  (P2, 3.0),
                  (P2, 3.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood"),

        // Position 5
        .init(id: .julusFirst, mode: .timedMotion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 1)",
              prayers: [
                  (P5, 3.0),
                  (P5, 3.0),
              ],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up"),

        // Position 6
        .init(id: .sujoodSecond, mode: .timedMotion,
              displayLabel: "Prostration (Sujood) - Second",
              prayers: [
                  (P2, 3.0),
                  (P2, 3.0),
                  (P2, 3.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again"),

        // Position 7
        .init(id: .qiyamRakat2, mode: .timedMotion,
              displayLabel: "Standing (Qiyam) - Rakat 2",
              prayers: [(P7, 20.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please stand for the next rakat"),

        // Position 8
        .init(id: .rukuSecond, mode: .timedMotion,
              displayLabel: "Bowing (Ruku) - Second",
              prayers: [
                  (P1, 3.0),
                  (P1, 3.0),
                  (P1, 3.0),
              ],
              exitSpeech: P3,
              motionTrigger: .ruku,
              repromptAudio: "Please bow into Ruku"),

        // Position 9 — yaw baseline captured here for Tasleem
        .init(id: .qiyamAfterRukuSecond, mode: .timedMotion,
              displayLabel: "Standing (Qiyam) - After Ruku (Rakat 2)",
              prayers: [(P4, 3.0)],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please return to standing",
              capturesYawBaseline: true),

        // Position 10
        .init(id: .sujoodThird, mode: .timedMotion,
              displayLabel: "Prostration (Sujood) - Third",
              prayers: [
                  (P2, 3.0),
                  (P2, 3.0),
                  (P2, 3.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood"),

        // Position 11
        .init(id: .julusSecond, mode: .timedMotion,
              displayLabel: "Sitting (Julus) - Between Prostrations (Rakat 2)",
              prayers: [
                  (P5, 3.0),
                  (P5, 3.0),
              ],
              exitSpeech: P0,
              motionTrigger: .upright,
              repromptAudio: "Please sit up"),

        // Position 12
        .init(id: .sujoodFourth, mode: .timedMotion,
              displayLabel: "Prostration (Sujood) - Fourth",
              prayers: [
                  (P2, 3.0),
                  (P2, 3.0),
                  (P2, 3.0),
              ],
              exitSpeech: P0,
              motionTrigger: .sujood,
              repromptAudio: "Please lower into Sujood again"),

        // Position 13
        .init(id: .julusTashahhud, mode: .timedMotion,
              displayLabel: "Sitting (Julus) - Tashahhud",
              prayers: [
                  (P8, 15.0),
                  (P9,  7.0),
                  (P10, 7.0),
              ],
              motionTrigger: .upright,
              repromptAudio: "Please sit for Tashahhud"),

        // Position 14
        .init(id: .tasleemRight, mode: .timedMotion,
              displayLabel: "Tasleem - Look Right",
              prayers: [(P6, 5.0)],
              motionTrigger: .headTurnRight,
              repromptAudio: "Please turn your head to the right"),

        // Position 15
        .init(id: .tasleemLeft, mode: .timedMotion,
              displayLabel: "Tasleem - Look Left",
              prayers: [(P6, 5.0)],
              exitSpeech: "Oh Allah, you are peace and pease comes from you",
              motionTrigger: .headTurnLeft,
              repromptAudio: "Please turn your head to the left"),
    ] }
}
