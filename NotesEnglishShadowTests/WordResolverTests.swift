import XCTest
@testable import NotesEnglishShadow

final class WordResolverTests: XCTestCase {
    func testLongestKnownPhraseWins() throws {
        let store = try LexiconStore(entries: [
            .init(
                hanzi: "很累",
                englishHint: "tired",
                partOfSpeech: "adjective",
                confidence: 0.95
            ),
            .init(
                hanzi: "我很累",
                englishHint: "I am exhausted",
                partOfSpeech: "phrase",
                confidence: 1.0
            )
        ])

        let hint = WordResolver(store: store).resolve(in: "今天我很累")
        XCTAssertEqual(hint?.entry.hanzi, "我很累")
        XCTAssertEqual(hint?.anchorRange, NSRange(location: 2, length: 3))
    }

    func testLowConfidenceAndSingleCharacterAreRejected() throws {
        let store = try LexiconStore(entries: [
            .init(
                hanzi: "行",
                englishHint: "okay",
                partOfSpeech: "adjective",
                confidence: 0.99
            ),
            .init(
                hanzi: "可能",
                englishHint: "maybe",
                partOfSpeech: "adverb",
                confidence: 0.70
            )
        ])

        XCTAssertNil(WordResolver(store: store).resolve(in: "行"))
        XCTAssertNil(WordResolver(store: store).resolve(in: "可能"))
    }

    func testRejectsOverlongHint() throws {
        let store = try LexiconStore(entries: [
            .init(
                hanzi: "很累",
                englishHint: String(repeating: "x", count: 33),
                partOfSpeech: "adjective",
                confidence: 1.0
            )
        ])

        XCTAssertNil(WordResolver(store: store).resolve(in: "很累"))
    }

    func testLongestSpecialistTermUpToTwelveCharactersWins() throws {
        let store = try LexiconStore(entries: [
            .init(
                hanzi: "人类学",
                englishHint: "anthropology",
                partOfSpeech: "noun",
                confidence: 0.95
            ),
            .init(
                hanzi: "社会文化人类学",
                englishHint: "sociocultural anthropology",
                partOfSpeech: "noun",
                confidence: 0.95
            )
        ])

        XCTAssertEqual(
            WordResolver(store: store).resolve(in: "我研究社会文化人类学")?.entry.hanzi,
            "社会文化人类学"
        )
    }
}
