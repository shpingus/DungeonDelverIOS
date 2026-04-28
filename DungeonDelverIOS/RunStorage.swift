import Foundation

struct SavedRun: Codable {
    var player: PlayerState
    var dungeon: DungeonState
    var shopGreed: Double
    var shopStock: [String]
    var elapsedOffset: TimeInterval
    var savedAt: Date
    var floorReached: Int
}

final class RunStorage {
    static let shared = RunStorage()
    private let saveKey = "dd_save"
    private let highScoreKey = "dd_high_score"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasSave: Bool {
        defaults.data(forKey: saveKey) != nil
    }

    func save(_ run: SavedRun) {
        if let data = try? JSONEncoder().encode(run) {
            defaults.set(data, forKey: saveKey)
        }
    }

    func load() -> SavedRun? {
        guard let data = defaults.data(forKey: saveKey) else { return nil }
        return try? JSONDecoder().decode(SavedRun.self, from: data)
    }

    func clearRun() {
        defaults.removeObject(forKey: saveKey)
    }

    func highScore() -> HighScore? {
        guard let data = defaults.data(forKey: highScoreKey) else { return nil }
        return try? JSONDecoder().decode(HighScore.self, from: data)
    }

    func evaluateHighScore(_ summary: RunSummary) -> (score: HighScore, isNewBest: Bool) {
        if let current = highScore(),
           current.floorReached > summary.floorReached ||
            (current.floorReached == summary.floorReached && current.elapsedSeconds <= summary.elapsedSeconds) {
            return (current, false)
        }

        let score = HighScore(floorReached: summary.floorReached, elapsedSeconds: summary.elapsedSeconds, completedAt: Date())
        if let data = try? JSONEncoder().encode(score) {
            defaults.set(data, forKey: highScoreKey)
        }
        return (score, true)
    }
}
