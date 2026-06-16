import SwiftUI

/// First-run onboarding: explains why GrammaGem needs Accessibility, deep-links
/// to System Settings, and advances automatically once permission is granted.
struct OnboardingView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to GrammaGem")
                    .font(.largeTitle.bold())
                Text("A private, on-device writing assistant that works in every app.")
                    .foregroundStyle(.secondary)
            }

            stepCard(
                number: 1,
                title: "Grant Accessibility access",
                body: "GrammaGem reads the text you select and writes the correction back. macOS requires Accessibility permission for this. Your text is processed on-device and never leaves your Mac.",
                granted: app.permissions.accessibilityTrusted
            ) {
                HStack {
                    Button("Open System Settings") { app.permissions.openAccessibilitySettings() }
                    Button("Request permission") {
                        app.permissions.requestAccessibility()
                        app.permissions.startPollingUntilGranted()
                    }
                }
            }

            stepCard(
                number: 2,
                title: "Download the on-device model (optional)",
                body: "Grammar & spelling work instantly with no download. The AI rewrite/tone/Ask features use a small model downloaded once from Hugging Face — then everything runs offline.",
                granted: app.model.state == .ready
            ) {
                ModelDownloadControls()
                    .environmentObject(app)
            }

            Spacer()

            HStack {
                Spacer()
                Button(app.permissions.accessibilityTrusted ? "Done" : "Continue without permission") {
                    app.showOnboardingDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { app.permissions.refresh() }
    }

    private func stepCard<Controls: View>(
        number: Int, title: String, body: String, granted: Bool,
        @ViewBuilder controls: () -> Controls
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(granted ? Color.green : Color.accentColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                if granted {
                    Image(systemName: "checkmark").foregroundStyle(.white).font(.caption.bold())
                } else {
                    Text("\(number)").font(.callout.bold()).foregroundStyle(.tint)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline)
                Text(body).font(.callout).foregroundStyle(.secondary)
                controls()
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Model download progress + trigger, shared by onboarding and settings.
struct ModelDownloadControls: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        switch app.model.state {
        case .notDownloaded:
            Button("Download model") { Task { await app.model.download() } }
        case .downloading(let progress):
            ProgressView(value: progress) { Text("Downloading… \(Int(progress * 100))%") }
                .frame(maxWidth: 260)
        case .ready:
            Label("Model ready", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case .failed(let message):
            VStack(alignment: .leading) {
                Label("Download failed", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(message).font(.caption).foregroundStyle(.secondary)
                Button("Retry") { Task { await app.model.download() } }
            }
        }
    }
}
