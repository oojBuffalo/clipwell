import Carbon

enum GlobalShortcut: UInt32, CaseIterable {
    case showHistory = 1, copyFirst, copySecond, copyThird

    var chord: String {
        switch self {
        case .showHistory: return "⌃⌥V"
        case .copyFirst: return "⌃⌥1"
        case .copySecond: return "⌃⌥2"
        case .copyThird: return "⌃⌥3"
        }
    }

    fileprivate var keyCode: Int {
        switch self {
        case .showHistory: return kVK_ANSI_V
        case .copyFirst: return kVK_ANSI_1
        case .copySecond: return kVK_ANSI_2
        case .copyThird: return kVK_ANSI_3
        }
    }
}

@MainActor
final class GlobalHotKeys {
    // A four-character Carbon signature identifies events delivered to Clipwell.
    private static let signature: OSType = 0x4370576C // CpWl
    private let onPress: (GlobalShortcut) -> Void
    private var handler: EventHandlerRef?
    private var registrations: [EventHotKeyRef] = []

    init(onPress: @escaping (GlobalShortcut) -> Void) {
        self.onPress = onPress
    }

    func register() -> [String] {
        let target = GetApplicationEventTarget()
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let result = InstallEventHandler(target, { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            var key = EventHotKeyID()
            let result = GetEventParameter(
                event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &key
            )
            guard result == noErr else { return result }
            // Application event handlers run on the main event loop.
            return MainActor.assumeIsolated {
                guard key.signature == GlobalHotKeys.signature,
                      let shortcut = GlobalShortcut(rawValue: key.id)
                else { return OSStatus(eventNotHandledErr) }
                Unmanaged<GlobalHotKeys>.fromOpaque(context).takeUnretainedValue().onPress(shortcut)
                return noErr
            }
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard result == noErr else { return GlobalShortcut.allCases.map(\.chord) }

        var unavailable: [String] = []
        for shortcut in GlobalShortcut.allCases {
            var registration: EventHotKeyRef?
            let result = RegisterEventHotKey(
                UInt32(shortcut.keyCode), UInt32(controlKey | optionKey),
                EventHotKeyID(signature: Self.signature, id: shortcut.rawValue),
                target, OptionBits(kEventHotKeyExclusive), &registration
            )
            if result == noErr, let registration {
                registrations.append(registration)
            } else {
                unavailable.append(shortcut.chord)
            }
        }
        return unavailable
    }

    func unregister() {
        for registration in registrations { UnregisterEventHotKey(registration) }
        registrations.removeAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }
}
