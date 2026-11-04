import AppKit

struct ShortcutConfiguration: Sendable {
    let keyCode: UInt16
    let requiredModifiers: NSEvent.ModifierFlags

    static let `default` = ShortcutConfiguration(
        keyCode: 15,
        requiredModifiers: [.control, .option, .command]
    )

    func matches(_ event: NSEvent) -> Bool {
        event.type == .keyDown
            && event.keyCode == keyCode
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == requiredModifiers
    }
}
