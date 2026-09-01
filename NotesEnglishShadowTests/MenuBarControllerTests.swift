import AppKit
import XCTest
@testable import NotesEnglishShadow

final class MenuBarControllerTests: XCTestCase {
    func testMenuImageIsColoredAndReadable() {
        let configuration = MenuBarIconConfiguration.default

        XCTAssertFalse(configuration.isTemplate)
        XCTAssertEqual(configuration.size, NSSize(width: 20, height: 20))
    }
}
