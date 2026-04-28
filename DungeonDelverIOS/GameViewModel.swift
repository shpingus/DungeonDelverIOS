import Combine
import Foundation

enum Overlay: Equatable {
    case title, confirmNewRun, shop, levelUp, death, help
}

enum Direction {
    case up, down, left, right, wait

    var delta: Point {
        switch self {
        case .up: return Point(x: 0, y: -1)
        case .down: return Point(x: 0, y: 1)
        case .left: return Point(x: -1, y: 0)
        case .right: return Point(x: 1, y: 0)
        case .wait: return Point(x: 0, y: 0)
        }
    }
}

enum ShopTab: Hashable {
    case buy, sell
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published var player = PlayerState()
    @Published var dungeon = DungeonState()
    @Published var overlay: Overlay? = .title
    @Published var messages: [String] = ["Welcome to the dungeon, Delver."]
    @Published var shopGreed = 1.0
    @Published var shopStock: [String] = []
    @Published var shopTab: ShopTab = .buy
    @Published var highScore: HighScore?
    @Published var deathSummary: RunSummary?
    @Published var deathWasNewBest = false
    @Published var elapsedSeconds: TimeInterval = 0

    private let storage: RunStorage
    private var timer: AnyCancellable?
    private var runStartedAt: Date?
    private var elapsedOffset: TimeInterval = 0
    private var floorReached = 1
    private var isGameOver = false

    init(storage: RunStorage = .shared) {
        self.storage = storage
        highScore = storage.highScore()
        startTimer()
    }

    var canContinue: Bool { storage.hasSave }
    var isRunning: Bool { runStartedAt != nil && !isGameOver && overlay != .title }

    func requestNewRun() {
        if storage.hasSave && !isGameOver {
            overlay = .confirmNewRun
        } else {
            startNewRun(clearSave: true)
        }
    }

    func startNewRun(clearSave: Bool) {
        if clearSave { storage.clearRun() }
        player = PlayerState()
        dungeon = DungeonState()
        dungeon.generate(player: &player)
        revealAroundPlayer()
        shopGreed = 1.0
        shopStock = []
        shopTab = .buy
        runStartedAt = Date()
        elapsedOffset = 0
        elapsedSeconds = 0
        floorReached = 1
        isGameOver = false
        deathSummary = nil
        deathWasNewBest = false
        overlay = nil
        messages = ["Welcome to the Depths. Find the stairs to descend."]
        save()
    }

    func continueRun() {
        guard let saved = storage.load() else {
            storage.clearRun()
            startNewRun(clearSave: false)
            return
        }
        player = saved.player
        player.clampHP()
        dungeon = saved.dungeon
        revealAroundPlayer()
        shopGreed = saved.shopGreed
        shopStock = saved.shopStock
        shopTab = .buy
        elapsedOffset = saved.elapsedOffset
        elapsedSeconds = saved.elapsedOffset
        floorReached = saved.floorReached
        runStartedAt = Date()
        isGameOver = false
        overlay = nil
        log("Your run continues.")
    }

    func closeHelp() {
        overlay = isRunning ? nil : .title
    }

    func move(_ direction: Direction) {
        guard isRunning, overlay == nil else { return }
        let delta = direction.delta
        let next = Point(x: player.position.x + delta.x, y: player.position.y + delta.y)

        if let monsterIndex = dungeon.monsterIndex(at: next) {
            combat(attackerIsPlayer: true, monsterIndex: monsterIndex)
            tick()
            save()
            return
        }

        guard dungeon.isWalkable(next) else { return }
        player.position = next
        resolveCurrentTile()
        revealAroundPlayer()
        tick()
        save()
    }

    func useInventory(at index: Int) {
        guard isRunning, overlay == nil, player.inventory.indices.contains(index),
              let item = GameData.items[player.inventory[index].id] else { return }

        if item.kind == .consumable {
            useConsumable(item, at: index)
        } else if let equipped = player.equipInventory(at: index) {
            log("Equipped \(equipped.name).")
        }
        player.clampHP()
        save()
    }

    func unequip(_ kind: ItemKind) {
        guard isRunning, overlay == nil else { return }
        if let item = player.unequip(kind) {
            log("Unequipped \(item.name).")
        } else {
            log("Inventory full.")
        }
        save()
    }

    func applyLevelUp(_ stat: LevelStat) {
        player.applyLevelUp(stat)
        overlay = nil
        save()
    }

    func setShopTab(_ tab: ShopTab) {
        shopTab = tab
    }

    func buy(_ itemID: String) {
        guard let item = GameData.items[itemID] else { return }
        let price = Int(Double(item.price) * shopGreed)
        guard player.gold >= price else {
            log("Not enough gold.")
            return
        }
        guard player.pickup(itemID) else {
            log("Inventory full.")
            return
        }
        _ = player.spendGold(price)
        shopStock.removeAll { $0 == itemID }
        shopGreed = min(3.0, shopGreed + 0.05)
        save()
    }

    func sellInventory(at index: Int) {
        guard player.inventory.indices.contains(index),
              let item = GameData.items[player.inventory[index].id] else { return }
        let price = Int(Double(item.price) * 0.4)
        guard price > 0 else { return }
        player.addGold(price)
        player.removeInventory(at: index)
        save()
    }

    func closeShop() {
        overlay = nil
        save()
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsedSeconds = self.currentElapsed()
                self.highScore = self.storage.highScore()
            }
    }

    private func currentElapsed() -> TimeInterval {
        guard let runStartedAt, !isGameOver else { return elapsedOffset }
        return elapsedOffset + Date().timeIntervalSince(runStartedAt)
    }

    private func save() {
        guard let runStartedAt, !isGameOver else { return }
        storage.save(SavedRun(player: player, dungeon: dungeon, shopGreed: shopGreed, shopStock: shopStock, elapsedOffset: elapsedOffset + Date().timeIntervalSince(runStartedAt), savedAt: Date(), floorReached: floorReached))
    }

    private func resolveCurrentTile() {
        if let itemIndex = dungeon.itemIndex(at: player.position) {
            let groundItem = dungeon.items[itemIndex]
            if player.pickup(groundItem.itemID) {
                log("You found a \(GameData.items[groundItem.itemID]?.name ?? "treasure")!")
                dungeon.items.remove(at: itemIndex)
            } else {
                log("Inventory full.")
            }
        }

        switch dungeon.tile(at: player.position) {
        case .stairs:
            if dungeon.isBossFloor && !dungeon.bossDefeated {
                log("The stairs are sealed until the floor boss falls.")
            } else {
                descendFloor()
            }
        case .shop:
            openShop()
        case .shrine:
            activateShrine()
        default:
            break
        }
    }

    private func descendFloor() {
        log("You descend deeper...")
        dungeon.floor += 1
        floorReached = max(floorReached, dungeon.floor)
        player.floorsReached = max(player.floorsReached, dungeon.floor)
        shopGreed = max(1.0, shopGreed - 0.2)
        shopStock = []
        dungeon.generate(player: &player)
        revealAroundPlayer()
    }

    private func openShop() {
        if shopStock.isEmpty {
            let purchasable = GameData.items.values.filter { $0.price > 0 }
            shopStock = (0..<6).compactMap { _ in purchasable.randomElement()?.id }
        }
        overlay = .shop
    }

    private func activateShrine() {
        guard let index = dungeon.shrineIndex(at: player.position) else { return }
        if dungeon.shrines[index].type == "healing" {
            guard player.spendGold(25) else {
                log("The shrine demands 25 gold.")
                return
            }
            player.hp = min(player.maxHP, player.hp + 35)
            log("The shrine mends your wounds for 25 gold.")
        } else {
            guard player.baseMaxHP > 15 else {
                log("The shrine refuses your weakened blood.")
                return
            }
            player.baseAttack += 2
            player.baseMaxHP -= 5
            player.clampHP(minimum: 1)
            log("The shrine sharpens your wrath and drains your vitality.")
        }
        dungeon.shrines[index].used = true
        dungeon.map[player.position.y][player.position.x] = .floor
    }

    private func useConsumable(_ item: ItemDef, at index: Int) {
        if item.heal > 0 {
            player.hp = min(player.maxHP, player.hp + item.heal)
            log("Used \(item.name).")
        }
        if item.teleports, let tile = dungeon.randomWalkableFloor() {
            player.position = tile
            revealAroundPlayer()
            log("The scroll bends space around you.")
        }
        if item.damage > 0 {
            for monsterIndex in dungeon.monsters.indices {
                let monster = dungeon.monsters[monsterIndex]
                if abs(monster.position.x - player.position.x) <= item.area &&
                    abs(monster.position.y - player.position.y) <= item.area {
                    dungeon.monsters[monsterIndex].hp -= item.damage
                }
            }
            dungeon.monsters.filter { $0.hp <= 0 }.forEach { kill($0) }
            log("The bomb explodes!")
        }
        player.removeInventory(at: index)
    }

    private func combat(attackerIsPlayer: Bool, monsterIndex: Int) {
        guard dungeon.monsters.indices.contains(monsterIndex) else { return }
        if attackerIsPlayer {
            let damage = max(1, player.attack - dungeon.monsters[monsterIndex].defense + Int.random(in: -2...2))
            dungeon.monsters[monsterIndex].hp -= damage
            log("You hit \(dungeon.monsters[monsterIndex].name) for \(damage) damage.")
            if dungeon.monsters[monsterIndex].hp <= 0 {
                kill(dungeon.monsters[monsterIndex])
            }
        } else {
            let monster = dungeon.monsters[monsterIndex]
            let damage = max(1, monster.attack - player.defense + Int.random(in: -2...2))
            player.hp -= damage
            log("\(monster.name) hits you for \(damage) damage.")
            if player.hp <= 0 {
                gameOver()
            }
        }
    }

    private func kill(_ monster: MonsterState) {
        log("The \(monster.name) dies! +\(monster.xp) XP")
        if player.addXP(monster.xp) {
            log("Level Up! You are now level \(player.level)")
            overlay = .levelUp
        }
        player.monstersDefeated += 1
        let gold = Int(Double(monster.xp) / 2.0 * (player.equipment.accessory == "charm_luck" ? 1.5 : 1.0))
        player.addGold(gold)
        dungeon.monsters.removeAll { $0.id == monster.id }

        if monster.isBoss {
            dungeon.bossDefeated = true
            if let reward = GameData.items.values.filter({ $0.price >= 80 }).randomElement() {
                dungeon.items.append(GroundItem(position: monster.position, itemID: reward.id))
            }
            log("The boss seal breaks. The stairs open.")
        }
    }

    private func tick() {
        guard !isGameOver, overlay == nil else { return }
        let ids = dungeon.monsters.map(\.id)
        for id in ids {
            guard let index = dungeon.monsters.firstIndex(where: { $0.id == id }) else { continue }
            let monster = dungeon.monsters[index]
            let distance = abs(monster.position.x - player.position.x) + abs(monster.position.y - player.position.y)
            guard distance < 6 else { continue }
            if distance == 1 {
                combat(attackerIsPlayer: false, monsterIndex: index)
                continue
            }
            let horizontal = Point(x: monster.position.x + (player.position.x - monster.position.x).signum(), y: monster.position.y)
            let vertical = Point(x: monster.position.x, y: monster.position.y + (player.position.y - monster.position.y).signum())
            if canMonsterMove(to: horizontal) {
                dungeon.monsters[index].position = horizontal
            } else if canMonsterMove(to: vertical) {
                dungeon.monsters[index].position = vertical
            }
        }
    }

    private func canMonsterMove(to point: Point) -> Bool {
        dungeon.isWalkable(point) && dungeon.monsterIndex(at: point) == nil && player.position != point
    }

    private func revealAroundPlayer() {
        for y in 0..<GameData.mapHeight {
            for x in 0..<GameData.mapWidth {
                let point = Point(x: x, y: y)
                if hypot(Double(x - player.position.x), Double(y - player.position.y)) < 5 {
                    dungeon.explored.insert(point)
                }
            }
        }
    }

    private func gameOver() {
        elapsedOffset = currentElapsed()
        isGameOver = true
        let summary = RunSummary(floorReached: floorReached, elapsedSeconds: elapsedOffset, monstersDefeated: player.monstersDefeated, goldCollected: player.goldCollected)
        let result = storage.evaluateHighScore(summary)
        highScore = result.score
        deathSummary = summary
        deathWasNewBest = result.isNewBest
        storage.clearRun()
        overlay = .death
    }

    private func log(_ message: String) {
        messages.append(message)
        if messages.count > 15 {
            messages.removeFirst(messages.count - 15)
        }
    }
}
