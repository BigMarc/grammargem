import SwiftUI

/// The dropdown shown from the menu-bar icon.
struct MenuBarContent: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Divider()

            actionRow(title: "Fix selection", shortcut: "⌘;") {
                Task { await app.runFix() }
            }
            actionRow(title: "Ask GrammaGem…", shortcut: "⌘'") {
                app.showAsk()
            }
            if app.gate.appAwareEnabled {
                actionRow(title: "Apply app-aware mode", shortcut: nil) {
                    Task { await app.runAppAwareRewrite() }
                }
            }

            Divider()

            actionRow(title: "Open GrammaGem…", shortcut: nil) {
                app.showMainWindow()
            }
            actionRow(title: "Manage devices…", shortcut: nil) {
                app.showMainWindow(select: .devices)
            }

            Divider()

            usageRow

            Divider()

            HStack {
                Button("Settings…") { openSettings() }
                Spacer()
                Button("Quit") { app.quit() }
            }
            .buttonStyle(.borderless)

            Text(app.lastStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 280)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil.and.scribble")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("GrammaGem").font(.headline)
                Text(app.license.tier.displayName + (app.license.isLicensed ? " · licensed" : " · free"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !app.permissions.accessibilityTrusted {
                Button {
                    app.showOnboarding()
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.borderless)
                .help("Accessibility permission needed")
            }
        }
    }

    @ViewBuilder
    private var usageRow: some View {
        if app.gate.entitlements.unlimitedAIActions {
            Label("Unlimited AI actions", systemImage: "infinity")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            let used = app.gate.aiActionsUsedToday
            let cap = app.gate.entitlements.dailyAIActionCap
            Label("\(max(0, cap - used)) of \(cap) free AI actions left today",
                  systemImage: "bolt")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func actionRow(title: String, shortcut: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if let shortcut {
                    Text(shortcut).foregroundStyle(.secondary).font(.callout.monospaced())
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
