import Foundation
import AppKit

/// Reports the frontmost application so App-Aware mode switching can pick the
/// right Writing Mode. Pure local introspection — no network, no logging of content.
@MainActor
final class AppDetector {
    struct FrontApp: Equatable {
        let bundleID: String
        let name: String
    }

    /// The app currently in the foreground (the one the hotkey will act on).
    func frontmost() -> FrontApp? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return FrontApp(
            bundleID: app.bundleIdentifier ?? "unknown",
            name: app.localizedName ?? "App")
    }

    /// The Writing Mode App-Aware would auto-apply for the current frontmost app.
    func suggestedMode() -> WritingMode? {
        guard let front = frontmost() else { return nil }
        return ModeRegistry.mode(forBundleID: front.bundleID)
    }
}
