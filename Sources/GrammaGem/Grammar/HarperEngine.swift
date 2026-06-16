import Foundation

/// STUB standing in for the real Harper core.
///
/// TODO(real-integration): replace the rule set below with calls into the Harper
/// Rust crate over C-FFI (`harper_check(text) -> spans`). This stub implements a
/// handful of Harper-style deterministic rules so the system loop, live
/// underlines, and tests have something real to exercise. It runs in well under
/// 10ms and is fully offline — matching Harper's performance profile.
final class HarperEngine: GrammarEngine {
    var ignoreList: Set<String> = []

    func check(_ text: String) -> [Suggestion] {
        var out: [Suggestion] = []
        let ns = text as NSString

        // Rule 1 — repeated word ("the the" -> "the").
        out += matches(in: text, pattern: #"\b(\w+)\s+\1\b"#) { match in
            let full = ns.substring(with: match.range)
            let firstWord = ns.substring(with: match.range(at: 1))
            guard !ignoreList.contains(firstWord.lowercased()) else { return nil }
            return Suggestion(
                location: match.range.location, length: match.range.length,
                original: full, replacement: firstWord,
                kind: .repetition, message: "Repeated word")
        }

        // Rule 2 — lowercase standalone "i" -> "I".
        out += matches(in: text, pattern: #"(?<=\s|^)i(?=\s|$|')"#) { match in
            Suggestion(
                location: match.range.location, length: match.range.length,
                original: "i", replacement: "I",
                kind: .capitalization, message: "Capitalize the pronoun “I”")
        }

        // Rule 3 — a few common confusions / typos.
        let confusions: [(String, String, GrammarKind, String)] = [
            (#"\btheir\b(?=\s+(any|are|is|was|were)\b)"#, "there", .grammar, "Did you mean “there”?"),
            (#"\bteh\b"#, "the", .spelling, "Spelling"),
            (#"\brecieve\b"#, "receive", .spelling, "Spelling (i before e)"),
            (#"\bcheckin\b"#, "check in", .phrasing, "“check in” is two words"),
            (#"\blmk\b"#, "let me know", .phrasing, "Expand abbreviation"),
            (#"(?<=\s|^)u(?=\s|$)"#, "you", .phrasing, "Expand “u”"),
        ]
        for (pattern, replacement, kind, message) in confusions {
            out += matches(in: text, pattern: pattern) { match in
                let original = ns.substring(with: match.range)
                guard !ignoreList.contains(original.lowercased()) else { return nil }
                return Suggestion(
                    location: match.range.location, length: match.range.length,
                    original: original, replacement: replacement,
                    kind: kind, message: message)
            }
        }

        // Rule 4 — sentence should start uppercase (very light heuristic).
        // (Left to the real Harper integration; intentionally omitted to avoid
        //  false positives in this stub.)

        return out.sorted { $0.location < $1.location }
    }

    // MARK: - Regex helper

    private func matches(
        in text: String, pattern: String,
        _ make: (NSTextCheckingResult) -> Suggestion?
    ) -> [Suggestion] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let full = NSRange(text.startIndex..., in: text)
        return re.matches(in: text, range: full).compactMap(make)
    }
}
