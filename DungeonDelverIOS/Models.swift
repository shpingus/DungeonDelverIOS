import Foundation

struct Point: Hashable, Codable {
    var x: Int
    var y: Int
}

struct InventorySlot: Identifiable, Codable, Hashable {
    var id: String
    var count: Int
}

struct Equipment: Codable, Hashable {
    var weapon: String? = nil
    var armor: String? = nil
    var accessory: String? = nil

    subscript(kind: ItemKind) -> String? {
        get {
            switch kind {
            case .weapon: return weapon
            case .armor: return armor
            case .accessory: return accessory
            case .consumable: return nil
            }
        }
        set {
            switch kind {
            case .weapon: weapon = newValue
            case .armor: armor = newValue
            case .accessory: accessory = newValue
            case .consumable: break
            }
        }
    }
}

struct PlayerState: Codable, Hashable {
    var position = Point(x: 0, y: 0)
    var level = 1
    var xp = 0
    var nextXP = 20
    var baseMaxHP = 36
    var hp = 36
    var baseAttack = 6
    var baseDefense = 2
    var gold = 0
    var goldCollected = 0
    var monstersDefeated = 0
    var floorsReached = 1
    var inventory = [InventorySlot(id: "potion_hp", count: 2)]
    var equipment = Equipment()

    var maxHP: Int { baseMaxHP + maxHPBonus(equipment) }
    var attack: Int { baseAttack + bonus(\.attack, kinds: [.weapon, .accessory]) }
    var defense: Int { baseDefense + bonus(\.defense, kinds: [.armor, .accessory]) }

    mutating func clampHP(minimum: Int = 0) {
        hp = max(minimum, min(hp, maxHP))
    }

    func maxHPBonus(_ equipment: Equipment) -> Int {
        [equipment.weapon, equipment.armor, equipment.accessory]
            .compactMap { $0 }
            .reduce(0) { $0 + (GameData.items[$1]?.maxHP ?? 0) }
    }

    func bonus(_ keyPath: KeyPath<ItemDef, Int>, kinds: [ItemKind]) -> Int {
        kinds.reduce(0) { total, kind in
            guard let id = equipment[kind], let item = GameData.items[id] else { return total }
            return total + item[keyPath: keyPath]
        }
    }

    mutating func addGold(_ amount: Int) {
        gold += amount
        goldCollected += max(0, amount)
    }

    mutating func spendGold(_ amount: Int) -> Bool {
        guard gold >= amount else { return false }
        gold -= amount
        return true
    }

    mutating func pickup(_ itemID: String) -> Bool {
        guard let item = GameData.items[itemID] else { return false }
        if item.stack, let index = inventory.firstIndex(where: { $0.id == itemID }) {
            inventory[index].count += 1
            return true
        }
        guard inventory.count < 16 else { return false }
        inventory.append(InventorySlot(id: itemID, count: 1))
        return true
    }

    mutating func removeInventory(at index: Int) {
        guard inventory.indices.contains(index) else { return }
        inventory[index].count -= 1
        if inventory[index].count <= 0 {
            inventory.remove(at: index)
        }
    }

    mutating func equipInventory(at index: Int) -> ItemDef? {
        guard inventory.indices.contains(index), let item = GameData.items[inventory[index].id], item.kind != .consumable else { return nil }
        let previous = equipment
        let oldID = equipment[item.kind]
        equipment[item.kind] = item.id
        inventory.remove(at: index)
        if let oldID {
            _ = pickup(oldID)
        }
        applyEquipmentHPDelta(from: previous, to: equipment)
        return item
    }

    mutating func unequip(_ kind: ItemKind) -> ItemDef? {
        guard kind != .consumable, let id = equipment[kind], inventory.count < 16 else { return nil }
        let previous = equipment
        equipment[kind] = nil
        _ = pickup(id)
        applyEquipmentHPDelta(from: previous, to: equipment)
        return GameData.items[id]
    }

    mutating func applyEquipmentHPDelta(from previous: Equipment, to next: Equipment) {
        let oldMax = baseMaxHP + maxHPBonus(previous)
        let newMax = baseMaxHP + maxHPBonus(next)
        hp += newMax - oldMax
        clampHP(minimum: 1)
    }

    mutating func addXP(_ amount: Int) -> Bool {
        xp += amount
        guard xp >= nextXP else { return false }
        level += 1
        xp -= nextXP
        nextXP = Int(Double(nextXP) * 1.5)
        return true
    }

    mutating func applyLevelUp(_ stat: LevelStat) {
        switch stat {
        case .attack: baseAttack += 2
        case .defense: baseDefense += 2
        case .hp:
            baseMaxHP += 10
            hp += 10
        }
        clampHP()
    }
}

enum LevelStat: String, CaseIterable, Identifiable {
    case attack, defense, hp
    var id: String { rawValue }
    var title: String {
        switch self {
        case .attack: return "+2 Attack"
        case .defense: return "+2 Defense"
        case .hp: return "+10 Max HP"
        }
    }
}

struct MonsterState: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var position: Point
    var hp: Int
    var maxHP: Int
    var attack: Int
    var defense: Int
    var xp: Int
    var behavior: String
    var isBoss: Bool
}

struct GroundItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var position: Point
    var itemID: String
}

struct ShrineState: Identifiable, Codable, Hashable {
    var id = UUID()
    var position: Point
    var type: String
    var used: Bool = false
}

struct HighScore: Codable, Equatable {
    var floorReached: Int
    var elapsedSeconds: TimeInterval
    var completedAt: Date
}

struct RunSummary: Equatable {
    var floorReached: Int
    var elapsedSeconds: TimeInterval
    var monstersDefeated: Int
    var goldCollected: Int
}
