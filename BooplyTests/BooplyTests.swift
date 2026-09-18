import XCTest
@testable import Booply

final class GrowWithMeEngineTests: XCTestCase {
    private func date(monthsAgo months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: -months, to: .now)!
    }

    func testNewbornStage() {
        XCTAssertEqual(Stage.current(birthdate: date(monthsAgo: 0)), .newborn)
        XCTAssertEqual(Stage.current(birthdate: date(monthsAgo: 3)), .newborn)
    }

    func testCauseEffectStage() {
        XCTAssertEqual(Stage.current(birthdate: date(monthsAgo: 4)), .causeEffect)
        XCTAssertEqual(Stage.current(birthdate: date(monthsAgo: 7)), .causeEffect)
    }

    func testSoundsWordsStage() {
        XCTAssertEqual(Stage.current(birthdate: date(monthsAgo: 8)), .soundsWords)
        XCTAssertEqual(Stage.current(birthdate: date(monthsAgo: 14)), .soundsWords)
    }

    func testMatchingStage() {
        XCTAssertEqual(Stage.current(birthdate: date(monthsAgo: 15)), .matching)
        XCTAssertEqual(Stage.current(birthdate: date(monthsAgo: 24)), .matching)
    }

    func testAllWorldsCovered() {
        XCTAssertEqual(WorldCatalog.all.count, 8)
        for world in WorldCatalog.all {
            XCTAssertTrue(world.minStage <= world.maxStage)
        }
    }

    func testFreeTierGetsTwoWorlds() {
        let enabled = Set(WorldCatalog.all.map(\.id))
        let worlds = WorldCatalog.worldsFor(birthdate: date(monthsAgo: 10), enabled: enabled, pro: false)
        XCTAssertEqual(worlds.count, 2)
    }

    func testProGetsAllEligible() {
        let enabled = Set(WorldCatalog.all.map(\.id))
        let pro = WorldCatalog.worldsFor(birthdate: date(monthsAgo: 10), enabled: enabled, pro: true)
        XCTAssertGreaterThan(pro.count, 2)
    }

    func testRotationStableWithinSameDay() {
        let enabled = Set(WorldCatalog.all.map(\.id))
        let now = Date()
        let a = WorldCatalog.worldsFor(birthdate: date(monthsAgo: 10), now: now, enabled: enabled, pro: true)
        let b = WorldCatalog.worldsFor(birthdate: date(monthsAgo: 10), now: now, enabled: enabled, pro: true)
        XCTAssertEqual(a.map(\.id), b.map(\.id))
    }

    func testDisabledWorldExcluded() {
        let enabled = Set(["bubbles"])
        let worlds = WorldCatalog.worldsFor(birthdate: date(monthsAgo: 10), enabled: enabled, pro: true)
        XCTAssertTrue(worlds.contains { $0.id == "bubbles" })
    }
}

final class MilestoneRulesTests: XCTestCase {
    func testSoundFollowMilestone() {
        let result = MilestoneRules.suggestions(tapCount: 5, focusedSeconds: 10, soundFollows: 3, stage: .soundsWords)
        XCTAssertTrue(result.contains { $0.title == "Imitates sounds" })
    }

    func testSoundFollowRequiresStage() {
        let result = MilestoneRules.suggestions(tapCount: 5, focusedSeconds: 10, soundFollows: 3, stage: .causeEffect)
        XCTAssertFalse(result.contains { $0.title == "Imitates sounds" })
    }

    func testReachMilestoneOnlyCauseEffect() {
        let result = MilestoneRules.suggestions(tapCount: 30, focusedSeconds: 10, soundFollows: 0, stage: .causeEffect)
        XCTAssertTrue(result.contains { $0.title == "Reaches with purpose" })
    }

    func testFocusMilestone() {
        let result = MilestoneRules.suggestions(tapCount: 1, focusedSeconds: 200, soundFollows: 0, stage: .matching)
        XCTAssertTrue(result.contains { $0.title == "Sustained attention" })
    }

    func testNoFalsePositives() {
        let result = MilestoneRules.suggestions(tapCount: 2, focusedSeconds: 5, soundFollows: 0, stage: .newborn)
        XCTAssertTrue(result.isEmpty)
    }
}

final class PurchaseTierTests: XCTestCase {
    @MainActor
    func testInitialTierIsFree() {
        let manager = PurchaseManager.shared
        XCTAssertFalse(manager.isPro)
    }
}
