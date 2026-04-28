import Foundation
import SwiftUI

enum Tile: String, Codable {
    case wall, floor, stairs, shop, shrine
}

enum ItemKind: String, Codable {
    case consumable, weapon, armor, accessory
}

enum ItemRarity: String, Codable {
    case common, uncommon, rare, legendary

    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .legendary: return .yellow
        }
    }
}

struct ItemDef: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let kind: ItemKind
    let rarity: ItemRarity
    let description: String
    let price: Int
    let stack: Bool
    var attack: Int = 0
    var defense: Int = 0
    var maxHP: Int = 0
    var goldMultiplier: Double = 1
    var heal: Int = 0
    var damage: Int = 0
    var area: Int = 0
    var teleports: Bool = false
}

struct MonsterDef: Codable, Hashable {
    let name: String
    let icon: String
    let hp: Int
    let attack: Int
    let defense: Int
    let xp: Int
    let behavior: String
    let isBoss: Bool
}

struct ShrineDef: Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let description: String
}

enum GameData {
    static let mapWidth = 20
    static let mapHeight = 15
    static let tileSize: CGFloat = 40

    static let items: [String: ItemDef] = [
        "potion_hp": ItemDef(id: "potion_hp", name: "Health Potion", icon: "🧪", kind: .consumable, rarity: .common, description: "Restores 15 HP.", price: 20, stack: true, heal: 15),
        "potion_hp_g": ItemDef(id: "potion_hp_g", name: "Great Potion", icon: "⚗️", kind: .consumable, rarity: .uncommon, description: "Restores 40 HP.", price: 50, stack: true, heal: 40),
        "bomb": ItemDef(id: "bomb", name: "Fire Bomb", icon: "💣", kind: .consumable, rarity: .uncommon, description: "Deals 20 damage nearby.", price: 40, stack: true, damage: 20, area: 1),
        "scroll_tele": ItemDef(id: "scroll_tele", name: "Phase Scroll", icon: "📜", kind: .consumable, rarity: .rare, description: "Teleports to a random floor tile.", price: 60, stack: true, teleports: true),
        "dagger_rusty": ItemDef(id: "dagger_rusty", name: "Rusty Dagger", icon: "🔪", kind: .weapon, rarity: .common, description: "A blunt, old blade.", price: 0, stack: false, attack: 3),
        "sword_iron": ItemDef(id: "sword_iron", name: "Iron Sword", icon: "⚔️", kind: .weapon, rarity: .uncommon, description: "Reliable steel.", price: 80, stack: false, attack: 8),
        "sword_fire": ItemDef(id: "sword_fire", name: "Flame Brand", icon: "🔥", kind: .weapon, rarity: .rare, description: "Burning with magical fury.", price: 250, stack: false, attack: 15),
        "blade_vorpal": ItemDef(id: "blade_vorpal", name: "Vorpal Blade", icon: "✨", kind: .weapon, rarity: .legendary, description: "Snicker-snack!", price: 600, stack: false, attack: 30),
        "robe_cloth": ItemDef(id: "robe_cloth", name: "Cloth Robe", icon: "🥋", kind: .armor, rarity: .common, description: "Better than nothing.", price: 0, stack: false, defense: 1),
        "vest_leather": ItemDef(id: "vest_leather", name: "Leather Vest", icon: "🧥", kind: .armor, rarity: .uncommon, description: "Toughened hide.", price: 70, stack: false, defense: 4),
        "mail_chain": ItemDef(id: "mail_chain", name: "Chainmail", icon: "⛓️", kind: .armor, rarity: .rare, description: "Sturdy links.", price: 200, stack: false, defense: 10),
        "plate_dragon": ItemDef(id: "plate_dragon", name: "Dragonscale", icon: "🐉", kind: .armor, rarity: .legendary, description: "Forged from drake scales.", price: 700, stack: false, defense: 25),
        "charm_luck": ItemDef(id: "charm_luck", name: "Lucky Charm", icon: "🍀", kind: .accessory, rarity: .uncommon, description: "Monsters drop more gold.", price: 120, stack: false, goldMultiplier: 1.5),
        "ring_vigor": ItemDef(id: "ring_vigor", name: "Ring of Vigor", icon: "💍", kind: .accessory, rarity: .rare, description: "+20 Max HP.", price: 200, stack: false, maxHP: 20),
        "amulet_wrath": ItemDef(id: "amulet_wrath", name: "Amulet of Wrath", icon: "📿", kind: .accessory, rarity: .rare, description: "+10 Atk, -5 Def.", price: 220, stack: false, attack: 10, defense: -5)
    ]

    static let monsters = [
        MonsterDef(name: "Slime", icon: "🟢", hp: 8, attack: 4, defense: 1, xp: 5, behavior: "normal", isBoss: false),
        MonsterDef(name: "Goblin", icon: "👺", hp: 15, attack: 7, defense: 2, xp: 12, behavior: "flee", isBoss: false),
        MonsterDef(name: "Skeleton", icon: "💀", hp: 25, attack: 12, defense: 5, xp: 25, behavior: "normal", isBoss: false),
        MonsterDef(name: "Orc", icon: "🐗", hp: 45, attack: 18, defense: 8, xp: 50, behavior: "normal", isBoss: false),
        MonsterDef(name: "Beholder", icon: "👁️", hp: 60, attack: 25, defense: 5, xp: 100, behavior: "ranged", isBoss: false),
        MonsterDef(name: "Dragon", icon: "🐲", hp: 150, attack: 40, defense: 20, xp: 500, behavior: "boss", isBoss: false)
    ]

    static let bosses = [
        MonsterDef(name: "Ogre Warden", icon: "🛡️", hp: 80, attack: 18, defense: 8, xp: 140, behavior: "boss", isBoss: true),
        MonsterDef(name: "Crystal Lich", icon: "💀", hp: 120, attack: 26, defense: 10, xp: 240, behavior: "boss", isBoss: true),
        MonsterDef(name: "Ancient Dragon", icon: "🐲", hp: 180, attack: 36, defense: 18, xp: 500, behavior: "boss", isBoss: true)
    ]

    static let shrines = [
        ShrineDef(id: "healing", name: "Mercy Shrine", icon: "✚", description: "Spend 25 gold to restore 35 HP."),
        ShrineDef(id: "power", name: "Blood Shrine", icon: "⛧", description: "Gain +2 Attack, lose 5 max HP.")
    ]
}
