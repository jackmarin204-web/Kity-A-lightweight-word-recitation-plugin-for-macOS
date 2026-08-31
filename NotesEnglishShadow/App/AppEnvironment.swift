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
    private var translationRequestID = 0
    private var previousSnapshot: TextSnapshot?
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
                previousSnapshot = TextProbe.snapshot(from: element)
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
            deadline: .now() + .milliseconds(45),
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

        let previous = previousSnapshot
        previousSnapshot = current
        guard let previous else {
            NSLog("NotesEnglishShadow probe: baseline captured")
            return
        }
        guard let commit = CommitResolver.resolve(previous: previous, current: current) else {
            NSLog("NotesEnglishShadow probe: no committed insertion")
            return
        }
        translationRequestID += 1
        let requestID = translationRequestID
        let candidate = String(HanText.trailingHanRun(in: commit.trailingContext).suffix(12))
        guard candidate.count >= 2 else { return }
        nativeTranslator.translate(candidate) { [weak self] englishHint in
            guard let self,
                  requestID == self.translationRequestID,
                  let englishHint,
                  !englishHint.isEmpty else { return }
            let anchor = (commit.trailingContext as NSString).range(
                of: candidate,
                options: .backwards
            )
            guard anchor.location != NSNotFound else { return }
            let entry = LexiconEntry(
                hanzi: candidate,
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
        previousSnapshot = nil
        translationRequestID += 1
        nativeTranslator.cancel()
        hintPanelController.hide()
    }
}
