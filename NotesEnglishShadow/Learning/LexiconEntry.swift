import Foundation

struct LexiconEntry: Codable, Equatable, Hashable {
    let hanzi: String
    let englishHint: String
    let partOfSpeech: String
    let confidence: Double
}
