import SwiftUI

// MARK: - Shortcuts

struct ShortcutsView: View {
    var body: some View {
        DetailScaffold(
            title: "Shortcuts",
            subtitle: "Global hotkeys that work in every app."
        ) {
            Card {
                shortcutRow(name: "Fix selection", keys: ["⌘", ";"], detail: "Grammar + clarity, in place")
                Divider()
                shortcutRow(name: "Ask GrammaGem", keys: ["⌘", "'"], detail: "Rewrite with an instruction")
            }
            Card {
                Label("Custom shortcuts", systemImage: "wand.and.stars")
                    .font(.headline)
                Text("A built-in recorder for fully customizable shortcuts is on the roadmap. For now the defaults above are active system-wide.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private func shortcutRow(name: String, keys: [String], detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { k in
                    Text(k)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(nsColor: .controlColor), in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.12)))
                }
            }
        }
    }
}

// MARK: - AI Model

struct ModelView: View {
    @EnvironmentObject private var app: AppState
    @EnvironmentObject private var gate: FeatureGate
    @EnvironmentObject private var model: ModelManager

    var body: some View {
        DetailScaffold(
            title: "AI Model",
            subtitle: "The local model that powers rewrites, tone, and Ask. Runs entirely on your Mac."
        ) {
            Card {
                Picker("Model", selection: $model.selectedRepo) {
                    Text("Qwen2.5-3B · balanced (default)").tag(AppConfig.Model.defaultRepo)
                    Text("Qwen2.5-7B · higher quality").tag(AppConfig.Model.largeRepo)
                }
                .disabled(!gate.entitlements.canUseLargeModel)

                if !gate.entitlements.canUseLargeModel {
                    HStack { Image(systemName: "lock.fill").foregroundStyle(GG.gold); Text("The larger model is available on the lifetime license.").font(.caption).foregroundStyle(.secondary) }
                }
                Divider()
                ModelDownloadControls().environmentObject(app)
            }

            Card {
                Label("Private by default", systemImage: "lock.shield")
                    .font(.headline)
                Text("The model is downloaded once from Hugging Face and then runs offline. It is never bundled in the app, and it never sends your text anywhere.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Privacy

struct PrivacyView: View {
    @EnvironmentObject private var usage: UsageStats
    @State private var confirmReset = false

    var body: some View {
        DetailScaffold(
            title: "Privacy",
            subtitle: "What touches the network — and what never does."
        ) {
            Card {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill").font(.title2).foregroundStyle(GG.emerald)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("0 bytes of your writing leave this Mac").font(.headline)
                        Text("Every correction and rewrite runs locally. No telemetry is collected.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
            }

            Card {
                Text("The only times GrammaGem uses the network").font(.headline)
                networkRow("One-time AI model download", "Hugging Face, on first run")
                Divider()
                networkRow("License activation & checks", "To enforce your device cap")
                Divider()
                networkRow("App updates", "Signed update checks")
                Text("None of these ever include the text you write.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Card {
                Text("Local data").font(.headline)
                Text("Your dictionary, snippets, modes, and usage counts live only on this Mac.")
                    .font(.callout).foregroundStyle(.secondary)
                Button(role: .destructive) { confirmReset = true } label: {
                    Label("Reset usage statistics", systemImage: "arrow.counterclockwise")
                }
                .confirmationDialog("Reset all local usage statistics?", isPresented: $confirmReset) {
                    Button("Reset", role: .destructive) { usage.reset() }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }

    private func networkRow(_ title: String, _ detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.forward.circle").foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
