import Foundation

/// Privacy-friendly, fully-local usage insights. Counts *how often* features are
/// used — never *what* was written. Stored only on this Mac.
@MainActor
final class UsageStats: ObservableObject {
    struct Snapshot: Codable, Equatable {
        var totalCorrections = 0
        var totalAIActions = 0
        var totalWords = 0
        var perDay: [String: Int] = [:] // "yyyy-MM-dd" -> actions that day
    }

    @Published private(set) var data: Snapshot

    private let key = "GrammaGem.usageStats"
    private let d = UserDefaults.standard

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()

    init() {
        if let raw = d.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: raw) {
            data = decoded
        } else {
            data = Snapshot()
        }
    }

    func recordCorrection(words: Int) {
        data.totalCorrections += 1
        data.totalWords += max(0, words)
        bumpToday()
        persist()
    }

    func recordAIAction(words: Int) {
        data.totalAIActions += 1
        data.totalWords += max(0, words)
        bumpToday()
        persist()
    }

    /// A playful, clearly-estimated "time saved" figure (local only).
    var estimatedMinutesSaved: Int {
        (data.totalCorrections * 8 + data.totalAIActions * 45) / 60
    }

    /// Counts for the last 7 calendar days, oldest → newest, for a small chart.
    func last7Days() -> [(label: String, count: Int)] {
        let cal = Calendar.current
        let today = Date()
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let key = Self.fmt.string(from: day)
            let short = day.formatted(.dateTime.weekday(.narrow))
            return (label: short, count: data.perDay[key] ?? 0)
        }
    }

    func reset() {
        data = Snapshot()
        persist()
    }

    private func bumpToday() {
        let k = Self.fmt.string(from: Date())
        data.perDay[k, default: 0] += 1
        // Keep only ~60 days of history.
        if data.perDay.count > 70 {
            let keep = Set((0..<60).compactMap { off -> String? in
                guard let day = Calendar.current.date(byAdding: .day, value: -off, to: Date()) else { return nil }
                return Self.fmt.string(from: day)
            })
            data.perDay = data.perDay.filter { keep.contains($0.key) }
        }
    }

    private func persist() {
        if let raw = try? JSONEncoder().encode(data) {
            d.set(raw, forKey: key)
        }
    }
}
