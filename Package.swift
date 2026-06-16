// swift-tools-version:5.10
import PackageDescription

// GrammaGem — native macOS menu-bar writing assistant.
//
// This package builds with ONLY Apple frameworks so it compiles cleanly out of
// the box (`swift build`). The heavyweight third-party pieces from the spec —
// Harper (Rust grammar core), MLX (local LLM), KeyboardShortcuts, Sparkle — are
// abstracted behind protocols with working stub implementations and clearly
// marked `TODO(real-integration)` seams. See README.md for wiring the real deps.
let package = Package(
    name: "GrammaGem",
    platforms: [
        .macOS(.v14) // Apple Silicon, macOS 14+ (per the product spec)
    ],
    products: [
        .executable(name: "GrammaGem", targets: ["GrammaGem"])
    ],
    dependencies: [
        // TODO(real-integration): add when wiring real engines / distribution.
        //   .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
        //   .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
        //   .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.18.0"),
        // The Harper grammar core is bundled via a Rust static lib + C-FFI; see harper-ffi/.
    ],
    targets: [
        .executableTarget(
            name: "GrammaGem",
            path: "Sources/GrammaGem"
        ),
        .testTarget(
            name: "GrammaGemTests",
            dependencies: ["GrammaGem"],
            path: "Tests/GrammaGemTests"
        ),
    ]
)
