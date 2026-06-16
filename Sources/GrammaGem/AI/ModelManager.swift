import Foundation

/// Manages the one-time download of the local LLM weights from Hugging Face.
/// This is one of the only three network touchpoints in the product (model
/// download, license activate/validate, update checks) — and it never sends
/// user text.
@MainActor
final class ModelManager: ObservableObject {
    enum State: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case ready
        case failed(String)
    }

    @Published private(set) var state: State = .notDownloaded
    @Published var selectedRepo: String = AppConfig.Model.defaultRepo

    /// Local cache directory for downloaded weights.
    var modelsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("GrammaGem/Models", isDirectory: true)
    }

    func isModelPresent(repo: String) -> Bool {
        let dir = modelsDirectory.appendingPathComponent(repo.replacingOccurrences(of: "/", with: "_"))
        return FileManager.default.fileExists(atPath: dir.path)
    }

    /// TODO(real-integration): stream the model files from Hugging Face into
    /// `modelsDirectory` (resumable, with progress), then hand the path to the
    /// MLX runtime. This stub simulates the lifecycle so onboarding UI works.
    func download(repo: String? = nil) async {
        let target = repo ?? selectedRepo
        selectedRepo = target

        if isModelPresent(repo: target) {
            state = .ready
            return
        }

        do {
            try FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        } catch {
            state = .failed(error.localizedDescription)
            return
        }

        // Simulated progress (replace with real URLSession download tasks).
        state = .downloading(progress: 0)
        for step in 1...10 {
            try? await Task.sleep(nanoseconds: 120_000_000)
            state = .downloading(progress: Double(step) / 10.0)
        }
        Log.ai.info("Model marked ready (stubbed download): \(target, privacy: .public)")
        state = .ready
    }
}
