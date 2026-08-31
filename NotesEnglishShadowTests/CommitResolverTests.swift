import XCTest
@testable import NotesEnglishShadow

final class CommitResolverTests: XCTestCase {
    func testExtractsInsertedPhraseFromBoundedContext() {
        let old = snapshot("我今天", location: 3)
        let new = snapshot("我今天很累", location: 5)

        XCTAssertEqual(
            CommitResolver.resolve(previous: old, current: new)?.insertedText,
            "很累"
        )
    }

    func testRejectsDeletionAndReplacement() {
        let old = snapshot("我今天很累", location: 5)
        let deletion = snapshot("我今天", location: 3)
        let replacement = snapshot("我明天", location: 3)

        XCTAssertNil(CommitResolver.resolve(previous: old, current: deletion))
        XCTAssertNil(CommitResolver.resolve(previous: old, current: replacement))
    }

    func testHandlesRollingFortyEightUnitWindow() {
        let oldText = String(repeating: "中", count: 48)
        let newText = String(repeating: "中", count: 46) + "很累"
        let old = snapshot(oldText, location: 100)
        let new = snapshot(newText, location: 102)

        XCTAssertEqual(
            CommitResolver.resolve(previous: old, current: new)?.insertedText,
            "很累"
        )
    }

    func testAcceptsLongCommittedAppendAndRejectsSelection() {
        let old = snapshot("", location: 0)
        let appended = "茄子西瓜草莓苦瓜青椒树莓生病大脑优秀"
        let longAppend = snapshot(appended, location: appended.utf16.count)
        let selection = TextSnapshot(
            contextBeforeCaret: "很累",
            caretRange: NSRange(location: 2, length: 1),
            caretRect: nil,
            windowRect: nil
        )

        XCTAssertEqual(
            CommitResolver.resolve(previous: old, current: longAppend)?.insertedText,
            appended
        )
        XCTAssertNil(CommitResolver.resolve(previous: old, current: selection))
    }

    private func snapshot(_ text: String, location: Int) -> TextSnapshot {
        TextSnapshot(
            contextBeforeCaret: text,
            caretRange: NSRange(location: location, length: 0),
            caretRect: nil,
            windowRect: nil
        )
    }
}
