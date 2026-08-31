import XCTest
@testable import NotesEnglishShadow

final class LexiconStoreTests: XCTestCase {
    func testLoadsJSON() throws {
        let data = #"[{"hanzi":"很累","englishHint":"exhausted","partOfSpeech":"adjective","confidence":1.0}]"#
            .data(using: .utf8)!
        let store = try LexiconStore(data: data)

        XCTAssertEqual(store["很累"]?.englishHint, "exhausted")
    }

    func testRejectsDuplicateKeys() {
        let entry = LexiconEntry(
            hanzi: "很累",
            englishHint: "exhausted",
            partOfSpeech: "adjective",
            confidence: 1.0
        )

        XCTAssertThrowsError(try LexiconStore(entries: [entry, entry])) { error in
            XCTAssertEqual(error as? LexiconStore.Error, .duplicateKey("很累"))
        }
    }

    func testBundledLexiconHasHighFrequencyScaleAndUniqueKeys() throws {
        let entries = try loadBundledEntries()

        XCTAssertEqual(entries.count, 61_503)
        XCTAssertEqual(Set(entries.map(\.hanzi)).count, entries.count)
        XCTAssertTrue(entries.allSatisfy { (2...12).contains($0.hanzi.count) })
        XCTAssertTrue(entries.allSatisfy {
            $0.englishHint.unicodeScalars.allSatisfy(\.isASCII)
                && $0.englishHint.count <= 32
        })
    }

    func testBundledLexiconIncludesRequiredCommonWords() throws {
        let entries = try loadBundledEntries()
        let hints = Dictionary(
            uniqueKeysWithValues: entries.map { ($0.hanzi, $0.englishHint) }
        )

        XCTAssertEqual(hints["苹果"], "apple")
        XCTAssertEqual(hints["优秀"], "outstanding")
        XCTAssertEqual(hints["理想"], "ideal")
        XCTAssertEqual(hints["计划"], "plan")
        XCTAssertEqual(hints["社会学"], "sociology")
        XCTAssertEqual(hints["量子力学"], "quantum mechanics")
        XCTAssertEqual(hints["机器学习"], "machine learning")
        XCTAssertEqual(hints["临床医学"], "clinical medicine")
    }

    func testKityBrandingKeepsExistingBundleIdentifier() throws {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let infoURL = sourceRoot.appendingPathComponent("NotesEnglishShadow/Info.plist")
        let projectURL = sourceRoot.appendingPathComponent(
            "NotesEnglishShadow.xcodeproj/project.pbxproj"
        )
        let info = try XCTUnwrap(
            NSDictionary(contentsOf: infoURL) as? [String: Any]
        )
        let project = try String(contentsOf: projectURL, encoding: .utf8)

        XCTAssertEqual(info["CFBundleDisplayName"] as? String, "Kity")
        XCTAssertEqual(info["CFBundleName"] as? String, "Kity")
        XCTAssertEqual(info["CFBundleIconFile"] as? String, "Kity")
        XCTAssertEqual(
            project.components(separatedBy: "PRODUCT_BUNDLE_IDENTIFIER = org.xiaozhu.NotesEnglishShadow;").count,
            3
        )
    }

    func testMenuBarUsesDedicatedHighResolutionCatAsset() throws {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let controllerURL = sourceRoot.appendingPathComponent(
            "NotesEnglishShadow/UI/MenuBarController.swift"
        )
        let controller = try String(contentsOf: controllerURL, encoding: .utf8)

        XCTAssertTrue(controller.contains("KityMenuBarCat"))
        XCTAssertTrue(controller.contains("NSSize(width: 20, height: 20)"))
        XCTAssertFalse(controller.contains("makeStatusIcon()"))
        XCTAssertTrue(controller.contains("isTemplate = true"))
    }

    private func loadBundledEntries() throws -> [LexiconEntry] {
        let sourceFile = URL(fileURLWithPath: #filePath)
        let resourceURL = sourceFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NotesEnglishShadow/Resources/Lexicon.json")
        return try JSONDecoder().decode(
            [LexiconEntry].self,
            from: Data(contentsOf: resourceURL)
        )
    }
}
