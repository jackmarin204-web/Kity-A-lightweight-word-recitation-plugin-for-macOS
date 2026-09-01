import Foundation

struct CaretCandidateRouter {
    private var lastIdentity: String?

    mutating func takeNewCandidate(context: String, caret: Int) -> CaretCandidate? {
        guard let candidate = CaretWordDetector.detect(
            contextBeforeCaret: context,
            caretLocation: caret
        ) else {
            lastIdentity = nil
            return nil
        }

        guard candidate.identity != lastIdentity else { return nil }
        lastIdentity = candidate.identity
        return candidate
    }

    mutating func reset() {
        lastIdentity = nil
    }
}
