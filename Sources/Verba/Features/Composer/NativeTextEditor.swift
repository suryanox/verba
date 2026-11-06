import AppKit
import SwiftUI

@MainActor
enum NativeTextEditorActions {
    private static weak var activeTextView: NSTextView?

    static func register(_ textView: NSTextView) {
        activeTextView = textView
    }

    static func undo() {
        activeTextView?.undoManager?.undo()
    }

    static func redo() {
        activeTextView?.undoManager?.redo()
    }
}

struct NativeTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true

        let textView = NativeTextView()
        textView.delegate = context.coordinator
        NativeTextEditorActions.register(textView)
        textView.string = text
        textView.font = .systemFont(ofSize: 19)
        textView.textColor = .white.withAlphaComponent(0.9)
        textView.insertionPointColor = .white
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
        textView.textContainerInset = NSSize(width: 4, height: 12)
        textView.minSize = NSSize(width: 0, height: 245)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        guard textView.string != text else { return }

        textView.string = text
        textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private var parent: NativeTextEditor

        init(_ parent: NativeTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

private final class NativeTextView: NSTextView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            NativeTextEditorActions.register(self)
            self.window?.makeFirstResponder(self)
        }
    }
}
