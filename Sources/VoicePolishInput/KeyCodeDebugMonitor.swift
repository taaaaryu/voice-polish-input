import AppKit
import Foundation

final class KeyCodeDebugMonitor {
    var onEvent: ((String) -> Void)?

    private var globalKeyDownMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var localKeyDownMonitor: Any?
    private var localFlagsMonitor: Any?

    deinit {
        stop()
    }

    func start() {
        guard globalKeyDownMonitor == nil else { return }

        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.emit(event: event, source: "global keyDown")
        }
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.emit(event: event, source: "global flagsChanged")
        }

        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.emit(event: event, source: "local keyDown")
            return event
        }
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.emit(event: event, source: "local flagsChanged")
            return event
        }
    }

    func stop() {
        if let token = globalKeyDownMonitor {
            NSEvent.removeMonitor(token)
            globalKeyDownMonitor = nil
        }
        if let token = globalFlagsMonitor {
            NSEvent.removeMonitor(token)
            globalFlagsMonitor = nil
        }
        if let token = localKeyDownMonitor {
            NSEvent.removeMonitor(token)
            localKeyDownMonitor = nil
        }
        if let token = localFlagsMonitor {
            NSEvent.removeMonitor(token)
            localFlagsMonitor = nil
        }
    }

    private func emit(event: NSEvent, source: String) {
        let chars = event.charactersIgnoringModifiers ?? ""
        let outputChars = chars.isEmpty ? "-" : chars
        let message = "\(source) | keyCode=\(event.keyCode) | flags=\(event.modifierFlags.rawValue) | chars=\(outputChars)"
        onEvent?(message)
    }
}

