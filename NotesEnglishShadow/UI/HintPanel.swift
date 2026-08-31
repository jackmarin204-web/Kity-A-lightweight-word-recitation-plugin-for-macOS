import AppKit

final class HintPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 70),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = true
        becomesKeyOnlyIfNeeded = false
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class HintContentView: NSVisualEffectView {
    private let hanziLabel = NSTextField(labelWithString: "")
    private let hintLabel = NSTextField(labelWithString: "")

    init(entry: LexiconEntry) {
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true

        hanziLabel.stringValue = entry.hanzi
        hanziLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        hanziLabel.textColor = .secondaryLabelColor
        hanziLabel.translatesAutoresizingMaskIntoConstraints = false

        hintLabel.stringValue = entry.englishHint
        hintLabel.font = .systemFont(ofSize: 12, weight: .medium)
        hintLabel.textColor = .labelColor
        hintLabel.lineBreakMode = .byTruncatingTail
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hanziLabel)
        addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hanziLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            hanziLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            hintLabel.leadingAnchor.constraint(equalTo: hanziLabel.trailingAnchor, constant: 5),
            hintLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            hintLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),
            hintLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
            hintLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }
}
