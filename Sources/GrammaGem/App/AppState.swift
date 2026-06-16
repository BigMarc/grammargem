import Foundation
import AppKit
import SwiftUI

/// Root application model. Owns the engines, managers, and the system-wide
/// coordinator, wires the global hotkeys, and presents the on-demand windows.
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    // Engines (Layer 1 + Layer 2)
    let grammar: GrammarEngine
    let ai: AIEngine

    // Managers
    let permissions: Permissions
    let model: ModelManager
    let license: LicenseManager
    let gate: FeatureGate
    let detector: AppDetector
    let hotkeys: HotkeyManager
    let dictionary: PersonalDictionary
    private let capture: TextCapture
    let coordinator: TextReplacementCoordinator

    // UI state
    @Published var lastStatus: String = "Ready"
    @Published var askText: String = ""
    @Published var appAwareEnabled: Bool = false

    private var onboardingWindow: NSWindow?
    private var askWindow: NSWindow?

    private init() {
        let harper = HarperEngine()
        grammar = harper
        ai = MLXEngine(ready: true)
        permissions = Permissions()
        model = ModelManager()
        license = LicenseManager()
        gate = FeatureGate(license: license)
        detector = AppDetector()
        capture = TextCapture()
        hotkeys = HotkeyManager()
        dictionary = PersonalDictionary()
        coordinator = TextReplacementCoordinator(
            capture: capture, grammar: harper, ai: ai, gate: gate, detector: detector)
    }

    /// Called once at launch (from the AppDelegate).
    func start() {
        // Menu-bar app: no Dock icon (works even without LSUIElement in Info.plist).
        NSApp.setActivationPolicy(.accessory)

        hotkeys.onAction = { [weak self] action in
            Task { await self?.handle(action) }
        }
        hotkeys.registerDefaults()

        permissions.refresh()
        appAwareEnabled = gate.appAwareEnabled
        syncIgnoreList()

        if !permissions.accessibilityTrusted {
            showOnboarding()
        }

        Task { await license.validateIfNeeded() }
        Log.app.info("GrammaGem started. Licensed: \(self.license.isLicensed, privacy: .public)")
    }

    // MARK: - Hotkey handling

    func handle(_ action: HotkeyManager.Action) async {
        switch action {
        case .fix:
            await runFix()
        case .ask:
            showAsk()
        }
    }

    func runFix() async {
        present(await coordinator.handleFix())
    }

    func runAsk() async {
        let instruction = askText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instruction.isEmpty else { return }
        present(await coordinator.handleAsk(instruction))
        askWindow?.close()
    }

    /// Apply the Mode suggested by the frontmost app (App-Aware, paid).
    func runAppAwareRewrite() async {
        guard gate.appAwareEnabled else {
            present(.blockedByEntitlement("App-aware switching is part of the lifetime upgrade."))
            return
        }
        guard let mode = detector.suggestedMode() else {
            lastStatus = "No mode mapped for the current app."
            return
        }
        present(await coordinator.handleApplyMode(mode))
    }

    private func present(_ outcome: ProcessOutcome) {
        switch outcome {
        case .replaced:
            lastStatus = "Fixed ✓"
        case .noSelection:
            lastStatus = "Select some text first."
        case .blockedByEntitlement(let reason):
            lastStatus = reason
            notify(title: "Upgrade required", body: reason)
        case .failed(let message):
            lastStatus = message
        }
    }

    private func notify(title: String, body: String) {
        // Lightweight, content-free alert (no user text ever leaves the device).
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    // MARK: - On-demand windows (AppKit-hosted SwiftUI; reliable for menu-bar apps)

    func showOnboarding() {
        if onboardingWindow == nil {
            let host = NSHostingController(rootView: OnboardingView().environmentObject(self))
            let win = NSWindow(contentViewController: host)
            win.title = "Welcome to GrammaGem"
            win.styleMask = [.titled, .closable, .fullSizeContentView]
            win.setContentSize(NSSize(width: 540, height: 600))
            win.isReleasedWhenClosed = false
            win.center()
            onboardingWindow = win
        }
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow?.makeKeyAndOrderFront(nil)
    }

    func showAsk() {
        askText = ""
        if askWindow == nil {
            let host = NSHostingController(rootView: AskView().environmentObject(self))
            let win = NSWindow(contentViewController: host)
            win.title = "Ask GrammaGem"
            win.styleMask = [.titled, .closable]
            win.setContentSize(NSSize(width: 460, height: 220))
            win.isReleasedWhenClosed = false
            win.center()
            win.level = .floating
            askWindow = win
        }
        NSApp.activate(ignoringOtherApps: true)
        askWindow?.makeKeyAndOrderFront(nil)
    }

    func showOnboardingDismiss() {
        onboardingWindow?.close()
    }

    func showAskDismiss() {
        askWindow?.close()
    }

    // MARK: - Personal dictionary (gated adds)

    @discardableResult
    func addDictionaryEntry(_ word: String) -> FeatureGate.Decision {
        let decision = gate.canAddDictionaryEntry(currentCount: dictionary.entries.count)
        if case .allowed = decision {
            dictionary.add(word)
            syncIgnoreList()
        }
        return decision
    }

    func removeDictionaryEntry(_ word: String) {
        dictionary.remove(word)
        syncIgnoreList()
    }

    private func syncIgnoreList() {
        grammar.ignoreList = Set(dictionary.entries.map { $0.lowercased() })
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
