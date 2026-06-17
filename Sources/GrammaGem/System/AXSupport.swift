import Foundation
import ApplicationServices

/// Safe Accessibility helpers shared across the System layer.
///
/// `AXUIElementCopyAttributeValue` returning `.success` only guarantees a
/// non-null `CFTypeRef` — NOT that it is an `AXUIElement`. A misbehaving AX
/// server (Electron/Java/custom) can return a different CF type, and a forced
/// `as!` cast then traps and crashes the whole app. These helpers cast safely.
enum AX {
    /// Safely bridge a CFTypeRef to AXUIElement, returning nil on type mismatch.
    static func element(_ ref: CFTypeRef?) -> AXUIElement? {
        guard let ref, CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        return (ref as! AXUIElement) // safe: type id verified above
    }

    /// Copy an attribute as an `AXUIElement` (nil on failure/type mismatch).
    static func copyElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success else {
            return nil
        }
        return AX.element(ref)
    }

    /// Copy an attribute as a `String` (nil on failure/wrong type).
    static func copyString(_ element: AXUIElement, _ attribute: String) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success else {
            return nil
        }
        return ref as? String
    }

    /// Bound each cross-process AX message so a wedged target app can't hang us.
    static func setMessagingTimeout(_ element: AXUIElement, _ seconds: Float) {
        AXUIElementSetMessagingTimeout(element, seconds)
    }
}
