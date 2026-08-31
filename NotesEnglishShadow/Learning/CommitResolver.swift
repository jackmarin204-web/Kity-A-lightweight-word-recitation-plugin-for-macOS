import Foundation

struct Commit: Equatable {
    let insertedText: String
    let trailingContext: String
}

enum CommitResolver {
    static func resolve(previous: TextSnapshot, current: TextSnapshot) -> Commit? {
        guard previous.caretRange.length == 0,
              current.caretRange.length == 0 else {
            return nil
        }

        let insertedUTF16Count = current.caretRange.location - previous.caretRange.location
        guard insertedUTF16Count > 0,
              let insertedSuffix = suffix(
                of: current.contextBeforeCaret,
                utf16Count: insertedUTF16Count
              ),
              let currentPrefix = droppingSuffix(
                from: current.contextBeforeCaret,
                utf16Count: insertedUTF16Count
              ) else {
            return nil
        }

        // Both snapshots end at the old caret after removing the candidate insertion.
        // Comparing their overlap also handles a rolling 48-unit probe window.
        let overlapCount = min(
            previous.contextBeforeCaret.utf16.count,
            currentPrefix.utf16.count
        )
        guard suffix(of: previous.contextBeforeCaret, utf16Count: overlapCount)
                == suffix(of: currentPrefix, utf16Count: overlapCount) else {
            return nil
        }

        let insertedHan = HanText.trailingHanRun(in: insertedSuffix)
        guard !insertedHan.isEmpty else { return nil }

        return Commit(
            insertedText: insertedHan,
            trailingContext: current.contextBeforeCaret
        )
    }

    private static func suffix(of text: String, utf16Count: Int) -> String? {
        guard utf16Count >= 0, utf16Count <= text.utf16.count else { return nil }
        let utf16Start = text.utf16.index(text.utf16.endIndex, offsetBy: -utf16Count)
        guard let start = String.Index(utf16Start, within: text) else { return nil }
        return String(text[start...])
    }

    private static func droppingSuffix(from text: String, utf16Count: Int) -> String? {
        guard utf16Count >= 0, utf16Count <= text.utf16.count else { return nil }
        let utf16End = text.utf16.index(text.utf16.endIndex, offsetBy: -utf16Count)
        guard let end = String.Index(utf16End, within: text) else { return nil }
        return String(text[..<end])
    }
}
