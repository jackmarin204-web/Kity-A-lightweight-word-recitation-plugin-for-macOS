import AppKit

final class HintPanelController {
    var displayDuration: TimeInterval = 1.2

    private let panel = HintPanel()
    private var fadeWorkItem: DispatchWorkItem?

    func show(hint: LearningHint, snapshot: TextSnapshot) {
        fadeWorkItem?.cancel()

        let contentView = HintContentView(entry: hint.entry)
        panel.contentView = contentView
        let fitting = contentView.fittingSize
        let size = NSSize(
            width: min(144, max(76, fitting.width)),
            height: 30
        )
        panel.setContentSize(size)
        panel.setFrameOrigin(origin(for: size, snapshot: snapshot))
        panel.alphaValue = 1
        panel.orderFront(nil)

        let workItem = DispatchWorkItem { [weak self] in
            self?.fadeOut()
        }
        fadeWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + max(0, displayDuration),
            execute: workItem
        )
    }

    func hide() {
        fadeWorkItem?.cancel()
        fadeWorkItem = nil
        panel.alphaValue = 0
        panel.orderOut(nil)
    }

    private func fadeOut() {
        fadeWorkItem = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
        }
    }

    private func origin(for size: NSSize, snapshot: TextSnapshot) -> NSPoint {
        let caret = snapshot.caretRect.map(convertAXRectToAppKit)
        let notesWindow = snapshot.windowRect.map(convertAXRectToAppKit)
        let screen = screen(containing: caret?.center ?? notesWindow?.center)
        let visible = (screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero)
            .insetBy(dx: 8, dy: 8)

        var result: NSPoint
        if let caret, let notesWindow {
            let left = NSPoint(
                x: caret.minX - size.width - 48,
                y: caret.midY - size.height / 2
            )
            if left.x >= visible.minX {
                result = left
            } else {
                let below = NSPoint(
                    x: caret.minX,
                    y: caret.minY - size.height - 6
                )
                if below.y >= visible.minY,
                   below.x + size.width <= visible.maxX {
                    result = below
                } else {
                    result = NSPoint(
                        x: notesWindow.minX + 12,
                        y: notesWindow.minY + 12
                    )
                }
            }
        } else if let caret {
            result = NSPoint(x: caret.minX, y: caret.minY - size.height - 8)
        } else if let notesWindow {
            result = NSPoint(
                x: notesWindow.minX + 12,
                y: notesWindow.minY + 12
            )
        } else {
            result = NSPoint(
                x: visible.midX - size.width / 2,
                y: visible.midY - size.height / 2
            )
        }

        return NSPoint(
            x: min(max(result.x, visible.minX), visible.maxX - size.width),
            y: min(max(result.y, visible.minY), visible.maxY - size.height)
        )
    }

    private func convertAXRectToAppKit(_ rect: CGRect) -> CGRect {
        let primaryTop = NSScreen.screens.first?.frame.maxY ?? 0
        return CGRect(
            x: rect.minX,
            y: primaryTop - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    private func screen(containing point: CGPoint?) -> NSScreen? {
        guard let point else { return NSScreen.main }
        return NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
