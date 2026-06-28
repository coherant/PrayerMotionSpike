import Foundation

// MARK: - WeatherCacheKey
//
// The cost lever, expressed as a key. Coordinates are coarsened to a ~10km grid and
// time is bucketed into the cache window, so all reads within one cell+window collapse
// to a single upstream call. Designing the key as (gridCell, timeWindow) now is what
// lets a server proxy decouple calls from headcount later — no rewrite. SPEC §2.

enum WeatherCacheKey {
    static func make(latitude: Double,
                     longitude: Double,
                     date: Date,
                     window: TimeInterval,
                     gridResolution: Double) -> String {
        let lat = (latitude / gridResolution).rounded() * gridResolution
        let lon = (longitude / gridResolution).rounded() * gridResolution
        let bucket = Int(date.timeIntervalSince1970 / window)
        return String(format: "%.3f,%.3f|%d", lat, lon, bucket)
    }
}

// MARK: - WeatherCache
//
// Persisted, bounded cache of WeatherState by key. An actor for safe concurrent
// access. `fileURL == nil` → memory-only (tests). Persistence means dev relaunches
// and app restarts reuse a result within its 6h window instead of re-fetching.

actor WeatherCache {
    private var entries: [String: WeatherState]
    private let fileURL: URL?
    private let maxEntries: Int

    init(fileURL: URL? = WeatherCache.defaultFileURL, maxEntries: Int = 16) {
        self.fileURL = fileURL
        self.maxEntries = maxEntries
        if let fileURL,
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: WeatherState].self, from: data) {
            entries = decoded
        } else {
            entries = [:]
        }
    }

    func value(for key: String) -> WeatherState? { entries[key] }

    func store(_ state: WeatherState, for key: String) {
        entries[key] = state
        if entries.count > maxEntries {
            // Drop the oldest by `asOf` — older windows are never re-queried.
            let overflow = entries.count - maxEntries
            for (k, _) in entries.sorted(by: { $0.value.asOf < $1.value.asOf }).prefix(overflow) {
                entries[k] = nil
            }
        }
        persist()
    }

    private func persist() {
        guard let fileURL, let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static var defaultFileURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("weather-cache.json")
    }
}
