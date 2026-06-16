# GrammaGem (macOS app)

A private, **on-device** writing assistant for macOS — a one-time-purchase
replacement for Grammarly. Fix grammar, sharpen tone, and rewrite anything in
**any app** via a global hotkey. Your words never leave your Mac.

Built in public. The grammar core is open-source; the repo is permissively
licensed. We sell the **signed, notarized, auto-updating build + a multi-device
license + support** — not code secrecy.

---

## Architecture (two layers)

```
GrammaGem (native menu-bar app, Swift/SwiftUI)
├─ System integration   global hotkey → capture selected text (AX API /
│                        clipboard fallback) → route to engine → replace in place
├─ Layer 1: GRAMMAR      Harper (Rust, Apache-2.0) — spelling/grammar/punctuation,
│                        deterministic, <10ms, offline. Powers live underlines. FREE.
├─ Layer 2: AI           MLX (Apple Silicon) + a small instruct model — rewrite,
│                        tone, "Ask", translate, Mode rewriting. Closes the gap. PAID.
└─ Entitlements + Licensing   free/paid gate · device-cap activation (Lemon Squeezy)
```

Network is touched **only** for: first-run model download (Hugging Face),
license activate/validate (Lemon Squeezy), and update checks (Sparkle/GitHub
Releases). **Writing never requires internet. No telemetry.**

## Repo layout

```
mac/
├─ Package.swift              SwiftPM executable (Apple-frameworks only → builds out of the box)
├─ Sources/GrammaGem/
│  ├─ App/        @main app, menu bar, onboarding, settings, Ask popover, AppState
│  ├─ System/     hotkey (Carbon), AX capture/replace + clipboard fallback, app detection, permissions
│  ├─ Grammar/    GrammarEngine protocol + Harper stub + personal dictionary
│  ├─ AI/         AIEngine protocol + MLX stub + model manager + Writing Modes
│  ├─ Licensing/  Lemon Squeezy client, device fingerprint, Keychain, license manager
│  ├─ Entitlements/ free/paid gate + daily AI counter
│  └─ Core/       config, models, logging
├─ Tests/GrammaGemTests/      unit tests (entitlements, Harper rules, fingerprint, modes)
├─ Resources/Modes/           Mode prompt presets (paid ones tuned in release only)
├─ AppSupport/                Info.plist (LSUIElement) + entitlements
├─ scripts/                   build → sign/notarize → release(Sparkle/GitHub)
└─ harper-ffi/                Rust↔Swift FFI for the real Harper core (placeholder)
```

## Build & run

```bash
cd mac
swift build            # compiles the app (Apple frameworks only)
swift test             # runs the unit tests
swift run GrammaGem     # runs as a menu-bar (accessory) app

# Package a .app bundle you can double-click:
./scripts/build.sh     # → dist/GrammaGem.app
```

On first launch, grant **Accessibility** when prompted (System Settings →
Privacy & Security → Accessibility). Without it the app degrades gracefully to a
manual paste-in window. Default hotkeys: **⌘;** fix selection, **⌘'** Ask.

> Prefer Xcode? Open `Package.swift` directly in Xcode 26 (File → Open). For a
> production app target, point it at `AppSupport/Info.plist` + entitlements.

## What's real vs. stubbed

This codebase implements the full **architecture and product logic** end-to-end,
with the heavyweight native integrations behind clean protocol seams so it
compiles with **zero external dependencies**. Search `TODO(real-integration)`.

| Area | Status |
|------|--------|
| System-wide capture → transform → replace loop | ✅ Real (AX + clipboard fallback, CGEvent ⌘C/⌘V, restore clipboard) |
| Global hotkeys | ✅ Real (Carbon `RegisterEventHotKey`) |
| Active-app detection + Mode mapping | ✅ Real (`NSWorkspace`) |
| Permissions onboarding | ✅ Real (`AXIsProcessTrusted`, deep-links, auto-advance) |
| Entitlements gate + daily AI counter (resets local midnight) | ✅ Real |
| Device fingerprint (IOPlatformUUID → SHA-256) | ✅ Real (IOKit + CryptoKit) |
| Keychain license storage | ✅ Real (Security framework) |
| Lemon Squeezy activate/validate/deactivate + hard-verify + offline grace | ✅ Real client (needs your store/product/variant IDs) |
| Personal dictionary (25 free / unlimited paid) | ✅ Real |
| Menu bar UI, Settings, Ask popover | ✅ Real (SwiftUI) |
| **Harper grammar core** | 🔌 Stub: small pure-Swift rule set; swap for the Rust FFI (`harper-ffi/`) |
| **MLX local LLM** | 🔌 Stub: deterministic transforms; swap for `mlx-swift` + downloaded model |
| **Model download** | 🔌 Stub: simulated progress; swap for real Hugging Face streaming |
| KeyboardShortcuts recorder UI / Sparkle auto-update | 🔌 Documented seams (scripts + Package.swift comments) |

### Before shipping
1. Set real IDs in [`Core/AppConfig.swift`](Sources/GrammaGem/Core/AppConfig.swift):
   Lemon Squeezy `expectedStoreID` / `expectedProductID` / per-tier `variantID`
   (set each variant's **activation limit** to the device cap: Solo 1 / Personal 2 / Studio 4),
   `bundleIdentifier`, `supportEmail`, model portal URL.
2. Replace the Harper stub with the FFI (`harper-ffi/README.md`).
3. Replace the MLX stub + model manager with `mlx-swift` and real HF download.
4. Add `KeyboardShortcuts` + `Sparkle` SwiftPM deps (commented in `Package.swift`).
5. Codesign + notarize via `scripts/sign-notarize.sh` (needs Apple Developer Program).

## Honest gaps (by design)

- **No plagiarism detection.** It needs a server-side corpus + live index, which
  breaks both the $0-cost rule and the privacy promise. Out of scope, not faked.
- **The gate is intentionally soft.** Because the code is public, a technical
  user could compile a build with the gate removed — that's the VoiceInk model
  and it's fine. The product is the signed build + license + support, not secrecy.

## Cost model — $0 marginal cost per customer

| Item | Cost |
|------|------|
| Server / database | $0 (none exists) |
| AI inference (on device) | $0 |
| Model hosting (Hugging Face) | $0 |
| Update hosting (GitHub Releases) | $0 |
| License validation (Lemon Squeezy) | $0 (included) |
| Apple Developer Program | $99 / year (fixed) |
| Payment processor | ~5% + fee per sale |

## License

Permissive (MIT/Apache-2.0) to maximize trust and stars. Monetization is the
signed binary + multi-device license, not the source.
