import Foundation

struct PositionReading: Identifiable {
    let id: UUID
    let timestamp: Date
    let position: PrayerPosition

    init(id: UUID = UUID(), timestamp: Date = Date(), position: PrayerPosition) {
        self.id = id
        self.timestamp = timestamp
        self.position = position
    }
}
