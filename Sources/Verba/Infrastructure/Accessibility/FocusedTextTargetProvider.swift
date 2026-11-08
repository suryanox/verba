import AppKit
import ApplicationServices
import CoreGraphics
import os

@MainActor
struct FocusedTextTargetProvider {
    private let permission: AccessibilityPermission
    private let logger = Logger(subsystem: "com.verba.app", category: "accessibility")

    init(permission: AccessibilityPermission = AccessibilityPermission()) {
        self.permission = permission
    }

    func focusedTarget(promptForPermission: Bool = false) -> FocusedTextTarget? {
        let trusted = permission.isTrusted(prompt: promptForPermission)
        print("Verba: accessibility trusted = \(trusted)")
        guard trusted else { return nil }

        guard let focusedElement = focusedElement() else {
            print("Verba: Accessibility returned no focused element")
            return nil
        }

        let role = copyAttribute(kAXRoleAttribute as CFString, from: focusedElement) as? String ?? ""
        let value = copyAttribute(kAXValueAttribute as CFString, from: focusedElement) as? String
        let selectedText = copyAttribute(kAXSelectedTextAttribute as CFString, from: focusedElement) as? String
        let selectedRange = copyAttribute(kAXSelectedTextRangeAttribute as CFString, from: focusedElement)
        let isTextLike = Self.textRoles.contains(role)
            || value != nil
            || selectedText != nil
            || selectedRange != nil
        guard isTextLike else {
            logger.info("Focused element is not text-like; role=\(role, privacy: .public)")
            return nil
        }
        let frame = copyFrame(from: focusedElement)
        logger.info("Focused text target found; role=\(role, privacy: .public)")

        return FocusedTextTarget(
            element: focusedElement,
            role: role,
            value: value,
            selectedText: selectedText,
            frame: frame
        )
    }

    private static let textRoles: Set<String> = [
        kAXTextFieldRole as String,
        kAXTextAreaRole as String,
        kAXComboBoxRole as String,
        kAXTextFieldRole as String,
    ]

    private func focusedElement() -> AXUIElement? {
        if let frontmostApplication = NSWorkspace.shared.frontmostApplication {
            let application = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
            if let value = copyAttribute(kAXFocusedUIElementAttribute as CFString, from: application),
               CFGetTypeID(value) == AXUIElementGetTypeID() {
                return unsafeDowncast(value, to: AXUIElement.self)
            }
        }

        let systemWide = AXUIElementCreateSystemWide()
        guard let value = copyAttribute(kAXFocusedUIElementAttribute as CFString, from: systemWide),
              CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return nil
        }
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    private func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let value else { return nil }
        return value
    }

    private func copyFrame(from element: AXUIElement) -> CGRect? {
        guard
            let positionValue = copyAttribute(kAXPositionAttribute as CFString, from: element),
            let sizeValue = copyAttribute(kAXSizeAttribute as CFString, from: element)
        else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard
            CFGetTypeID(positionValue) == AXValueGetTypeID(),
            CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else {
            return nil
        }
        let typedPosition = unsafeDowncast(positionValue, to: AXValue.self)
        let typedSize = unsafeDowncast(sizeValue, to: AXValue.self)
        guard
            AXValueGetValue(typedPosition, .cgPoint, &position),
            AXValueGetValue(typedSize, .cgSize, &size)
        else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }
}
