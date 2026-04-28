import SpriteKit
import SwiftUI

final class DungeonScene: SKScene {
    private let viewDistance = 5.0

    override init() {
        super.init(size: CGSize(width: CGFloat(GameData.mapWidth) * GameData.tileSize, height: CGFloat(GameData.mapHeight) * GameData.tileSize))
        scaleMode = .aspectFit
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(player: PlayerState, dungeon: DungeonState) {
        removeAllChildren()
        renderTiles(player: player, dungeon: dungeon)
        renderItems(player: player, dungeon: dungeon)
        renderMonsters(player: player, dungeon: dungeon)
        addGlyph("@", at: player.position, size: 28, color: .systemYellow)
    }

    private func renderTiles(player: PlayerState, dungeon: DungeonState) {
        for y in 0..<GameData.mapHeight {
            for x in 0..<GameData.mapWidth {
                let point = Point(x: x, y: y)
                let distance = hypot(Double(x - player.position.x), Double(y - player.position.y))
                if distance < viewDistance {
                    addTile(dungeon.map[y][x], at: point)
                    addTileGlyph(dungeon.map[y][x], at: point, dungeon: dungeon)
                } else if dungeon.explored.contains(point) {
                    addTile(.floor, at: point, alpha: 0.35)
                }
            }
        }
    }

    private func renderItems(player: PlayerState, dungeon: DungeonState) {
        for item in dungeon.items where isVisible(item.position, player: player) {
            addGlyph(itemGlyph(item.itemID), at: item.position, size: 22, color: .systemOrange)
        }
    }

    private func renderMonsters(player: PlayerState, dungeon: DungeonState) {
        for monster in dungeon.monsters where isVisible(monster.position, player: player) {
            addGlyph(monsterGlyph(monster), at: monster.position, size: monster.isBoss ? 28 : 22, color: monster.isBoss ? .systemRed : .white)
            addHealthBar(monster)
        }
    }

    private func addTile(_ tile: Tile, at point: Point, alpha: CGFloat = 1) {
        let node = SKShapeNode(rectOf: CGSize(width: GameData.tileSize - 1, height: GameData.tileSize - 1))
        node.fillColor = color(for: tile).withAlphaComponent(alpha)
        node.strokeColor = .clear
        node.position = scenePosition(point)
        addChild(node)
    }

    private func addTileGlyph(_ tile: Tile, at point: Point, dungeon: DungeonState) {
        switch tile {
        case .stairs:
            addGlyph(dungeon.isBossFloor && !dungeon.bossDefeated ? "X" : ">", at: point, size: 22, color: .white)
        case .shop:
            addGlyph("$", at: point, size: 24, color: .systemYellow)
        case .shrine:
            addGlyph("+", at: point, size: 24, color: .white)
        default:
            break
        }
    }

    private func addGlyph(_ text: String, at point: Point, size: CGFloat, color: UIColor = .white) {
        let label = SKLabelNode(text: text)
        label.fontName = "Menlo-Bold"
        label.fontSize = size
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = scenePosition(point)
        addChild(label)
    }

    private func monsterGlyph(_ monster: MonsterState) -> String {
        if monster.isBoss { return "B" }
        return String(monster.name.prefix(1)).uppercased()
    }

    private func itemGlyph(_ itemID: String) -> String {
        guard let item = GameData.items[itemID] else { return "?" }
        switch item.kind {
        case .consumable: return item.teleports ? "?" : "!"
        case .weapon: return "/"
        case .armor: return "]"
        case .accessory: return "="
        }
    }

    private func addHealthBar(_ monster: MonsterState) {
        let width: CGFloat = 30
        let origin = CGPoint(x: scenePosition(monster.position).x - width / 2, y: scenePosition(monster.position).y + 15)
        let background = SKShapeNode(rect: CGRect(x: origin.x, y: origin.y, width: width, height: 3))
        background.fillColor = .red
        background.strokeColor = .clear
        addChild(background)

        let ratio = max(0, CGFloat(monster.hp) / CGFloat(monster.maxHP))
        let fill = SKShapeNode(rect: CGRect(x: origin.x, y: origin.y, width: width * ratio, height: 3))
        fill.fillColor = .green
        fill.strokeColor = .clear
        addChild(fill)
    }

    private func scenePosition(_ point: Point) -> CGPoint {
        CGPoint(
            x: CGFloat(point.x) * GameData.tileSize + GameData.tileSize / 2,
            y: size.height - (CGFloat(point.y) * GameData.tileSize + GameData.tileSize / 2)
        )
    }

    private func isVisible(_ point: Point, player: PlayerState) -> Bool {
        hypot(Double(point.x - player.position.x), Double(point.y - player.position.y)) < viewDistance
    }

    private func color(for tile: Tile) -> UIColor {
        switch tile {
        case .wall: return UIColor(red: 0.17, green: 0.12, blue: 0.22, alpha: 1)
        case .floor: return UIColor(red: 0.10, green: 0.04, blue: 0.14, alpha: 1)
        case .stairs: return UIColor(red: 0.20, green: 0.60, blue: 0.86, alpha: 1)
        case .shop: return UIColor(red: 0.63, green: 0.13, blue: 0.94, alpha: 1)
        case .shrine: return UIColor(red: 0.10, green: 0.74, blue: 0.61, alpha: 1)
        }
    }
}
