import AppKit
import ApplicationServices

extension Notification.Name {
    static let shadowSettingsDidChange = Notification.Name(
        "NotesEnglishShadow.settingsDidChange"
    )
}

@MainActor
final class AppEnvironment {
    var isPaused = false {
        didSet {
            menuBarController.updatePausedState()
            reconcileRunningState()
        }
    }

    private let defaults: UserDefaults
    private let hintPanelController = HintPanelController()
    private let nativeTranslator = NativeTranslator()
    private let wordResolver: WordResolver
    private var translationRequestID = 0
    private var candidateRouter = CaretCandidateRouter()
    private var probeWorkItem: DispatchWorkItem?
    private var settingsObserver: NSObjectProtocol?
    private var trusted = false
    private var started = false

    private lazy var menuBarController = MenuBarController(
        isPaused: { [weak self] in self?.isPaused ?? true },
        togglePause: { [weak self] in
            guard let self else { return }
            self.isPaused.toggle()
        }
    )

    private lazy var notesSession: NotesSession = {
        let session = NotesSession()
        session.onEvent = { [weak self] event in
            self?.handle(event)
        }
        session.onDeactivated = { [weak self] in
            self?.resetTransientState()
        }
        return session
    }()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let localEntries = [
            ("尼加拉瓜", "Nicaragua"),
            ("人工智能", "artificial intelligence"),
            ("人类学", "anthropology"),
            ("红薯", "sweet potato"),
            ("泥巴", "mud"),
            ("信仰", "faith"),
            ("备忘录", "Notes"),
            ("炒蛋", "scrambled eggs"),
            ("西瓜", "watermelon"),
            ("黄瓜", "cucumber"),
            ("茄子", "eggplant"),
            ("南瓜", "pumpkin"),
            ("鸡腿", "chicken leg"),
            ("力量", "strength"),
            ("哲学", "philosophy"),
            ("手机", "phone"),
            ("太阳", "sun"),
            ("胡萝卜", "carrot"),
            ("番茄", "tomato"),
            ("土豆", "potato"),
            ("火车", "train")
        ].map {
            LexiconEntry(
                hanzi: $0.0,
                englishHint: $0.1,
                partOfSpeech: "word",
                confidence: 1.0
            )
        }
        wordResolver = WordResolver(store: try! LexiconStore(entries: localEntries))
        defaults.register(defaults: [
            "enabled": true,
            "fadeDuration": 3.0
        ])
    }

    func start() {
        guard !started else { return }
        started = true
        _ = menuBarController

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .shadowSettingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadSettings()
        }

        reloadSettings()
        trusted = AccessibilityPermission.isTrusted(prompt: true)
        defaults.set("started trusted=\(trusted)", forKey: "diagnosticStage")
        menuBarController.setAvailable(trusted && isEnabled)
        reconcileRunningState()
    }

    func stop() {
        guard started else { return }
        started = false
        notesSession.stop()
        probeWorkItem?.cancel()
        probeWorkItem = nil
        hintPanelController.hide()
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }
        settingsObserver = nil
    }

    private var isEnabled: Bool {
        defaults.bool(forKey: "enabled")
    }

    private func reloadSettings() {
        hintPanelController.displayDuration = defaults.double(forKey: "fadeDuration")
        menuBarController.setAvailable(trusted && isEnabled)
        reconcileRunningState()
    }

    private func reconcileRunningState() {
        guard started, trusted, isEnabled, !isPaused else {
            notesSession.stop()
            resetTransientState()
            return
        }
        notesSession.start()
    }

    private func handle(_ event: NotesSession.Event) {
        switch event {
        case .valueChanged(let element):
            scheduleProbe(element: element)
        case .focusedElementChanged(let element):
            resetTransientState()
            if let element,
               notesSession.isNotesFrontmost {
                scheduleProbe(element: element)
            }
        case .geometryChanged:
            resetTransientState()
        }
    }

    private func scheduleProbe(element: AXUIElement) {
        probeWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.probe(element: element)
        }
        probeWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .milliseconds(40),
            execute: workItem
        )
    }

    private func probe(element: AXUIElement) {
        probeWorkItem = nil
        guard notesSession.isNotesFrontmost,
              trusted,
              isEnabled,
              !isPaused else {
            NSLog("NotesEnglishShadow probe: gated")
            resetTransientState()
            return
        }

        guard let current = TextProbe.snapshot(from: element) else {
            NSLog("NotesEnglishShadow probe: snapshot unavailable")
            return
        }

        guard let candidate = candidateRouter.takeNewCandidate(
            context: current.contextBeforeCaret,
            caret: current.caretRange.location
        ) else {
            return
        }
        translationRequestID += 1
        let requestID = translationRequestID
        if let hint = wordResolver.resolve(in: current.contextBeforeCaret) {
            nativeTranslator.cancel()
            hintPanelController.show(hint: hint, snapshot: current)
            return
        }
        nativeTranslator.translate(candidate.text) { [weak self] englishHint in
            guard let self,
                  requestID == self.translationRequestID,
                  let englishHint,
                  !englishHint.isEmpty else { return }
            let anchor = (current.contextBeforeCaret as NSString).range(
                of: candidate.text,
                options: .backwards
            )
            guard anchor.location != NSNotFound else { return }
            let entry = LexiconEntry(
                hanzi: candidate.text,
                englishHint: englishHint,
                partOfSpeech: "translation",
                confidence: 1.0
            )
            self.hintPanelController.show(
                hint: LearningHint(entry: entry, anchorRange: anchor),
                snapshot: current
            )
        }
    }

    private func resetTransientState() {
        probeWorkItem?.cancel()
        probeWorkItem = nil
        candidateRouter.reset()
        translationRequestID += 1
        nativeTranslator.cancel()
        hintPanelController.hide()
    }
}
