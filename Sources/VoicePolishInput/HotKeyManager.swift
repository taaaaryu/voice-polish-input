import Carbon
import Foundation

final class HotKeyManager {
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?

    var isEnabled: Bool = false {
        didSet { isEnabled ? register() : unregister() }
    }

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    deinit {
        unregister()
    }

    private func register() {
        guard hotKeyRef == nil else { return }

        let hotKeyID = EventHotKeyID(signature: OSType(0x56504948), id: 1) // 'VPIH'
        let modifiers: UInt32 = 0
        let keyCode: UInt32 = UInt32(kVK_F13)

        var handler: EventHandlerRef?
        let pressedType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let releasedType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyReleased)
        )

        let statusInstall = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hkID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                guard err == noErr, hkID.id == 1 else { return noErr }
                let kind = GetEventKind(event)
                if kind == UInt32(kEventHotKeyPressed) {
                    manager.onPress?()
                } else if kind == UInt32(kEventHotKeyReleased) {
                    manager.onRelease?()
                }
                return noErr
            },
            2,
            [pressedType, releasedType],
            Unmanaged.passUnretained(self).toOpaque(),
            &handler
        )

        guard statusInstall == noErr else { return }
        eventHandler = handler

        var ref: EventHotKeyRef?
        let statusRegister = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        guard statusRegister == noErr else {
            unregister()
            return
        }

        hotKeyRef = ref
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
