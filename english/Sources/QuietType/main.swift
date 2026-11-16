import AppKit

private final class WordSession {
    private let words = [
        "about", "after", "again", "air", "along", "always", "another", "answer", "around", "away",
        "back", "because", "before", "begin", "between", "both", "bring", "build", "call", "came",
        "carry", "change", "city", "close", "come", "common", "complete", "could", "course", "day",
        "different", "does", "done", "down", "draw", "each", "early", "earth", "easy", "end",
        "enough", "every", "example", "eye", "face", "family", "far", "fast", "feel", "find",
        "first", "follow", "form", "found", "friend", "from", "game", "gave", "get", "give",
        "good", "great", "group", "grow", "had", "hand", "hard", "has", "have", "head",
        "help", "here", "high", "home", "house", "idea", "important", "into", "just", "keep",
        "kind", "know", "land", "large", "last", "later", "learn", "leave", "left", "letter",
        "life", "light", "like", "line", "little", "live", "long", "look", "made", "make",
        "many", "may", "mean", "might", "more", "most", "move", "much", "must", "name",
        "near", "need", "never", "new", "next", "night", "number", "often", "old", "once",
        "only", "open", "other", "over", "own", "page", "part", "people", "place", "plan",
        "play", "point", "put", "quick", "read", "real", "right", "room", "run", "said",
        "same", "saw", "say", "school", "second", "see", "seem", "sentence", "set", "should",
        "show", "side", "small", "so", "some", "something", "sound", "spell", "start", "state",
        "still", "story", "study", "such", "take", "tell", "than", "that", "their", "them",
        "then", "there", "these", "thing", "think", "this", "thought", "three", "through", "time",
        "together", "too", "try", "turn", "two", "under", "until", "use", "very", "want",
        "water", "way", "well", "went", "were", "what", "when", "where", "which", "while",
        "white", "who", "why", "will", "with", "word", "work", "world", "would", "write",
        "year", "you", "young", "your"
    ]

    private(set) var current = "focus"
    private(set) var next = "steady"
    private(set) var typed = ""
    private var bag: [String] = []

    init() {
        reset()
    }

    func reset() {
        bag = words.shuffled()
        current = takeWord()
        next = takeWord(excluding: current)
        typed = ""
    }

    func accept(_ character: Character) {
        typed.append(Character(character.lowercased()))
    }

    var isComplete: Bool {
        typed == current
    }

    func advance() {
        current = next
        next = takeWord(excluding: current)
        typed = ""
    }

    func removeLast() {
        guard !typed.isEmpty else { return }
        typed.removeLast()
    }

    private func takeWord(excluding excluded: String? = nil) -> String {
        if bag.isEmpty { bag = words.shuffled() }
        var word = bag.removeLast()
        if word == excluded {
            bag.insert(word, at: 0)
            word = bag.removeLast()
        }
        return word
    }
}

private final class TypingView: NSView {
    private let session: WordSession
    private var transitionTimer: Timer?
    var onHide: (() -> Void)?
    var onPreferredWidthChange: ((CGFloat) -> Void)?

    var preferredWindowWidth: CGFloat {
        ceil(makeLineText().size().width + 44)
    }

    init(session: WordSession) {
        self.session = session
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 18
        layer?.cornerCurve = .continuous
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.76).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onHide?()
            return
        }

        if event.keyCode == 51 || event.keyCode == 117 {
            transitionTimer?.invalidate()
            transitionTimer = nil
            session.removeLast()
            onPreferredWidthChange?(preferredWindowWidth)
            needsDisplay = true
            return
        }

        guard transitionTimer == nil,
              event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
              let characters = event.charactersIgnoringModifiers,
              let character = characters.first,
              character.isLetter else {
            super.keyDown(with: event)
            return
        }

        session.accept(character)
        onPreferredWidthChange?(preferredWindowWidth)
        needsDisplay = true
        if session.isComplete {
            transitionTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.session.advance()
                self.transitionTimer = nil
                self.onPreferredWidthChange?(self.preferredWindowWidth)
                self.needsDisplay = true
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let lineText = makeLineText()
        let centeredY = floor((bounds.height - lineText.size().height) / 2)
        lineText.draw(at: NSPoint(x: 22, y: centeredY))
    }

    private func makeLineText() -> NSMutableAttributedString {
        let targetCharacters = Array(session.current)
        let typedCharacters = Array(session.typed)
        let displayCount = max(targetCharacters.count, typedCharacters.count)
        var displayedWord = ""

        for index in 0..<displayCount {
            if index < typedCharacters.count {
                displayedWord.append(typedCharacters[index])
            } else {
                displayedWord.append(targetCharacters[index])
            }
        }

        let lineText = NSMutableAttributedString(string: displayedWord, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.92)
        ])

        for index in typedCharacters.indices {
            let isCorrect = index < targetCharacters.count && typedCharacters[index] == targetCharacters[index]
            lineText.addAttribute(
                .foregroundColor,
                value: isCorrect
                    ? NSColor.systemGreen.withAlphaComponent(0.95)
                    : NSColor.systemRed.withAlphaComponent(0.98),
                range: NSRange(location: index, length: 1)
            )
        }

        lineText.append(NSAttributedString(string: " ", attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .medium),
            .kern: 7
        ]))
        lineText.append(NSAttributedString(string: session.next, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.34)
        ]))
        return lineText
    }
}

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let session = WordSession()
    private var panel: FloatingPanel!
    private var typingView: TypingView!
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    func applicationDidFinishLaunching(_ notification: Notification) {
        configurePanel()
        configureStatusItem()
        showWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveWindowPosition()
    }

    private func configurePanel() {
        typingView = TypingView(session: session)
        let size = NSSize(width: typingView.preferredWindowWidth, height: 72)
        let origin = restoredOrigin(for: size)
        panel = FloatingPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow
        panel.delegate = self

        typingView.onHide = { [weak self] in self?.hideWindow() }
        typingView.onPreferredWidthChange = { [weak self] width in
            self?.resizePanel(to: width)
        }
        panel.contentView = typingView
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "QuietType")
            button.image?.isTemplate = true
            button.toolTip = "QuietType · 点击显示或隐藏"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        menu = NSMenu()
        menu.addItem(withTitle: "显示 / 隐藏", action: #selector(toggleWindow), keyEquivalent: "")
        menu.addItem(withTitle: "重新开始", action: #selector(resetSession), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 QuietType", action: #selector(quitApp), keyEquivalent: "q")
        for item in menu.items { item.target = self }
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleWindow()
        }
    }

    @objc private func toggleWindow() {
        panel.isVisible ? hideWindow() : showWindow()
    }

    @objc private func resetSession() {
        session.reset()
        resizePanel(to: typingView.preferredWindowWidth)
        typingView.needsDisplay = true
        showWindow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func showWindow() {
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.makeFirstResponder(typingView)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideWindow() {
        saveWindowPosition()
        panel.orderOut(nil)
    }

    private func resizePanel(to width: CGFloat) {
        var frame = panel.frame
        frame.size.width = width
        panel.setFrame(frame, display: true)
    }

    func windowDidMove(_ notification: Notification) {
        saveWindowPosition()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    private func restoredOrigin(for size: NSSize) -> NSPoint {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "windowX") != nil,
           defaults.object(forKey: "windowY") != nil {
            return NSPoint(x: defaults.double(forKey: "windowX"), y: defaults.double(forKey: "windowY"))
        }

        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSPoint(x: visible.maxX - size.width - 22, y: visible.maxY - size.height - 22)
    }

    private func saveWindowPosition() {
        guard panel != nil else { return }
        UserDefaults.standard.set(panel.frame.origin.x, forKey: "windowX")
        UserDefaults.standard.set(panel.frame.origin.y, forKey: "windowY")
    }
}

@main
private struct QuietTypeApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
