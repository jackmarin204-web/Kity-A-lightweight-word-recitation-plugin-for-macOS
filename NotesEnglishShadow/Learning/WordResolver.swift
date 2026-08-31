import Foundation

struct LearningHint: Equatable {
    let entry: LexiconEntry
    let anchorRange: NSRange
}

struct WordResolver {
    private let store: LexiconStore

    init(store: LexiconStore) {
        self.store = store
    }

    func resolve(in context: String) -> LearningHint? {
        let run = Array(HanText.trailingHanRun(in: context))
        guard run.count >= 2 else { return nil }

        for length in stride(from: min(12, run.count), through: 2, by: -1) {
            let candidate = String(run.suffix(length))
            guard let entry = store[candidate],
                  entry.confidence >= 0.90,
                  entry.englishHint.count <= 32,
                  entry.englishHint.unicodeScalars.allSatisfy({ $0.isASCII }) else {
                continue
            }

            let anchor = (context as NSString).range(
                of: candidate,
                options: .backwards
            )
            guard anchor.location != NSNotFound else { continue }
            return LearningHint(entry: entry, anchorRange: anchor)
        }
        return nil
    }
}
