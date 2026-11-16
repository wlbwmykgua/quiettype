import AppKit

private final class WordSession {
    private let words = [
        "时间", "生活", "工作", "学习", "今天", "明天", "现在", "以后", "开始", "完成",
        "喜欢", "希望", "觉得", "知道", "明白", "发现", "准备", "需要", "可以", "应该",
        "可能", "已经", "还是", "一起", "一直", "正在", "非常", "特别", "当然", "其实",
        "如果", "因为", "所以", "但是", "然后", "虽然", "而且", "或者", "只有", "只要",
        "这里", "那里", "哪里", "这个", "那个", "什么", "怎么", "为什么", "多少", "时候",
        "自己", "大家", "朋友", "同学", "老师", "家人", "孩子", "父母", "别人", "我们",
        "中国", "城市", "地方", "世界", "国家", "社会", "公司", "学校", "家庭", "房间",
        "电脑", "手机", "网络", "软件", "文件", "消息", "内容", "问题", "答案", "方法",
        "事情", "机会", "结果", "原因", "计划", "目标", "想法", "感觉", "经验", "习惯",
        "早上", "中午", "晚上", "昨天", "最近", "周末", "小时", "分钟", "每天", "去年",
        "吃饭", "睡觉", "回家", "出门", "上班", "下班", "休息", "运动", "旅行", "读书",
        "写字", "说话", "听见", "看见", "打开", "关闭", "帮助", "等待", "选择", "改变",
        "简单", "困难", "重要", "正确", "清楚", "认真", "开心", "高兴", "舒服", "安静",
        "美好", "健康", "安全", "快速", "慢慢", "一样", "不同", "主要", "最后", "终于",
        "天气", "空气", "阳光", "天空", "春天", "夏天", "秋天", "冬天", "早晨", "夜晚",
        "音乐", "电影", "游戏", "照片", "故事", "文章", "新闻", "语言", "文字", "声音",
        "咖啡", "水果", "米饭", "面条", "牛奶", "公园", "商店", "医院", "车站", "机场",
        "努力", "坚持", "进步", "成长", "成功", "未来", "梦想", "勇气", "自由", "快乐",
        "认真学习", "保持专注", "按时完成", "解决问题", "提高效率", "继续努力", "放松一下", "早点休息"
    ]

    private(set) var current = "专注"
    private(set) var next = "练习"
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

    func accept(_ text: String) {
        typed.append(contentsOf: text)
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

private final class TypingView: NSView, NSTextInputClient {
    private let session: WordSession
    private var transitionTimer: Timer?
    private var compositionText = ""
    private var compositionSelection = NSRange(location: 0, length: 0)
    private lazy var nativeInputContext = NSTextInputContext(client: self)
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
    override var inputContext: NSTextInputContext? { nativeInputContext }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 && !hasMarkedText() {
            onHide?()
            return
        }

        guard transitionTimer == nil else { return }

        if !event.modifierFlags.intersection([.command, .control]).isEmpty {
            super.keyDown(with: event)
            return
        }

        interpretKeyEvents([event])
    }

    func insertText(_ string: Any, replacementRange: NSRange) {
        let insertedText = plainString(from: string)
        compositionText = ""
        compositionSelection = NSRange(location: 0, length: 0)
        commit(insertedText)
    }

    override func doCommand(by selector: Selector) {
        switch NSStringFromSelector(selector) {
        case "deleteBackward:", "deleteForward:":
            transitionTimer?.invalidate()
            transitionTimer = nil
            session.removeLast()
            refreshLayout()
        case "cancelOperation:":
            if hasMarkedText() {
                compositionText = ""
                compositionSelection = NSRange(location: 0, length: 0)
                refreshLayout()
            } else {
                onHide?()
            }
        case "insertNewline:", "insertTab:", "insertBacktab:":
            break
        default:
            break
        }
    }

    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        compositionText = plainString(from: string)
        compositionSelection = selectedRange
        refreshLayout()
        inputContext?.invalidateCharacterCoordinates()
    }

    func unmarkText() {
        guard !compositionText.isEmpty else { return }
        let textToCommit = compositionText
        compositionText = ""
        compositionSelection = NSRange(location: 0, length: 0)
        commit(textToCommit)
    }

    func selectedRange() -> NSRange {
        NSRange(
            location: session.typed.utf16.count + compositionSelection.location,
            length: compositionSelection.length
        )
    }

    func markedRange() -> NSRange {
        guard hasMarkedText() else { return NSRange(location: NSNotFound, length: 0) }
        return NSRange(location: session.typed.utf16.count, length: compositionText.utf16.count)
    }

    func hasMarkedText() -> Bool {
        !compositionText.isEmpty
    }

    func attributedSubstring(
        forProposedRange range: NSRange,
        actualRange: NSRangePointer?
    ) -> NSAttributedString? {
        nil
    }

    func validAttributesForMarkedText() -> [NSAttributedString.Key] {
        [.foregroundColor, .underlineStyle]
    }

    func firstRect(
        forCharacterRange range: NSRange,
        actualRange: NSRangePointer?
    ) -> NSRect {
        actualRange?.pointee = range
        let currentTextWidth = makeCurrentWordText().size().width
        let lineHeight = makeLineText().size().height
        let localRect = NSRect(
            x: min(22 + currentTextWidth, bounds.maxX - 4),
            y: floor((bounds.height - lineHeight) / 2),
            width: 1,
            height: lineHeight
        )
        let windowRect = convert(localRect, to: nil)
        return window?.convertToScreen(windowRect) ?? .zero
    }

    func characterIndex(for point: NSPoint) -> Int {
        session.typed.utf16.count
    }

    private func plainString(from value: Any) -> String {
        if let attributed = value as? NSAttributedString { return attributed.string }
        if let string = value as? String { return string }
        return String(describing: value)
    }

    private func commit(_ text: String) {
        guard transitionTimer == nil else { return }
        let committedText = String(text.filter { !$0.isWhitespace })
        guard !committedText.isEmpty else {
            refreshLayout()
            return
        }

        session.accept(committedText)
        refreshLayout()
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

    private func refreshLayout() {
        onPreferredWidthChange?(preferredWindowWidth)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let lineText = makeLineText()
        let centeredY = floor((bounds.height - lineText.size().height) / 2)
        lineText.draw(at: NSPoint(x: 22, y: centeredY))
    }

    private func makeLineText() -> NSMutableAttributedString {
        let lineText = makeCurrentWordText()

        if !compositionText.isEmpty {
            lineText.append(NSAttributedString(string: " ", attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .kern: 3
            ]))
            lineText.append(NSAttributedString(string: compositionText, attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.systemBlue.withAlphaComponent(0.95),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]))
        }

        lineText.append(NSAttributedString(string: " ", attributes: [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .kern: 7
        ]))
        lineText.append(NSAttributedString(string: session.next, attributes: [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.34)
        ]))
        return lineText
    }

    private func makeCurrentWordText() -> NSMutableAttributedString {
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
            .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.92)
        ])

        var utf16Offset = 0
        for index in typedCharacters.indices {
            let isCorrect = index < targetCharacters.count && typedCharacters[index] == targetCharacters[index]
            let characterLength = String(typedCharacters[index]).utf16.count
            lineText.addAttribute(
                .foregroundColor,
                value: isCorrect
                    ? NSColor.systemGreen.withAlphaComponent(0.95)
                    : NSColor.systemRed.withAlphaComponent(0.98),
                range: NSRange(location: utf16Offset, length: characterLength)
            )
            utf16Offset += characterLength
        }
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
            button.image = NSImage(systemSymbolName: "character.cursor.ibeam", accessibilityDescription: "QuietType 中文")
            button.image?.isTemplate = true
            button.toolTip = "QuietType 中文 · 点击显示或隐藏"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        menu = NSMenu()
        menu.addItem(withTitle: "显示 / 隐藏", action: #selector(toggleWindow), keyEquivalent: "")
        menu.addItem(withTitle: "重新开始", action: #selector(resetSession), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 QuietType 中文", action: #selector(quitApp), keyEquivalent: "q")
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
private struct QuietTypeChineseApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
