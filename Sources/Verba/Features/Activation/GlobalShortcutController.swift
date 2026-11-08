import AppKit
import Carbon.HIToolbox
import os

@MainActor
final class GlobalShortcutController: ActivationController {
    private let logger = Logger(subsystem: "com.verba.app", category: "activation")
    private let configuration: ShortcutConfiguration
    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?
    private var monitors: [Any] = []

    var isEnabled: Bool {
        hotKey != nil || !monitors.isEmpty
    }

    var onActivation: (() -> Void)?

    init(configuration: ShortcutConfiguration = .default) {
        self.configuration = configuration
    }

    func start() {
        guard !isEnabled else { return }
        logger.info("Starting global shortcut monitor")

        if registerCarbonHotKey() {
            logger.info("Carbon global hot key registered")
            return
        }

        logger.info("Carbon global hot key unavailable; using NSEvent monitor fallback")
        installNSEventMonitors()
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()

        if let hotKey {
            UnregisterEventHotKey(hotKey)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        hotKey = nil
        eventHandler = nil
    }

    private func registerCarbonHotKey() -> Bool {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.carbonEventHandler,
            1,
            &eventType,
            pointer,
            &eventHandler
        )
        guard handlerStatus == noErr else { return false }

        let hotKeyID = EventHotKeyID(signature: 0x5652_4241, id: 1)
        let modifiers = UInt32(controlKey | optionKey | cmdKey)
        let registerStatus = RegisterEventHotKey(
            UInt32(configuration.keyCode),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        guard registerStatus == noErr else {
            RemoveEventHandler(eventHandler)
            eventHandler = nil
            return false
        }
        return true
    }

    private func installNSEventMonitors() {
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                guard self.configuration.matches(event) else { return }
                self.handleActivation()
            }
        }
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, configuration.matches(event) else { return event }
            handleActivation()
            return nil
        }
        monitors = [globalMonitor, localMonitor].compactMap { $0 }
        logger.info("Shortcut monitors installed: \(self.monitors.count)")
    }

    private func handleActivation() {
        logger.info("Activation shortcut recognized")
        onActivation?()
    }

    private static let carbonEventHandler: EventHandlerUPP = { _, event, userData in
        guard let userData else { return noErr }
        var hotKeyID = EventHotKeyID()
        let parameterStatus = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard parameterStatus == noErr, hotKeyID.id == 1 else {
            return parameterStatus
        }
        let controller = Unmanaged<GlobalShortcutController>
            .fromOpaque(userData)
            .takeUnretainedValue()
        print("Carbon hot key callback received")
        DispatchQueue.main.async { [weak controller] in
            controller?.handleActivation()
        }
        return noErr
    }
}
