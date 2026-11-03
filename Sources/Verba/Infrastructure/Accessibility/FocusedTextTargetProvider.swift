import ApplicationServices
import CoreGraphics

@MainActor
struct FocusedTextTargetProvider {
    private let permission: AccessibilityPermission

    init(permission: AccessibilityPermission = AccessibilityPermission()) {
        self.permission = permission
    }

    func focusedTarget(promptForPermission: Bool = true) -> FocusedTextTarget? {
        guard permission.isTrusted(prompt: promptForPermission) else { return nil }

        let systemWide = AXUIElementCreateSystemWide()
        guard let focusedValue = copyAttribute(
            kAXFocusedUIElementAttribute as CFString,
            from: systemWide
        ) else {
            return nil
        }
        guard CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else { return nil }
        let focusedElement = unsafeDowncast(focusedValue, to: AXUIElement.self)

        let role = copyAttribute(kAXRoleAttribute as CFString, from: focusedElement) as? String ?? ""
        guard Self.textRoles.contains(role) else { return nil }

        let value = copyAttribute(kAXValueAttribute as CFString, from: focusedElement) as? String
        let selectedText = copyAttribute(kAXSelectedTextAttribute as CFString, from: focusedElement) as? String
        let frame = copyFrame(from: focusedElement)

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
        kAXTextFieldRole as String
    ]

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
