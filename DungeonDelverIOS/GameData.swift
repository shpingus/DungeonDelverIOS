import Foundation
import SwiftUI
import UIKit

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
        "potion_hp": ItemDef(id: "potion_hp", name: "Health Potion", icon: "item.potion.hp", kind: .consumable, rarity: .common, description: "Restores 18 HP.", price: 18, stack: true, heal: 18),
        "potion_hp_g": ItemDef(id: "potion_hp_g", name: "Great Potion", icon: "item.potion.great", kind: .consumable, rarity: .uncommon, description: "Restores 45 HP.", price: 45, stack: true, heal: 45),
        "bomb": ItemDef(id: "bomb", name: "Fire Bomb", icon: "item.bomb", kind: .consumable, rarity: .uncommon, description: "Deals 20 damage nearby.", price: 40, stack: true, damage: 20, area: 1),
        "scroll_tele": ItemDef(id: "scroll_tele", name: "Phase Scroll", icon: "item.scroll", kind: .consumable, rarity: .rare, description: "Teleports to a random floor tile.", price: 60, stack: true, teleports: true),
        "dagger_rusty": ItemDef(id: "dagger_rusty", name: "Rusty Dagger", icon: "item.dagger", kind: .weapon, rarity: .common, description: "A blunt, old blade.", price: 12, stack: false, attack: 2),
        "sword_iron": ItemDef(id: "sword_iron", name: "Iron Sword", icon: "item.sword", kind: .weapon, rarity: .uncommon, description: "Reliable steel.", price: 80, stack: false, attack: 8),
        "sword_fire": ItemDef(id: "sword_fire", name: "Flame Brand", icon: "item.fire_sword", kind: .weapon, rarity: .rare, description: "Burning with magical fury.", price: 250, stack: false, attack: 15),
        "blade_vorpal": ItemDef(id: "blade_vorpal", name: "Vorpal Blade", icon: "item.vorpal", kind: .weapon, rarity: .legendary, description: "Snicker-snack!", price: 600, stack: false, attack: 30),
        "robe_cloth": ItemDef(id: "robe_cloth", name: "Cloth Robe", icon: "item.robe", kind: .armor, rarity: .common, description: "Better than nothing.", price: 12, stack: false, defense: 1),
        "vest_leather": ItemDef(id: "vest_leather", name: "Leather Vest", icon: "item.vest", kind: .armor, rarity: .uncommon, description: "Toughened hide.", price: 70, stack: false, defense: 4),
        "mail_chain": ItemDef(id: "mail_chain", name: "Chainmail", icon: "item.chainmail", kind: .armor, rarity: .rare, description: "Sturdy links.", price: 200, stack: false, defense: 10),
        "plate_dragon": ItemDef(id: "plate_dragon", name: "Dragonscale", icon: "item.dragonscale", kind: .armor, rarity: .legendary, description: "Forged from drake scales.", price: 700, stack: false, defense: 25),
        "charm_luck": ItemDef(id: "charm_luck", name: "Lucky Charm", icon: "item.charm", kind: .accessory, rarity: .uncommon, description: "Monsters drop more gold.", price: 120, stack: false, goldMultiplier: 1.5),
        "ring_vigor": ItemDef(id: "ring_vigor", name: "Ring of Vigor", icon: "item.ring", kind: .accessory, rarity: .rare, description: "+20 Max HP.", price: 200, stack: false, maxHP: 20),
        "amulet_wrath": ItemDef(id: "amulet_wrath", name: "Amulet of Wrath", icon: "item.amulet", kind: .accessory, rarity: .rare, description: "+10 Atk, -5 Def.", price: 220, stack: false, attack: 10, defense: -5)
    ]

    static let monsters = [
        MonsterDef(name: "Slime", icon: "monster.slime", hp: 7, attack: 3, defense: 0, xp: 6, behavior: "normal", isBoss: false),
        MonsterDef(name: "Goblin", icon: "monster.goblin", hp: 13, attack: 5, defense: 1, xp: 12, behavior: "flee", isBoss: false),
        MonsterDef(name: "Skeleton", icon: "monster.skeleton", hp: 22, attack: 9, defense: 3, xp: 24, behavior: "normal", isBoss: false),
        MonsterDef(name: "Orc", icon: "monster.orc", hp: 38, attack: 14, defense: 5, xp: 48, behavior: "normal", isBoss: false),
        MonsterDef(name: "Beholder", icon: "monster.beholder", hp: 54, attack: 20, defense: 4, xp: 95, behavior: "ranged", isBoss: false),
        MonsterDef(name: "Dragon", icon: "monster.dragon", hp: 130, attack: 34, defense: 16, xp: 460, behavior: "boss", isBoss: false)
    ]

    static let bosses = [
        MonsterDef(name: "Ogre Warden", icon: "monster.ogre", hp: 72, attack: 15, defense: 6, xp: 140, behavior: "boss", isBoss: true),
        MonsterDef(name: "Crystal Lich", icon: "monster.lich", hp: 112, attack: 23, defense: 8, xp: 240, behavior: "boss", isBoss: true),
        MonsterDef(name: "Ancient Dragon", icon: "monster.dragon", hp: 170, attack: 32, defense: 15, xp: 500, behavior: "boss", isBoss: true)
    ]

    static let shrines = [
        ShrineDef(id: "healing", name: "Mercy Shrine", icon: "tile.shrine.healing", description: "Spend 25 gold to restore 35 HP."),
        ShrineDef(id: "power", name: "Blood Shrine", icon: "tile.shrine.power", description: "Gain +2 Attack, lose 5 max HP.")
    ]
}

enum GameIcon {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(named rawName: String, size: CGFloat) -> UIImage {
        let name = normalized(rawName)
        let pixelSize = max(16, ceil(size))
        let cacheKey = "\(name)-\(Int(pixelSize))" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let image = draw(name: name, size: CGSize(width: pixelSize, height: pixelSize))
        cache.setObject(image, forKey: cacheKey)
        return image
    }

    private static func normalized(_ rawName: String) -> String {
        switch rawName {
        case "🧙", "@": return "hero.player"
        case "🪜", ">": return "tile.stairs"
        case "⛔️", "X": return "tile.stairs.locked"
        case "🛒", "$": return "tile.shop"
        case "⛩️", "✚", "+": return "tile.shrine.healing"
        case "⛧", "^": return "tile.shrine.power"
        case "🧪": return "item.potion.hp"
        case "⚗️", "H": return "item.potion.great"
        case "💣", "*": return "item.bomb"
        case "📜", "?": return "item.scroll"
        case "🔪", "/": return "item.dagger"
        case "⚔️", ")": return "item.sword"
        case "🔥", "F": return "item.fire_sword"
        case "✨", "V": return "item.vorpal"
        case "🥋", "[": return "item.robe"
        case "🧥", "]": return "item.vest"
        case "⛓️", "#": return "item.chainmail"
        case "🐉": return "monster.dragon"
        case "🍀": return "item.charm"
        case "💍": return "item.ring"
        case "📿", "A": return "item.amulet"
        case "🟢", "s": return "monster.slime"
        case "👺", "g": return "monster.goblin"
        case "💀", "k": return "monster.skeleton"
        case "🐗", "o": return "monster.orc"
        case "👁️", "e": return "monster.beholder"
        case "🛡️", "O": return "monster.ogre"
        case "🧙‍♂️", "L": return "monster.lich"
        case "D":
            return "monster.dragon"
        default:
            return rawName
        }
    }

    private static func draw(name: String, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let ctx = renderer.cgContext
            let side = min(size.width, size.height)
            let bounds = CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)

            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: bounds.minX + x * side, y: bounds.minY + y * side, width: w * side, height: h * side)
            }

            func fill(_ color: UIColor, _ path: UIBezierPath) {
                color.setFill()
                path.fill()
            }

            func stroke(_ color: UIColor, _ path: UIBezierPath, width: CGFloat = 0.07) {
                color.setStroke()
                path.lineWidth = max(1, side * width)
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }

            func fillEllipse(_ color: UIColor, _ frame: CGRect) {
                fill(color, UIBezierPath(ovalIn: frame))
            }

            func fillRect(_ color: UIColor, _ frame: CGRect, radius: CGFloat = 0.04) {
                fill(color, UIBezierPath(roundedRect: frame, cornerRadius: side * radius))
            }

            func line(_ color: UIColor, from: CGPoint, to: CGPoint, width: CGFloat = 0.08) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: bounds.minX + from.x * side, y: bounds.minY + from.y * side))
                path.addLine(to: CGPoint(x: bounds.minX + to.x * side, y: bounds.minY + to.y * side))
                stroke(color, path, width: width)
            }

            func text(_ value: String, color: UIColor = .white, scale: CGFloat = 0.55) {
                let font = UIFont.systemFont(ofSize: side * scale, weight: .black)
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let measured = (value as NSString).size(withAttributes: attributes)
                let origin = CGPoint(
                    x: bounds.midX - measured.width / 2,
                    y: bounds.midY - measured.height / 2
                )
                (value as NSString).draw(at: origin, withAttributes: attributes)
            }

            switch name {
            case "hero.player":
                fillEllipse(.systemCyan, rect(0.28, 0.12, 0.44, 0.44))
                fillRect(.systemBlue, rect(0.22, 0.48, 0.56, 0.36), radius: 0.12)
                fillEllipse(.white, rect(0.38, 0.28, 0.08, 0.08))
                fillEllipse(.white, rect(0.54, 0.28, 0.08, 0.08))
            case "tile.stairs":
                line(.systemYellow, from: CGPoint(x: 0.22, y: 0.78), to: CGPoint(x: 0.78, y: 0.22), width: 0.08)
                for step in [0.34, 0.48, 0.62] as [CGFloat] {
                    line(.systemYellow, from: CGPoint(x: step - 0.14, y: step), to: CGPoint(x: step + 0.14, y: step), width: 0.06)
                }
            case "tile.stairs.locked":
                fillRect(.systemRed, rect(0.22, 0.32, 0.56, 0.42), radius: 0.08)
                stroke(.systemRed, UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.minY + side * 0.36), radius: side * 0.18, startAngle: .pi, endAngle: 0, clockwise: true), width: 0.08)
            case "tile.shop":
                fillRect(.systemYellow, rect(0.18, 0.36, 0.64, 0.34), radius: 0.04)
                line(.systemYellow, from: CGPoint(x: 0.26, y: 0.34), to: CGPoint(x: 0.20, y: 0.20), width: 0.06)
                fillEllipse(.black, rect(0.28, 0.70, 0.12, 0.12))
                fillEllipse(.black, rect(0.62, 0.70, 0.12, 0.12))
            case "tile.shrine.healing":
                fillRect(.systemMint, rect(0.25, 0.25, 0.50, 0.58), radius: 0.08)
                fillRect(.white, rect(0.44, 0.34, 0.12, 0.34), radius: 0.02)
                fillRect(.white, rect(0.33, 0.45, 0.34, 0.12), radius: 0.02)
            case "tile.shrine.power":
                fillRect(.systemPurple, rect(0.24, 0.24, 0.52, 0.58), radius: 0.08)
                text("!", color: .white, scale: 0.62)
            case "item.potion.hp", "item.potion.great":
                let fillColor: UIColor = name == "item.potion.hp" ? .systemRed : .systemGreen
                fillRect(.lightGray, rect(0.39, 0.12, 0.22, 0.16), radius: 0.03)
                fillRect(fillColor, rect(0.28, 0.28, 0.44, 0.56), radius: 0.12)
                fillRect(.white.withAlphaComponent(0.7), rect(0.36, 0.36, 0.10, 0.28), radius: 0.03)
            case "item.bomb":
                fillEllipse(.darkGray, rect(0.22, 0.30, 0.56, 0.56))
                line(.systemOrange, from: CGPoint(x: 0.62, y: 0.28), to: CGPoint(x: 0.78, y: 0.14), width: 0.06)
                fillEllipse(.systemYellow, rect(0.72, 0.08, 0.14, 0.14))
            case "item.scroll":
                fillRect(UIColor(red: 0.86, green: 0.73, blue: 0.50, alpha: 1), rect(0.24, 0.22, 0.52, 0.58), radius: 0.08)
                line(.brown, from: CGPoint(x: 0.34, y: 0.42), to: CGPoint(x: 0.66, y: 0.42), width: 0.04)
                line(.brown, from: CGPoint(x: 0.34, y: 0.56), to: CGPoint(x: 0.62, y: 0.56), width: 0.04)
            case "item.dagger", "item.sword", "item.fire_sword", "item.vorpal":
                let bladeColor: UIColor = name == "item.fire_sword" ? .systemOrange : (name == "item.vorpal" ? .systemPurple : .lightGray)
                line(bladeColor, from: CGPoint(x: 0.30, y: 0.76), to: CGPoint(x: 0.72, y: 0.20), width: name == "item.dagger" ? 0.08 : 0.10)
                line(.brown, from: CGPoint(x: 0.22, y: 0.84), to: CGPoint(x: 0.38, y: 0.68), width: 0.10)
                if name == "item.fire_sword" { fillEllipse(.systemRed, rect(0.62, 0.16, 0.20, 0.20)) }
                if name == "item.vorpal" { text("*", color: .systemYellow, scale: 0.55) }
            case "item.robe", "item.vest", "item.chainmail", "item.dragonscale":
                let armorColor: UIColor
                switch name {
                case "item.vest": armorColor = .brown
                case "item.chainmail": armorColor = .lightGray
                case "item.dragonscale": armorColor = .systemGreen
                default: armorColor = .systemIndigo
                }
                fillRect(armorColor, rect(0.24, 0.22, 0.52, 0.62), radius: 0.08)
                fillRect(.black.withAlphaComponent(0.35), rect(0.44, 0.22, 0.12, 0.22), radius: 0.04)
                if name == "item.chainmail" { text("#", color: .darkGray, scale: 0.48) }
            case "item.charm":
                fillEllipse(.systemGreen, rect(0.28, 0.28, 0.44, 0.44))
                text("$", color: .white, scale: 0.44)
            case "item.ring":
                stroke(.systemYellow, UIBezierPath(ovalIn: rect(0.25, 0.25, 0.50, 0.50)), width: 0.12)
            case "item.amulet":
                stroke(.systemPurple, UIBezierPath(ovalIn: rect(0.30, 0.28, 0.40, 0.44)), width: 0.08)
                fillEllipse(.systemRed, rect(0.40, 0.46, 0.20, 0.20))
            case "monster.slime":
                fillEllipse(.systemGreen, rect(0.18, 0.34, 0.64, 0.42))
                fillEllipse(.white, rect(0.38, 0.44, 0.08, 0.08))
                fillEllipse(.white, rect(0.56, 0.44, 0.08, 0.08))
            case "monster.goblin", "monster.orc", "monster.ogre":
                let skin: UIColor = name == "monster.goblin" ? .systemGreen : UIColor(red: 0.43, green: 0.62, blue: 0.25, alpha: 1)
                fillEllipse(skin, rect(0.20, 0.20, 0.60, 0.60))
                fillEllipse(.white, rect(0.34, 0.40, 0.08, 0.08))
                fillEllipse(.white, rect(0.58, 0.40, 0.08, 0.08))
                if name == "monster.ogre" { text("!", color: .black, scale: 0.4) }
            case "monster.skeleton":
                fillEllipse(.white, rect(0.22, 0.18, 0.56, 0.56))
                fillEllipse(.black, rect(0.34, 0.38, 0.12, 0.12))
                fillEllipse(.black, rect(0.54, 0.38, 0.12, 0.12))
                fillRect(.white, rect(0.36, 0.68, 0.28, 0.16), radius: 0.03)
            case "monster.beholder":
                fillEllipse(.systemPurple, rect(0.18, 0.20, 0.64, 0.60))
                fillEllipse(.white, rect(0.32, 0.32, 0.36, 0.36))
                fillEllipse(.black, rect(0.44, 0.44, 0.12, 0.12))
            case "monster.dragon":
                fillRect(.systemRed, rect(0.20, 0.28, 0.60, 0.46), radius: 0.12)
                fillRect(.systemOrange, rect(0.58, 0.16, 0.18, 0.22), radius: 0.04)
                line(.systemYellow, from: CGPoint(x: 0.20, y: 0.34), to: CGPoint(x: 0.05, y: 0.18), width: 0.08)
            case "monster.lich":
                fillRect(.systemBlue, rect(0.24, 0.18, 0.52, 0.66), radius: 0.18)
                fillEllipse(.cyan, rect(0.38, 0.36, 0.08, 0.08))
                fillEllipse(.cyan, rect(0.54, 0.36, 0.08, 0.08))
            default:
                fillRect(.systemGray, rect(0.18, 0.18, 0.64, 0.64), radius: 0.08)
                text("?", color: .white, scale: 0.55)
            }
        }
    }
}
