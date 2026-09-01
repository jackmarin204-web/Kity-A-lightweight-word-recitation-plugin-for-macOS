import AppKit
import XCTest
@testable import NotesEnglishShadow

final class MenuBarControllerTests: XCTestCase {
    func testMenuImageIsColoredAndReadable() {
        let configuration = MenuBarIconConfiguration.default

        XCTAssertFalse(configuration.isTemplate)
        XCTAssertEqual(configuration.size, NSSize(width: 22, height: 22))
    }
}
