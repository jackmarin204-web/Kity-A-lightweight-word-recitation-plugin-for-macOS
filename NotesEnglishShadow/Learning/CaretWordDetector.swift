import Foundation

struct CaretCandidate: Equatable {
    let text: String
    let identity: String
}

enum CaretWordDetector {
    static func detect(
        contextBeforeCaret: String,
        caretLocation: Int
    ) -> CaretCandidate? {
        let run = HanText.lastHanRun(in: contextBeforeCaret)
        let text = String(run.suffix(12))
        guard text.count >= 2 else { return nil }

        return CaretCandidate(
            text: text,
            identity: "\(caretLocation):\(contextBeforeCaret)"
        )
    }
}
