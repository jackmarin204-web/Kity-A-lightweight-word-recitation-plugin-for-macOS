import XCTest
@testable import NotesEnglishShadow

final class CaretWordDetectorTests: XCTestCase {
    func testDetectsTrailingChineseCandidate() {
        let candidate = CaretWordDetector.detect(
            contextBeforeCaret: "人工智能",
            caretLocation: 4
        )

        XCTAssertEqual(candidate?.text, "人工智能")
    }

    func testBreaksIdentityWhenContextHasNoChineseCandidate() {
        XCTAssertNil(
            CaretWordDetector.detect(
                contextBeforeCaret: "today ",
                caretLocation: 6
            )
        )
    }

    func testIdentityChangesWhenCaretMoves() {
        let first = CaretWordDetector.detect(contextBeforeCaret: "泥巴", caretLocation: 2)
        let second = CaretWordDetector.detect(contextBeforeCaret: "x泥巴", caretLocation: 3)

        XCTAssertNotEqual(first?.identity, second?.identity)
    }
}
