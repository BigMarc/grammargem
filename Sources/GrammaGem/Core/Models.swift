import Foundation

// MARK: - Plans & tiers

/// License tiers. `free` is the unlicensed default; paid tiers carry a device cap.
enum Tier: String, Codable, CaseIterable, Hashable {
    case free
    case solo
    case personal
    case studio

    /// Number of Macs a license may be activated on (enforced via Lemon Squeezy
    /// variant activation limits + our offline cap).
    var deviceCap: Int {
        switch self {
        case .free: return 1
        case .solo: return 1
        case .personal: return 2
        case .studio: return 4
        }
    }

    var isPaid: Bool { self != .free }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .solo: return "Solo"
        case .personal: return "Personal"
        case .studio: return "Studio"
        }
    }
}

// MARK: - Grammar (Layer 1)

/// Categories Harper surfaces. Layer-1 corrections are deterministic + instant.
enum GrammarKind: String, Codable {
    case spelling
    case grammar
    case punctuation
    case phrasing
    case repetition
    case capitalization
}

/// A single grammar suggestion over a span of the input text.
struct Suggestion: Identifiable, Equatable {
    let id = UUID()
    /// UTF-16 offset + length, so it maps cleanly onto `NSRange` / AX ranges.
    let location: Int
    let length: Int
    let original: String
    let replacement: String
    let kind: GrammarKind
    let message: String

    var range: NSRange { NSRange(location: location, length: length) }
}

// MARK: - AI actions (Layer 2)

/// The local-LLM-powered actions. All of these share the free daily counter.
enum AIAction: Equatable {
    case rewriteClarity          // clarity / conciseness
    case adjustTone(Tone)        // detect + shift tone
    case rewrite                 // full paraphrase
    case ask(String)             // free-form instruction ("make formal", "shorten")
    case translate(language: String)
    case applyMode(WritingMode)  // Mode-based rewrite

    /// Whether this action is gated behind a paid license (free tier still gets
    /// a limited daily allowance of these — see `FeatureGate`).
    var isPaidAction: Bool {
        switch self {
        case .applyMode(let mode): return mode.isPaid
        default: return true
        }
    }
}

enum Tone: String, Codable, CaseIterable {
    case professional
    case friendly
    case confident
    case academic
    case punchy
}

// MARK: - Writing modes

/// A Writing Mode is just a named system-prompt preset for the local LLM.
struct WritingMode: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var systemPrompt: String
    /// Free tier ships only the `polish` mode; the rest are paid.
    var isPaid: Bool
    /// Optional length cap / auto-format hints surfaced in App-Aware settings.
    var lengthCap: Int?
    var autoFormat: String?
}

// MARK: - Engine results

/// Outcome of running the system-wide capture → engine → replace loop.
enum ProcessOutcome: Equatable {
    case replaced(String)        // text was rewritten in place
    case noSelection             // nothing was selected to act on
    case blockedByEntitlement(String) // hit a paywall / daily limit
    case failed(String)          // capture/replace/engine error (message)
}
