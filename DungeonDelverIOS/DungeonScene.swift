import SpriteKit
import SwiftUI
import UIKit

final class DungeonScene: SKScene {
    private let viewDistance = 5.0
    private let mapPixelSize = CGSize(
        width: CGFloat(GameData.mapWidth) * GameData.tileSize,
        height: CGFloat(GameData.mapHeight) * GameData.tileSize
    )

    override init() {
        super.init(size: mapPixelSize)
        scaleMode = .resizeFill
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(player: PlayerState, dungeon: DungeonState) {
        removeAllChildren()

        let world = SKNode()
        addChild(world)

        renderTiles(player: player, dungeon: dungeon, in: world)
        renderItems(player: player, dungeon: dungeon, in: world)
        renderMonsters(player: player, dungeon: dungeon, in: world)
        addGlyph("hero.player", at: player.position, size: 30, in: world)

        focusCamera(on: player.position)
    }

    private func renderTiles(player: PlayerState, dungeon: DungeonState, in world: SKNode) {
        for y in 0..<GameData.mapHeight {
            for x in 0..<GameData.mapWidth {
                let point = Point(x: x, y: y)
                let distance = hypot(Double(x - player.position.x), Double(y - player.position.y))
                if distance < viewDistance {
                    addTile(dungeon.map[y][x], at: point, in: world)
                    addTileGlyph(dungeon.map[y][x], at: point, dungeon: dungeon, in: world)
                } else if dungeon.explored.contains(point) {
                    addTile(.floor, at: point, alpha: 0.35, in: world)
                }
            }
        }
    }

    private func renderItems(player: PlayerState, dungeon: DungeonState, in world: SKNode) {
        for item in dungeon.items where isVisible(item.position, player: player) {
            addGlyph(itemGlyph(item.itemID), at: item.position, size: 24, color: .systemOrange, in: world)
        }
    }

    private func renderMonsters(player: PlayerState, dungeon: DungeonState, in world: SKNode) {
        for monster in dungeon.monsters where isVisible(monster.position, player: player) {
            addGlyph(monsterGlyph(monster), at: monster.position, size: monster.isBoss ? 30 : 25, in: world)
            addHealthBar(monster, in: world)
        }
    }

    private func addTile(_ tile: Tile, at point: Point, alpha: CGFloat = 1, in world: SKNode) {
        let node = SKShapeNode(rectOf: CGSize(width: GameData.tileSize - 1, height: GameData.tileSize - 1))
        node.fillColor = color(for: tile).withAlphaComponent(alpha)
        node.strokeColor = .clear
        node.position = scenePosition(point)
        world.addChild(node)
    }

    private func addTileGlyph(_ tile: Tile, at point: Point, dungeon: DungeonState, in world: SKNode) {
        switch tile {
        case .stairs:
            addGlyph(dungeon.isBossFloor && !dungeon.bossDefeated ? "tile.stairs.locked" : "tile.stairs", at: point, size: 25, in: world)
        case .shop:
            addGlyph("tile.shop", at: point, size: 25, in: world)
        case .shrine:
            let shrineIcon = dungeon.shrines.first { $0.position == point }
                .flatMap { shrine in GameData.shrines.first { $0.id == shrine.type }?.icon }
            addGlyph(shrineIcon ?? "tile.shrine.healing", at: point, size: 25, in: world)
        default:
            break
        }
    }

    private func addGlyph(_ text: String, at point: Point, size: CGFloat, color: UIColor = .white, in world: SKNode) {
        let imageSize = CGSize(width: size * 1.45, height: size * 1.45)
        let image = GameIcon.image(named: text, size: max(imageSize.width, imageSize.height))
        let sprite = SKSpriteNode(texture: SKTexture(image: image))
        sprite.size = imageSize
        sprite.position = scenePosition(point)
        world.addChild(sprite)
    }

    private func monsterGlyph(_ monster: MonsterState) -> String {
        monster.icon
    }

    private func itemGlyph(_ itemID: String) -> String {
        GameData.items[itemID]?.icon ?? "?"
    }

    private func addHealthBar(_ monster: MonsterState, in world: SKNode) {
        let width: CGFloat = 30
        let origin = CGPoint(x: scenePosition(monster.position).x - width / 2, y: scenePosition(monster.position).y + 15)
        let background = SKShapeNode(rect: CGRect(x: origin.x, y: origin.y, width: width, height: 3))
        background.fillColor = .red
        background.strokeColor = .clear
        world.addChild(background)

        let ratio = max(0, CGFloat(monster.hp) / CGFloat(monster.maxHP))
        let fill = SKShapeNode(rect: CGRect(x: origin.x, y: origin.y, width: width * ratio, height: 3))
        fill.fillColor = .green
        fill.strokeColor = .clear
        world.addChild(fill)
    }

    private func focusCamera(on point: Point) {
        let cameraNode = SKCameraNode()
        cameraNode.position = clampedCameraPosition(for: scenePosition(point), scale: cameraScale)
        cameraNode.xScale = cameraScale
        cameraNode.yScale = cameraScale
        addChild(cameraNode)
        camera = cameraNode
    }

    private var cameraScale: CGFloat {
        let visibleTileHeight: CGFloat = 10.8
        let visibleTileWidth: CGFloat = 13.8
        let verticalScale = (visibleTileHeight * GameData.tileSize) / max(size.height, 1)
        let horizontalScale = (visibleTileWidth * GameData.tileSize) / max(size.width, 1)
        return max(0.45, min(max(verticalScale, horizontalScale), 0.92))
    }

    private func clampedCameraPosition(for target: CGPoint, scale: CGFloat) -> CGPoint {
        let halfWidth = size.width * scale / 2
        let halfHeight = size.height * scale / 2

        guard mapPixelSize.width > halfWidth * 2,
              mapPixelSize.height > halfHeight * 2 else {
            return CGPoint(x: mapPixelSize.width / 2, y: mapPixelSize.height / 2)
        }

        return CGPoint(
            x: min(max(target.x, halfWidth), mapPixelSize.width - halfWidth),
            y: min(max(target.y, halfHeight), mapPixelSize.height - halfHeight)
        )
    }

    private func scenePosition(_ point: Point) -> CGPoint {
        CGPoint(
            x: CGFloat(point.x) * GameData.tileSize + GameData.tileSize / 2,
            y: mapPixelSize.height - (CGFloat(point.y) * GameData.tileSize + GameData.tileSize / 2)
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

