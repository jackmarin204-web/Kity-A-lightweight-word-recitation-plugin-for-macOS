import Foundation
import Translation

@MainActor
final class NativeTranslator {
    private var task: Task<Void, Never>?

    func cancel() {
        task?.cancel()
        task = nil
    }

    func translate(_ text: String, completion: @escaping (String?) -> Void) {
        cancel()
        task = Task {
            guard #available(macOS 26.0, *) else {
                completion(nil)
                return
            }
            let session = TranslationSession(
                installedSource: Locale.Language(identifier: "zh-Hans"),
                target: Locale.Language(identifier: "en")
            )
            guard await session.isReady, !Task.isCancelled else {
                completion(nil)
                return
            }
            do {
                let response = try await session.translate(text)
                completion(Task.isCancelled ? nil : response.targetText)
            } catch {
                completion(nil)
            }
        }
    }
}
