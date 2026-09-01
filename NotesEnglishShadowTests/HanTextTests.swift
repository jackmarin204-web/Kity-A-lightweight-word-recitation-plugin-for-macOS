import XCTest
@testable import NotesEnglishShadow

final class HanTextTests: XCTestCase {
    func testHanOnlyAcceptsChinesePhrase() {
        XCTAssertTrue(HanText.isHanOnly("很累"))
        XCTAssertFalse(HanText.isHanOnly("很累!"))
        XCTAssertFalse(HanText.isHanOnly("abc"))
        XCTAssertFalse(HanText.isHanOnly(""))
    }

    func testTrailingHanRunReturnsOnlyLastRun() {
        XCTAssertEqual(HanText.trailingHanRun(in: "today我很累"), "我很累")
        XCTAssertEqual(HanText.trailingHanRun(in: "我很好。"), "")
    }

    func testLastHanRunIgnoresCommittedPunctuationAndNewline() {
        XCTAssertEqual(HanText.lastHanRun(in: "人工智能、\n"), "人工智能")
    }
}
