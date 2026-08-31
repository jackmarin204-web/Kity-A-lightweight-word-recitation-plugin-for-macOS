import AppKit
import ApplicationServices

struct TextSnapshot: Equatable {
    let contextBeforeCaret: String
    let caretRange: NSRange
    let caretRect: CGRect?
    let windowRect: CGRect?
}

enum AXRead {
    static func value<T>(_ element: AXUIElement, _ attribute: CFString, as: T.Type) -> T? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &raw) == .success else {
            return nil
        }
        return raw as? T
    }

    static func parameterized<T>(
        _ element: AXUIElement,
        _ attribute: CFString,
        parameter: CFTypeRef,
        as: T.Type
    ) -> T? {
        var raw: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            attribute,
            parameter,
            &raw
        ) == .success else {
            return nil
        }
        return raw as? T
    }
}

enum TextProbe {
    static let maximumContextLength = 48

    static func snapshot(from element: AXUIElement) -> TextSnapshot? {
        guard let selectedValue: AXValue = AXRead.value(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            as: AXValue.self
        ) else {
            return nil
        }

        var selectedRange = CFRange()
        guard AXValueGetType(selectedValue) == .cfRange,
              AXValueGetValue(selectedValue, .cfRange, &selectedRange),
              selectedRange.location >= 0,
              selectedRange.length == 0 else {
            return nil
        }

        let caretLocation = selectedRange.location
        let contextLength = min(maximumContextLength, caretLocation)
        var contextRange = CFRange(
            location: max(0, caretLocation - contextLength),
            length: contextLength
        )
        guard let contextRangeValue = AXValueCreate(.cfRange, &contextRange),
              let context: String = AXRead.parameterized(
                element,
                kAXStringForRangeParameterizedAttribute as CFString,
                parameter: contextRangeValue,
                as: String.self
              ),
              context.utf16.count <= maximumContextLength else {
            return nil
        }

        let caretRect = boundsNearCaret(element: element, caretLocation: caretLocation)
        let windowRect = windowFrame(for: element)

        return TextSnapshot(
            contextBeforeCaret: context,
            caretRange: NSRange(location: caretLocation, length: 0),
            caretRect: caretRect,
            windowRect: windowRect
        )
    }

    private static func boundsNearCaret(
        element: AXUIElement,
        caretLocation: Int
    ) -> CGRect? {
        guard caretLocation > 0 else { return nil }

        let length = min(2, caretLocation)
        var range = CFRange(location: caretLocation - length, length: length)
        guard let rangeValue = AXValueCreate(.cfRange, &range),
              let boundsValue: AXValue = AXRead.parameterized(
                element,
                kAXBoundsForRangeParameterizedAttribute as CFString,
                parameter: rangeValue,
                as: AXValue.self
              ) else {
            return nil
        }

        var bounds = CGRect.zero
        guard AXValueGetType(boundsValue) == .cgRect,
              AXValueGetValue(boundsValue, .cgRect, &bounds) else {
            return nil
        }
        return bounds
    }

    private static func windowFrame(for element: AXUIElement) -> CGRect? {
        guard let window: AXUIElement = AXRead.value(
            element,
            kAXWindowAttribute as CFString,
            as: AXUIElement.self
        ),
        let origin = pointValue(window, attribute: kAXPositionAttribute as CFString),
        let size = sizeValue(window, attribute: kAXSizeAttribute as CFString) else {
            return nil
        }
        return CGRect(origin: origin, size: size)
    }

    private static func pointValue(
        _ element: AXUIElement,
        attribute: CFString
    ) -> CGPoint? {
        guard let value: AXValue = AXRead.value(element, attribute, as: AXValue.self) else {
            return nil
        }
        var point = CGPoint.zero
        guard AXValueGetType(value) == .cgPoint,
              AXValueGetValue(value, .cgPoint, &point) else {
            return nil
        }
        return point
    }

    private static func sizeValue(
        _ element: AXUIElement,
        attribute: CFString
    ) -> CGSize? {
        guard let value: AXValue = AXRead.value(element, attribute, as: AXValue.self) else {
            return nil
        }
        var size = CGSize.zero
        guard AXValueGetType(value) == .cgSize,
              AXValueGetValue(value, .cgSize, &size) else {
            return nil
        }
        return size
    }
}
