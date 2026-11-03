import ApplicationServices

@MainActor
final class AccessibilityTextInserter: TextInserter {
    func insert(_ text: String, into target: FocusedTextTarget) throws {
        let result = AXUIElementSetAttributeValue(
            target.element,
            kAXSelectedTextAttribute as CFString,
            text as CFString
        )
        guard result == .success else {
            throw TextInsertionError.failed(result.rawValue)
        }
    }
}

enum TextInsertionError: Error, Equatable {
    case failed(Int32)
}
