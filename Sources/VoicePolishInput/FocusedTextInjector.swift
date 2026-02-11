import ApplicationServices
import Carbon
import Foundation

enum TextInjectionError: LocalizedError {
    case noFocusedElement
    case unsupportedElement
    case axError(AXError)
    case typeFallbackNotAllowed
    case accessibilityNotTrusted
    case keyEventUnavailable

    var errorDescription: String? {
        switch self {
        case .noFocusedElement:
            return "No focused UI element"
        case .unsupportedElement:
            return "Focused element does not support text insertion"
        case .axError(let err):
            return "Accessibility error: \(err.rawValue)"
        case .typeFallbackNotAllowed:
            return "Key-event fallback is disabled"
        case .accessibilityNotTrusted:
            return "Accessibility permission is not granted for VoicePolishInput"
        case .keyEventUnavailable:
            return "Key-event fallback unavailable (check Input Monitoring permission)"
        }
    }
}

final class FocusedTextInjector {
    typealias FocusTarget = AXUIElement

    func captureCurrentFocusTarget() throws -> FocusTarget {
        guard isAccessibilityTrusted() else { throw TextInjectionError.accessibilityNotTrusted }
        return try currentFocusedElement()
    }

    func insert(text: String, allowTypeFallback: Bool, target: FocusTarget? = nil) throws {
        if (try? insertViaAccessibility(text: text, target: target)) == true {
            return
        }

        guard allowTypeFallback else { throw TextInjectionError.typeFallbackNotAllowed }
        try typeViaKeyEvents(text: text)
    }

    private func insertViaAccessibility(text: String, target: FocusTarget?) throws -> Bool {
        guard isAccessibilityTrusted() else { return false }

        if let target, try insert(text: text, into: target) {
            return true
        }
        let focusedElement = try currentFocusedElement()
        return try insert(text: text, into: focusedElement)
    }

    private func insert(text: String, into focusedElement: AXUIElement) throws -> Bool {
        var isSettable: DarwinBoolean = false
        let errSettable = AXUIElementIsAttributeSettable(focusedElement, kAXValueAttribute as CFString, &isSettable)
        if errSettable != .success || !isSettable.boolValue {
            return false
        }

        var value: CFTypeRef?
        let errValue = AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &value)
        guard errValue == .success else { return false }
        guard let current = value as? String else { return false }

        var rangeValue: CFTypeRef?
        let errRange = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &rangeValue)
        guard errRange == .success, let axRange = rangeValue else {
            return false
        }

        guard CFGetTypeID(axRange) == AXValueGetTypeID() else { return false }
        let axValue = axRange as! AXValue
        var range = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &range) else { return false }

        let ns = current as NSString
        let before = ns.substring(with: NSRange(location: 0, length: range.location))
        let afterStart = range.location + range.length
        let after = afterStart <= ns.length ? ns.substring(from: afterStart) : ""
        let newValue = before + text + after

        let errSet = AXUIElementSetAttributeValue(focusedElement, kAXValueAttribute as CFString, newValue as CFTypeRef)
        guard errSet == .success else { return false }

        var newRange = CFRange(location: range.location + (text as NSString).length, length: 0)
        if let newRangeValue = AXValueCreate(.cfRange, &newRange) {
            _ = AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, newRangeValue)
        }

        return true
    }

    private func currentFocusedElement() throws -> AXUIElement {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused)
        guard err == .success else { throw TextInjectionError.axError(err) }
        guard let element = focused else { throw TextInjectionError.noFocusedElement }
        return element as! AXUIElement
    }

    private func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    private func typeViaKeyEvents(text: String) throws {
        for scalar in text.unicodeScalars {
            if scalar == "\n" {
                try keyPress(keyCode: CGKeyCode(kVK_Return))
                continue
            }

            let utf16 = String(scalar).utf16
            guard let codeUnit = utf16.first else { continue }
            try keyPress(unicode: codeUnit)
        }
    }

    private func keyPress(unicode: UInt16) throws {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            throw TextInjectionError.keyEventUnavailable
        }
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            throw TextInjectionError.keyEventUnavailable
        }

        var u = unicode
        down.keyboardSetUnicodeString(stringLength: 1, unicodeString: &u)
        up.keyboardSetUnicodeString(stringLength: 1, unicodeString: &u)

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private func keyPress(keyCode: CGKeyCode) throws {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            throw TextInjectionError.keyEventUnavailable
        }
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            throw TextInjectionError.keyEventUnavailable
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
