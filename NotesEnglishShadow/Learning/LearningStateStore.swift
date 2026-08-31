import Foundation

final class LearningStateStore {
    private let defaults: UserDefaults
    private let interval: TimeInterval
    private let storageKey = "lastShownByLexiconKey"
    private let retention: TimeInterval = 30 * 24 * 60 * 60

    init(defaults: UserDefaults = .standard, interval: TimeInterval = 900) {
        self.defaults = defaults
        self.interval = interval
    }

    func shouldShow(_ lexiconKey: String, now: Date = Date()) -> Bool {
        guard interval > 0 else { return true }
        guard let lastShown = storedDates()[lexiconKey] else { return true }
        return now.timeIntervalSince(lastShown) >= interval
    }

    func recordShown(_ lexiconKey: String, now: Date = Date()) {
        var dates = storedDates().filter {
            now.timeIntervalSince($0.value) <= retention
        }
        dates[lexiconKey] = now
        defaults.set(dates, forKey: storageKey)
    }

    private func storedDates() -> [String: Date] {
        let raw = defaults.dictionary(forKey: storageKey) ?? [:]
        return raw.reduce(into: [String: Date]()) { result, pair in
            if let date = pair.value as? Date {
                result[pair.key] = date
            }
        }
    }
}
