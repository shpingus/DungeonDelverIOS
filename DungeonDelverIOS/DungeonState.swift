import Foundation

struct DungeonState: Codable, Hashable {
    var floor = 1
    var map = Array(repeating: Array(repeating: Tile.wall, count: GameData.mapWidth), count: GameData.mapHeight)
    var monsters: [MonsterState] = []
    var items: [GroundItem] = []
    var shrines: [ShrineState] = []
    var explored: Set<Point> = []
    var bossDefeated = true

    var isBossFloor: Bool { floor > 0 && floor.isMultiple(of: 5) }

    mutating func generate(player: inout PlayerState) {
        map = Array(repeating: Array(repeating: Tile.wall, count: GameData.mapWidth), count: GameData.mapHeight)
        monsters = []
        items = []
        shrines = []
        explored = []
        bossDefeated = !isBossFloor

        var rooms = generateRooms()
        if rooms.isEmpty {
            rooms = [Room(x: 1, y: 1, width: 3, height: 3)]
            carve(rooms[0])
        }
        connect(rooms)

        player.position = rooms[0].center
        map[rooms.last!.center.y][rooms.last!.center.x] = .stairs
        placeShop(in: rooms)
        placeShrine(in: rooms)
        populate(rooms: rooms)
        if isBossFloor {
            placeBoss(in: rooms.last!)
        }
    }

    mutating func generateRooms() -> [Room] {
        var rooms: [Room] = []
        for _ in 0..<8 {
            let width = Int.random(in: 3...6)
            let height = Int.random(in: 3...5)
            let x = Int.random(in: 1..<(GameData.mapWidth - width - 1))
            let y = Int.random(in: 1..<(GameData.mapHeight - height - 1))
            let room = Room(x: x, y: y, width: width, height: height)
            guard !rooms.contains(where: { $0.overlaps(room) }) else { continue }
            rooms.append(room)
            carve(room)
        }
        return rooms
    }

    mutating func carve(_ room: Room) {
        for y in room.y..<(room.y + room.height) {
            for x in room.x..<(room.x + room.width) {
                map[y][x] = .floor
            }
        }
    }

    mutating func connect(_ rooms: [Room]) {
        guard rooms.count > 1 else { return }
        for index in 0..<(rooms.count - 1) {
            let a = rooms[index].center
            let b = rooms[index + 1].center
            for x in min(a.x, b.x)...max(a.x, b.x) { map[a.y][x] = .floor }
            for y in min(a.y, b.y)...max(a.y, b.y) { map[y][b.x] = .floor }
        }
    }

    mutating func placeShop(in rooms: [Room]) {
        guard floor.isMultiple(of: 2), rooms.count > 2 else { return }
        let room = rooms.dropFirst().dropLast().randomElement()!
        map[room.y][room.x] = .shop
    }

    mutating func placeShrine(in rooms: [Room]) {
        guard !isBossFloor, rooms.count > 2, Double.random(in: 0...1) <= 0.28 else { return }
        let room = rooms.dropFirst().dropLast().randomElement()!
        let point = Point(x: room.x + room.width - 1, y: room.y)
        guard tile(at: point) == .floor else { return }
        map[point.y][point.x] = .shrine
        shrines.append(ShrineState(position: point, type: GameData.shrines.randomElement()!.id))
    }

    mutating func populate(rooms: [Room]) {
        for (index, room) in rooms.enumerated() {
            guard index != 0 else { continue }
            if isBossFloor && index == rooms.count - 1 { continue }

            let count = Int.random(in: 1...(2 + floor / 3))
            for _ in 0..<count {
                let point = Point(x: Int.random(in: room.x..<(room.x + room.width)), y: Int.random(in: room.y..<(room.y + room.height)))
                guard isFloorOpen(point) else { continue }
                let maxIndex = min(GameData.monsters.count - 1, Int(Double(floor) / 2.0))
                let def = GameData.monsters[Int.random(in: 0...maxIndex)]
                let hp = def.hp + floor * 2
                monsters.append(MonsterState(name: def.name, icon: def.icon, position: point, hp: hp, maxHP: hp, attack: def.attack, defense: def.defense, xp: def.xp, behavior: def.behavior, isBoss: false))
            }

            if Double.random(in: 0...1) > 0.6 {
                let point = Point(x: Int.random(in: room.x..<(room.x + room.width)), y: Int.random(in: room.y..<(room.y + room.height)))
                guard isFloorOpen(point) else { continue }
                let pool = GameData.items.values.filter { $0.price <= floor * 100 || $0.price == 0 }
                if let drop = pool.randomElement() {
                    items.append(GroundItem(position: point, itemID: drop.id))
                }
            }
        }
    }

    mutating func placeBoss(in room: Room) {
        let template = GameData.bosses[min(GameData.bosses.count - 1, floor / 10)]
        let point = Point(x: room.center.x, y: max(room.y, room.center.y - 1))
        let hp = template.hp + floor * 8
        monsters.append(MonsterState(name: template.name, icon: template.icon, position: point, hp: hp, maxHP: hp, attack: template.attack + Int(Double(floor) * 1.5), defense: template.defense + floor / 3, xp: template.xp + floor * 20, behavior: template.behavior, isBoss: true))
    }

    func tile(at point: Point) -> Tile? {
        guard point.x >= 0, point.x < GameData.mapWidth, point.y >= 0, point.y < GameData.mapHeight else { return nil }
        return map[point.y][point.x]
    }

    func isWalkable(_ point: Point) -> Bool {
        guard let tile = tile(at: point) else { return false }
        return tile != .wall
    }

    func monsterIndex(at point: Point) -> Int? {
        monsters.firstIndex { $0.position == point }
    }

    func itemIndex(at point: Point) -> Int? {
        items.firstIndex { $0.position == point }
    }

    func shrineIndex(at point: Point) -> Int? {
        shrines.firstIndex { $0.position == point && !$0.used }
    }

    func isFloorOpen(_ point: Point) -> Bool {
        tile(at: point) == .floor && monsterIndex(at: point) == nil
    }

    func randomWalkableFloor() -> Point? {
        var candidates: [Point] = []
        for y in 0..<GameData.mapHeight {
            for x in 0..<GameData.mapWidth {
                let point = Point(x: x, y: y)
                if isFloorOpen(point) {
                    candidates.append(point)
                }
            }
        }
        return candidates.randomElement()
    }
}

struct Room: Hashable {
    var x: Int
    var y: Int
    var width: Int
    var height: Int

    var center: Point {
        Point(x: x + width / 2, y: y + height / 2)
    }

    func overlaps(_ other: Room) -> Bool {
        !(x + width < other.x || x > other.x + other.width || y + height < other.y || y > other.y + other.height)
    }
}
