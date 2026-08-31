import AppKit
import ApplicationServices

private let notesAXCallback: AXObserverCallback = {
    _, element, notification, context in
    guard let context else { return }
    let session = Unmanaged<NotesSession>.fromOpaque(context).takeUnretainedValue()
    session.receive(element: element, notification: notification)
}

final class NotesSession {
    enum Event {
        case valueChanged(AXUIElement)
        case focusedElementChanged(AXUIElement?)
        case geometryChanged
    }

    var onEvent: ((Event) -> Void)?
    var onDeactivated: (() -> Void)?

    private struct Registration {
        let element: AXUIElement
        let notification: CFString
    }

    private let workspace = NSWorkspace.shared
    private var workspaceTokens: [NSObjectProtocol] = []
    private var observer: AXObserver?
    private var runLoopSource: CFRunLoopSource?
    private var appElement: AXUIElement?
    private var focusedElement: AXUIElement?
    private var registrations: [Registration] = []
    private var fallbackTimer: DispatchSourceTimer?
    private var runningPID: pid_t?
    private var isStarted = false

    var isNotesFrontmost: Bool {
        workspace.frontmostApplication?.bundleIdentifier == "com.apple.Notes"
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        UserDefaults.standard.set("notes session started", forKey: "diagnosticStage")

        let center = workspace.notificationCenter
        workspaceTokens = [
            center.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.evaluateFrontmostApplication()
            },
            center.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.evaluateFrontmostApplication()
            }
        ]
        evaluateFrontmostApplication()
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        let center = workspace.notificationCenter
        workspaceTokens.forEach { center.removeObserver($0) }
        workspaceTokens.removeAll()
        tearDownObserver(notify: true)
    }

    fileprivate func receive(element: AXUIElement, notification: CFString) {
        let name = notification as String
        switch name {
        case kAXApplicationDeactivatedNotification as String:
            tearDownObserver(notify: true)
        case kAXFocusedUIElementChangedNotification as String:
            let element = refreshFocusedElement()
            onEvent?(.focusedElementChanged(element))
        case kAXValueChangedNotification as String:
            onEvent?(.valueChanged(element))
        case kAXWindowMovedNotification as String,
             kAXWindowResizedNotification as String:
            onEvent?(.geometryChanged)
        default:
            break
        }
    }

    private func evaluateFrontmostApplication() {
        guard isNotesFrontmost,
              let application = workspace.frontmostApplication else {
            UserDefaults.standard.set("notes not frontmost", forKey: "diagnosticStage")
            tearDownObserver(notify: true)
            return
        }

        if runningPID != application.processIdentifier || observer == nil {
            activate(processIdentifier: application.processIdentifier)
        }
    }

    private func activate(processIdentifier: pid_t) {
        tearDownObserver(notify: false)
        UserDefaults.standard.set("notes activation attempted", forKey: "diagnosticStage")

        var newObserver: AXObserver?
        guard AXObserverCreate(
            processIdentifier,
            notesAXCallback,
            &newObserver
        ) == .success,
        let newObserver else {
            UserDefaults.standard.set("notes observer unavailable", forKey: "diagnosticStage")
            onDeactivated?()
            return
        }

        let applicationElement = AXUIElementCreateApplication(processIdentifier)
        observer = newObserver
        appElement = applicationElement
        runningPID = processIdentifier

        let source = AXObserverGetRunLoopSource(newObserver)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)

        _ = register(
            element: applicationElement,
            notification: kAXFocusedUIElementChangedNotification as CFString
        )
        _ = register(
            element: applicationElement,
            notification: kAXApplicationDeactivatedNotification as CFString
        )
        _ = register(
            element: applicationElement,
            notification: kAXWindowMovedNotification as CFString
        )
        _ = register(
            element: applicationElement,
            notification: kAXWindowResizedNotification as CFString
        )
        let element = refreshFocusedElement()
        onEvent?(.focusedElementChanged(element))
    }

    @discardableResult
    private func refreshFocusedElement() -> AXUIElement? {
        removeFocusedValueRegistration()
        guard let applicationElement = appElement,
              let element: AXUIElement = AXRead.value(
                applicationElement,
                kAXFocusedUIElementAttribute as CFString,
                as: AXUIElement.self
              ) else {
            focusedElement = nil
            stopFallback()
            return nil
        }

        focusedElement = element
        _ = register(
            element: element,
            notification: kAXValueChangedNotification as CFString
        )
        // Apple Notes can accept this notification registration without
        // delivering a callback for ordinary typing. Keep a bounded 350 ms
        // probe active while Notes is focused so that committed text is still
        // observed without monitoring raw keyboard input.
        startFallback()
        return element
    }

    @discardableResult
    private func register(
        element: AXUIElement,
        notification: CFString
    ) -> AXError {
        guard let observer else { return .invalidUIElementObserver }
        let result = AXObserverAddNotification(
            observer,
            element,
            notification,
            Unmanaged.passUnretained(self).toOpaque()
        )
        if result == .success {
            registrations.append(
                Registration(element: element, notification: notification)
            )
        }
        return result
    }

    private func removeFocusedValueRegistration() {
        guard let observer, let focusedElement else { return }
        registrations.removeAll { registration in
            let isMatch = CFEqual(registration.element, focusedElement)
                && registration.notification as String
                    == kAXValueChangedNotification as String
            if isMatch {
                AXObserverRemoveNotification(
                    observer,
                    registration.element,
                    registration.notification
                )
            }
            return isMatch
        }
    }

    private func startFallback() {
        guard fallbackTimer == nil else { return }
        NSLog("NotesEnglishShadow session: fallback started")
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(
            deadline: .now() + .milliseconds(80),
            repeating: .milliseconds(80)
        )
        timer.setEventHandler { [weak self] in
            guard let self,
                  self.isNotesFrontmost,
                  let element = self.focusedElement else {
                return
            }
            self.onEvent?(.valueChanged(element))
        }
        fallbackTimer = timer
        timer.resume()
    }

    private func stopFallback() {
        fallbackTimer?.setEventHandler {}
        fallbackTimer?.cancel()
        fallbackTimer = nil
    }

    private func tearDownObserver(notify: Bool) {
        stopFallback()
        if let observer {
            for registration in registrations {
                AXObserverRemoveNotification(
                    observer,
                    registration.element,
                    registration.notification
                )
            }
        }
        registrations.removeAll()

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        runLoopSource = nil
        observer = nil
        appElement = nil
        focusedElement = nil
        runningPID = nil

        if notify {
            onDeactivated?()
        }
    }
}
