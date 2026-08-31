import Foundation

struct LexiconStore {
    enum Error: Swift.Error, Equatable {
        case duplicateKey(String)
        case resourceMissing
    }

    private let entriesByHanzi: [String: LexiconEntry]

    init(entries: [LexiconEntry]) throws {
        var indexed: [String: LexiconEntry] = [:]
        for entry in entries {
            guard indexed[entry.hanzi] == nil else {
                throw Error.duplicateKey(entry.hanzi)
            }
            indexed[entry.hanzi] = entry
        }
        entriesByHanzi = indexed
    }

    init(data: Data) throws {
        try self.init(entries: JSONDecoder().decode([LexiconEntry].self, from: data))
    }

    init(bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "Lexicon", withExtension: "json") else {
            throw Error.resourceMissing
        }
        try self.init(data: Data(contentsOf: url))
    }

    subscript(hanzi: String) -> LexiconEntry? {
        entriesByHanzi[hanzi]
    }
}
