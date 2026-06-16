import XCTest
@testable import GrammaGem

final class GrammaGemTests: XCTestCase {

    // MARK: - Tiers / entitlements

    func testDeviceCapsMatchSpec() {
        XCTAssertEqual(Tier.solo.deviceCap, 1)
        XCTAssertEqual(Tier.personal.deviceCap, 2)
        XCTAssertEqual(Tier.studio.deviceCap, 4)
        XCTAssertEqual(Tier.free.deviceCap, 1)
    }

    func testFreeEntitlementsAreLimited() {
        let free = Entitlements(tier: .free)
        XCTAssertFalse(free.unlimitedAIActions)
        XCTAssertEqual(free.dailyAIActionCap, AppConfig.Limits.freeDailyAIActions)
        XCTAssertEqual(free.dictionaryCap, AppConfig.Limits.freeDictionaryCap)
        XCTAssertFalse(free.appAwareSwitching)
        XCTAssertFalse(free.allModes)
        XCTAssertTrue(free.unlimitedGrammar) // grammar is always free
    }

    func testPaidEntitlementsUnlockEverything() {
        let paid = Entitlements(tier: .personal)
        XCTAssertTrue(paid.unlimitedAIActions)
        XCTAssertEqual(paid.dailyAIActionCap, Int.max)
        XCTAssertEqual(paid.dictionaryCap, Int.max)
        XCTAssertTrue(paid.appAwareSwitching)
        XCTAssertTrue(paid.allModes)
    }

    // MARK: - Grammar (Harper stub) rules

    func testHarperFixesRepeatedWordAndCasing() {
        let harper = HarperEngine()
        let input = "hey i wanted to checkin about the the proposal"
        let fixed = harper.correct(input)
        XCTAssertFalse(fixed.contains("the the"), "repeated word should be collapsed")
        XCTAssertTrue(fixed.contains(" I "), "lowercase pronoun i should be capitalized")
        XCTAssertTrue(fixed.contains("check in"), "checkin should split into two words")
    }

    func testIgnoreListSuppressesCorrection() {
        let harper = HarperEngine()
        harper.ignoreList = ["teh"] // pretend "teh" is an intentional brand term
        let suggestions = harper.check("teh launch")
        XCTAssertFalse(suggestions.contains { $0.original.lowercased() == "teh" })
    }

    // MARK: - Modes

    func testFreeTierGetsOnlyPolishMode() {
        let free = ModeRegistry.available(for: .free)
        XCTAssertEqual(free.map(\.id), ["polish"])
        let paid = ModeRegistry.available(for: .studio)
        XCTAssertGreaterThan(paid.count, 1)
        XCTAssertTrue(paid.contains { $0.id == "email" })
    }

    func testAppAwareModeMapping() {
        XCTAssertEqual(ModeRegistry.mode(forBundleID: "com.apple.mail")?.id, "email")
        XCTAssertEqual(ModeRegistry.mode(forBundleID: "com.microsoft.VSCode")?.id, "code")
        XCTAssertNil(ModeRegistry.mode(forBundleID: "com.unknown.app"))
    }

    // MARK: - Device fingerprint

    func testDeviceFingerprintIsStableAndHashed() {
        let a = DeviceFingerprint.stableID()
        let b = DeviceFingerprint.stableID()
        XCTAssertEqual(a, b, "fingerprint must be stable across calls")
        XCTAssertFalse(a.isEmpty)
        // SHA-256 hex is 64 chars (unless the random fallback path is hit).
        XCTAssertTrue(a.count == 64 || a.count == UUID().uuidString.count)
    }
}
