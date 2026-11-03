import ApplicationServices
import CoreGraphics

@MainActor
final class FocusedTextTarget {
    let element: AXUIElement
    let role: String
    let value: String?
    let selectedText: String?
    let frame: CGRect?

    init(
        element: AXUIElement,
        role: String,
        value: String?,
        selectedText: String?,
        frame: CGRect?
    ) {
        self.element = element
        self.role = role
        self.value = value
        self.selectedText = selectedText
        self.frame = frame
    }
}
