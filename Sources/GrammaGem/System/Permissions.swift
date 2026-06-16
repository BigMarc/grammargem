import Foundation
import AppKit
import ApplicationServices

/// Tracks and requests the macOS permissions GrammaGem needs to read & replace
/// text system-wide: **Accessibility** (required) and, for the synthetic-keystroke
/// clipboard fallback, **Input Monitoring** may also be prompted by the system.
@MainActor
final class Permissions: ObservableObject {
    @Published private(set) var accessibilityTrusted: Bool = false

    init() {
        refresh()
    }

    /// True when the app is trusted for the Accessibility API.
    func refresh() {
        accessibilityTrusted = AXIsProcessTrusted()
    }

    /// Prompt for Accessibility (shows the system dialog the first time).
    func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        accessibilityTrusted = AXIsProcessTrustedWithOptions(options)
    }

    /// Deep-link to the relevant System Settings pane.
    func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func openInputMonitoringSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    /// Poll until the user grants Accessibility (used by onboarding to advance
    /// automatically once permission flips on). Cancels when `accessibilityTrusted`.
    func startPollingUntilGranted(interval: TimeInterval = 1.0) {
        guard !accessibilityTrusted else { return }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { timer.invalidate(); return }
                self.refresh()
                if self.accessibilityTrusted { timer.invalidate() }
            }
        }
    }
}
