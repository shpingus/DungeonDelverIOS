import XCTest
@testable import DungeonDelverIOS

final class DungeonDelverIOSTests: XCTestCase {
    func testRingOfVigorEquipAndUnequipAtFullHealth() {
        var player = PlayerState()
        player.inventory.append(InventorySlot(id: "ring_vigor", count: 1))

        _ = player.equipInventory(at: 1)
        XCTAssertEqual(player.hp, 56)
        XCTAssertEqual(player.maxHP, 56)

        _ = player.unequip(.accessory)
        XCTAssertEqual(player.hp, 36)
        XCTAssertEqual(player.maxHP, 36)
    }

    func testRingOfVigorDamagedAndLowHPUnequip() {
        var player = PlayerState()
        player.hp = 10
        player.inventory.append(InventorySlot(id: "ring_vigor", count: 1))

        _ = player.equipInventory(at: 1)
        XCTAssertEqual(player.hp, 30)
        XCTAssertEqual(player.maxHP, 56)

        player.hp = 5
        _ = player.unequip(.accessory)
        XCTAssertEqual(player.hp, 1)
        XCTAssertEqual(player.maxHP, 36)
    }

    func testBossFloorStartsLockedWithBoss() {
        var player = PlayerState()
        var dungeon = DungeonState()
        dungeon.floor = 5
        dungeon.generate(player: &player)

        XCTAssertTrue(dungeon.isBossFloor)
        XCTAssertFalse(dungeon.bossDefeated)
        XCTAssertTrue(dungeon.monsters.contains(where: \.isBoss))
        XCTAssertTrue(dungeon.map.contains { $0.contains(.stairs) })
    }

    func testTeleportReturnsOnlyPlainFloorTiles() throws {
        var player = PlayerState()
        var dungeon = DungeonState()
        dungeon.generate(player: &player)

        for _ in 0..<20 {
            let point = try XCTUnwrap(dungeon.randomWalkableFloor())
            XCTAssertEqual(dungeon.tile(at: point), .floor)
            XCTAssertNil(dungeon.monsterIndex(at: point))
        }
    }

    func testHighScorePrefersDeeperThenFasterRuns() {
        let defaults = UserDefaults(suiteName: "DungeonDelverIOSTests-\(UUID().uuidString)")!
        let storage = RunStorage(defaults: defaults)

        let first = storage.evaluateHighScore(RunSummary(floorReached: 3, elapsedSeconds: 100, monstersDefeated: 2, goldCollected: 10))
        XCTAssertTrue(first.isNewBest)
        XCTAssertEqual(first.score.floorReached, 3)

        let slowerSameFloor = storage.evaluateHighScore(RunSummary(floorReached: 3, elapsedSeconds: 120, monstersDefeated: 5, goldCollected: 40))
        XCTAssertFalse(slowerSameFloor.isNewBest)
        XCTAssertEqual(slowerSameFloor.score.elapsedSeconds, 100)

        let fasterSameFloor = storage.evaluateHighScore(RunSummary(floorReached: 3, elapsedSeconds: 80, monstersDefeated: 1, goldCollected: 1))
        XCTAssertTrue(fasterSameFloor.isNewBest)
        XCTAssertEqual(fasterSameFloor.score.elapsedSeconds, 80)

        let deeper = storage.evaluateHighScore(RunSummary(floorReached: 4, elapsedSeconds: 500, monstersDefeated: 1, goldCollected: 1))
        XCTAssertTrue(deeper.isNewBest)
        XCTAssertEqual(deeper.score.floorReached, 4)
    }

    func testSavedRunRoundTripsDungeonAndShopState() throws {
        let defaults = UserDefaults(suiteName: "DungeonDelverIOSTests-\(UUID().uuidString)")!
        let storage = RunStorage(defaults: defaults)
        var player = PlayerState()
        var dungeon = DungeonState()
        dungeon.floor = 5
        dungeon.generate(player: &player)
        dungeon.bossDefeated = false

        storage.save(SavedRun(player: player, dungeon: dungeon, shopGreed: 1.7, shopStock: ["ring_vigor"], elapsedOffset: 42, savedAt: Date(), floorReached: 5))

        let saved = try XCTUnwrap(storage.load())
        XCTAssertEqual(saved.shopGreed, 1.7)
        XCTAssertEqual(saved.shopStock, ["ring_vigor"])
        XCTAssertEqual(saved.elapsedOffset, 42)
        XCTAssertEqual(saved.floorReached, 5)
        XCTAssertEqual(saved.dungeon.floor, 5)
        XCTAssertFalse(saved.dungeon.bossDefeated)
    }
}
