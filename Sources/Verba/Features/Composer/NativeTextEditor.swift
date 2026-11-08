import AppKit
import SwiftUI

@MainActor
enum NativeTextEditorActions {
    private weak static var activeTextView: NSTextView?

    static func register(_ textView: NSTextView) {
        activeTextView = textView
    }

    static func undo() {
        guard let textView = activeTextView else { return }
        textView.window?.makeFirstResponder(textView)
        textView.undoManager?.undo()
    }

    static func redo() {
        guard let textView = activeTextView else { return }
        textView.window?.makeFirstResponder(textView)
        textView.undoManager?.redo()
    }
}

/// Everything the editor needs to draw itself. Compared by value (not object identity) so the editor
/// only restyles when something really changed. Restyling on every keystroke would disturb undo.
struct EditorStyle: Equatable {
    var font: NSFont
    var textColor: NSColor
    var caretColor: NSColor
    var selectionColor: NSColor
    var lineHeightMultiple: CGFloat
    var columnWidth: CGFloat

    static func == (lhs: EditorStyle, rhs: EditorStyle) -> Bool {
        lhs.signature == rhs.signature
    }

    private var signature: String {
        [
            font.fontName,
            String(format: "%.1f", font.pointSize),
            Self.rgba(textColor),
            Self.rgba(caretColor),
            Self.rgba(selectionColor),
            String(format: "%.2f", lineHeightMultiple),
            String(format: "%.0f", columnWidth),
        ].joined(separator: "|")
    }

    private static func rgba(_ color: NSColor) -> String {
        guard let rgb = color.usingColorSpace(.sRGB) else { return color.description }
        return String(
            format: "%.3f,%.3f,%.3f,%.3f",
            rgb.redComponent,
            rgb.greenComponent,
            rgb.blueComponent,
            rgb.alphaComponent
        )
    }
}

struct NativeTextEditor: NSViewRepresentable {
    @Binding var text: String
    var style: EditorStyle
    /// While true, all programmatic text changes are merged into one undo step.
    var isDictating = false

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = EditorScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
        scrollView.scrollerInsets = NSEdgeInsets(top: 52, left: 0, bottom: 90, right: 0)

        let textView = NativeTextView()
        configure(textView, delegate: context.coordinator)
        textView.string = text
        textView.apply(style)
        textView.columnWidth = style.columnWidth
        context.coordinator.lastStyle = style

        NativeTextEditorActions.register(textView)
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NativeTextView else { return }
        let coordinator = context.coordinator
        coordinator.parent = self

        updateDictationGrouping(textView, coordinator: coordinator)

        if textView.string != text {
            // Replace through the text system so the change lands on the undo stack.
            coordinator.isApplyingExternalChange = true
            textView.replaceAll(with: text)
            coordinator.isApplyingExternalChange = false

            textView.apply(style)
            let end = NSRange(location: textView.string.utf16.count, length: 0)
            textView.setSelectedRange(end)
            textView.scrollRangeToVisible(end)
        } else if coordinator.lastStyle != style {
            textView.apply(style)
        }

        coordinator.lastStyle = style
        textView.columnWidth = style.columnWidth
    }

    private func updateDictationGrouping(_ textView: NSTextView, coordinator: Coordinator) {
        guard coordinator.wasDictating != isDictating else { return }
        coordinator.wasDictating = isDictating
        guard let undoManager = textView.undoManager else { return }
        if isDictating {
            undoManager.groupsByEvent = false
            undoManager.beginUndoGrouping()
        } else {
            undoManager.endUndoGrouping()
            undoManager.groupsByEvent = true
        }
    }

    private func configure(_ textView: NativeTextView, delegate: NSTextViewDelegate) {
        textView.delegate = delegate
        textView.isRichText = false
        textView.importsGraphics = false
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticLinkDetectionEnabled = false
        textView.textContainerInset = NSSize(width: 28, height: 80)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NativeTextEditor
        var lastStyle: EditorStyle?
        var wasDictating = false
        var isApplyingExternalChange = false

        init(_ parent: NativeTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            // Skip echoes of changes that came from the model, to avoid writing state during a view update.
            guard !isApplyingExternalChange, let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

private extension NSTextView {
    func replaceAll(with newText: String) {
        let fullRange = NSRange(location: 0, length: (string as NSString).length)
        if shouldChangeText(in: fullRange, replacementString: newText) {
            textStorage?.replaceCharacters(in: fullRange, with: newText)
            didChangeText()
        } else {
            string = newText
        }
    }

    func apply(_ style: EditorStyle) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = style.lineHeightMultiple

        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: style.textColor,
            .paragraphStyle: paragraph,
        ]

        insertionPointColor = style.caretColor
        defaultParagraphStyle = paragraph
        typingAttributes = attributes
        selectedTextAttributes = [.backgroundColor: style.selectionColor]

        if let storage = textStorage, storage.length > 0 {
            storage.addAttributes(attributes, range: NSRange(location: 0, length: storage.length))
        }
    }
}

/// Keeps the text view at least as tall as the visible area so clicking empty space focuses the editor.
private final class EditorScrollView: NSScrollView {
    override func layout() {
        super.layout()
        guard let textView = documentView as? NSTextView else { return }
        let height = contentSize.height
        if abs(textView.minSize.height - height) > 0.5 {
            textView.minSize = NSSize(width: 0, height: height)
        }
    }
}

private final class NativeTextView: NSTextView {
    var columnWidth: CGFloat = 700 {
        didSet { updateHorizontalInset() }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateHorizontalInset()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            NativeTextEditorActions.register(self)
            window?.makeFirstResponder(self)
        }
    }

    /// Centers the text in a fixed-width reading column.
    private func updateHorizontalInset() {
        let horizontal = max(28, (bounds.width - columnWidth) / 2)
        guard abs(textContainerInset.width - horizontal) > 0.5 else { return }
        textContainerInset = NSSize(width: horizontal, height: textContainerInset.height)
    }
}
