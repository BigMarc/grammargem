import Foundation

/// STUB standing in for the real MLX-backed local LLM.
///
/// TODO(real-integration): load the model via mlx-swift from
/// `ModelManager.modelsDirectory`, build the prompt from the action's system
/// prompt + the user's text, and stream tokens (target: first token < 1s on
/// M-series). Everything stays on-device — this method must never hit the network.
///
/// The stub produces deterministic, plausible transformations so the capture →
/// engine → replace loop and the entitlement gating can be exercised end-to-end
/// without the multi-gigabyte model present.
final class MLXEngine: AIEngine {
    private let ready: Bool

    init(ready: Bool = true) {
        self.ready = ready
    }

    var isReady: Bool { ready }

    func run(_ action: AIAction, on text: String) async throws -> String {
        guard ready else { throw AIEngineError.modelNotReady }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        switch action {
        case .rewriteClarity, .rewrite:
            return tidy(trimmed)
        case .adjustTone(let tone):
            return apply(tone: tone, to: tidy(trimmed))
        case .ask(let instruction):
            return follow(instruction: instruction, on: trimmed)
        case .translate(let language):
            return "[\(language)] " + tidy(trimmed)
        case .applyMode(let mode):
            return applyMode(mode, to: trimmed)
        }
    }

    func detectTone(_ text: String) async -> Tone {
        let lower = text.lowercased()
        if lower.contains("!") || lower.contains("🚀") { return .punchy }
        if lower.contains("therefore") || lower.contains("hereby") { return .academic }
        if lower.contains("hey") || lower.contains("lol") { return .friendly }
        return .professional
    }

    // MARK: - Deterministic stand-in transforms

    private func tidy(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: " i ", with: " I ")
        out = out.replacingOccurrences(of: "lmk", with: "let me know")
        out = out.replacingOccurrences(of: "u ", with: "you ")
        if let first = out.first, first.isLowercase {
            out.replaceSubrange(out.startIndex...out.startIndex, with: String(first).uppercased())
        }
        if let last = out.last, !".!?".contains(last) { out.append(".") }
        return out
    }

    private func apply(tone: Tone, to s: String) -> String {
        switch tone {
        case .professional: return s
        case .friendly: return "Hi! " + s
        case .confident: return s.replacingOccurrences(of: "I think ", with: "")
        case .academic: return "It is worth noting that " + s.prefix(1).lowercased() + s.dropFirst()
        case .punchy: return s.replacingOccurrences(of: ". ", with: ".\n")
        }
    }

    private func follow(instruction: String, on s: String) -> String {
        let i = instruction.lowercased()
        if i.contains("short") { return String(s.split(separator: " ").prefix(8).joined(separator: " ")) + "." }
        if i.contains("formal") { return apply(tone: .academic, to: tidy(s)) }
        if i.contains("translate") { return "[translated] " + tidy(s) }
        return tidy(s)
    }

    private func applyMode(_ mode: WritingMode, to s: String) -> String {
        switch mode.id {
        case "email": return "Hi,\n\n\(tidy(s))\n\nThanks!"
        case "post": return apply(tone: .punchy, to: tidy(s))
        case "academic": return apply(tone: .academic, to: tidy(s))
        case "slack": return s.lowercased()
        case "code": return "// " + tidy(s)
        default: return tidy(s)
        }
    }
}
