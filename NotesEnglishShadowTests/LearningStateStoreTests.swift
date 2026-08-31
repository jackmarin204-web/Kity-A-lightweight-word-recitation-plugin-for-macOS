import XCTest
@testable import NotesEnglishShadow

final class LearningStateStoreTests: XCTestCase {
    func testZeroIntervalNeverSuppresses() {
        let suite = "LearningStateStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = LearningStateStore(defaults: defaults, interval: 0)
        let now = Date(timeIntervalSince1970: 1_000)
        store.recordShown("很累", now: now)
        XCTAssertTrue(store.shouldShow("很累", now: now))
    }
}
