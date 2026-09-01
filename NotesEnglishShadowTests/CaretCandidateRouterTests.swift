import XCTest
@testable import NotesEnglishShadow

final class CaretCandidateRouterTests: XCTestCase {
    func testSameSnapshotDoesNotTriggerTwice() {
        var router = CaretCandidateRouter()

        XCTAssertNotNil(router.takeNewCandidate(context: "泥巴", caret: 2))
        XCTAssertNil(router.takeNewCandidate(context: "泥巴", caret: 2))
    }

    func testDeletionThenRetypingSameWordTriggersAgain() {
        var router = CaretCandidateRouter()

        XCTAssertNotNil(router.takeNewCandidate(context: "泥巴", caret: 2))
        XCTAssertNil(router.takeNewCandidate(context: "", caret: 0))
        XCTAssertNotNil(router.takeNewCandidate(context: "泥巴", caret: 2))
    }
}
