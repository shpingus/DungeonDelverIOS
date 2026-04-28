import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameViewModel()
    @State private var scene = DungeonScene()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                landscapeGame(in: proxy.size)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .padding(.leading, proxy.safeAreaInsets.leading)
                    .padding(.trailing, proxy.safeAreaInsets.trailing)
                    .padding(.top, proxy.safeAreaInsets.top)
                    .padding(.bottom, proxy.safeAreaInsets.bottom)

                if let overlay = game.overlay {
                    overlayView(overlay)
                }
            }
        }
        .font(.custom("Menlo", size: 12))
        .foregroundStyle(.white)
        .statusBarHidden(true)
        .onAppear { scene.render(player: game.player, dungeon: game.dungeon) }
        .onReceive(game.$player.combineLatest(game.$dungeon)) { player, dungeon in
            scene.render(player: player, dungeon: dungeon)
        }
    }

    private func landscapeGame(in size: CGSize) -> some View {
        HStack(spacing: 8) {
            leftSidebar
                .frame(width: sideWidth(for: size))
            centerBoard
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            rightSidebar
                .frame(width: sideWidth(for: size) + 20)
        }
    }

    private func sideWidth(for size: CGSize) -> CGFloat {
        min(max(size.width * 0.23, 190), 245)
    }

    private var centerBoard: some View {
        VStack(spacing: 8) {
            runStrip
            SpriteView(scene: scene)
                .aspectRatio(CGFloat(GameData.mapWidth) / CGFloat(GameData.mapHeight), contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: 2))
            controls
        }
        .frame(maxHeight: .infinity)
    }

    private var leftSidebar: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("Hero Stats")
            statRow("Level", "\(game.player.level)")
            hpBar
            statRow("HP", "\(game.player.hp)/\(game.player.maxHP)")
            xpBar
            statRow("Attack", "\(game.player.attack)")
            statRow("Defense", "\(game.player.defense)")
            statRow("Gold", "\(game.player.gold)")
            statRow("Floor", "\(game.dungeon.floor)")

            sectionTitle("Equipment").padding(.top, 6)
            equipmentSlot("Weapon", .weapon, game.player.equipment.weapon)
            equipmentSlot("Armor", .armor, game.player.equipment.armor)
            equipmentSlot("Accessory", .accessory, game.player.equipment.accessory)

            Spacer(minLength: 0)
            Button("Help") { game.overlay = .help }
                .buttonStyle(RetroButtonStyle(compact: true))
        }
        .panelStyle()
    }

    private var rightSidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Inventory")
            inventoryGrid
                .frame(maxHeight: 130)
            sectionTitle("Log")
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(game.messages.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .font(.custom("Menlo", size: 10))
                                .foregroundStyle(index == game.messages.count - 1 ? Color.white : Color.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                }
                .onChange(of: game.messages.count) { _, count in
                    if count > 0 { reader.scrollTo(count - 1, anchor: .bottom) }
                }
            }
            Spacer(minLength: 0)
        }
        .panelStyle()
    }

    private var runStrip: some View {
        HStack(spacing: 14) {
            Text("F\(game.dungeon.floor)")
            if game.dungeon.isBossFloor && !game.dungeon.bossDefeated {
                Text("BOSS").foregroundStyle(.red).bold()
            }
            Text(format(game.elapsedSeconds))
            Text("Best \(bestText)")
        }
        .font(.custom("Menlo-Bold", size: 14))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.panel.opacity(0.92))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gold, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button("◀") { game.move(.left) }.buttonStyle(ControlButtonStyle())
            Button("▲") { game.move(.up) }.buttonStyle(ControlButtonStyle())
            Button("•") { game.move(.wait) }.buttonStyle(ControlButtonStyle())
            Button("▼") { game.move(.down) }.buttonStyle(ControlButtonStyle())
            Button("▶") { game.move(.right) }.buttonStyle(ControlButtonStyle())
        }
        .padding(.bottom, 2)
    }

    private var hpBar: some View {
        bar(value: Double(game.player.hp), max: Double(game.player.maxHP), color: hpColor)
    }

    private var xpBar: some View {
        bar(value: Double(game.player.xp), max: Double(game.player.nextXP), color: .blue)
            .frame(height: 7)
    }

    private var hpColor: Color {
        let ratio = Double(game.player.hp) / Double(max(1, game.player.maxHP))
        if ratio < 0.3 { return .red }
        if ratio < 0.6 { return .yellow }
        return .green
    }

    private func bar(value: Double, max: Double, color: Color) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.black.opacity(0.75))
                Rectangle()
                    .fill(color)
                    .frame(width: proxy.size.width * CGFloat(min(1, value / Swift.max(max, 1))))
            }
            .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: 1))
        }
        .frame(height: 11)
    }

    private var inventoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 4), spacing: 5) {
            ForEach(0..<16, id: \.self) { index in
                inventoryCell(index)
            }
        }
    }

    private func inventoryCell(_ index: Int) -> some View {
        Button {
            game.useInventory(at: index)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color.slot)
                    .overlay(Rectangle().stroke(inventoryBorder(index), lineWidth: 1.5))
                if game.player.inventory.indices.contains(index), let item = GameData.items[game.player.inventory[index].id] {
                    Text(itemSymbol(item))
                        .font(.custom("Menlo-Bold", size: 18))
                        .foregroundStyle(item.rarity.color)
                    if game.player.inventory[index].count > 1 {
                        Text("\(game.player.inventory[index].count)")
                            .font(.custom("Menlo-Bold", size: 9))
                            .padding(2)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(!game.player.inventory.indices.contains(index))
    }

    private func inventoryBorder(_ index: Int) -> Color {
        guard game.player.inventory.indices.contains(index),
              let item = GameData.items[game.player.inventory[index].id] else { return Color.panelBorder }
        return item.rarity.color
    }

    private func itemSymbol(_ item: ItemDef) -> String {
        switch item.kind {
        case .consumable: return item.teleports ? "?" : "!"
        case .weapon: return "/"
        case .armor: return "]"
        case .accessory: return "="
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.custom("Menlo-Bold", size: 11))
            .foregroundStyle(Color.gold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 3)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.panelBorder).frame(height: 1) }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(label):")
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
        }
        .font(.custom("Menlo", size: 12))
    }

    private func equipmentSlot(_ label: String, _ kind: ItemKind, _ itemID: String?) -> some View {
        Button {
            game.unequip(kind)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.custom("Menlo", size: 9)).foregroundStyle(.gray)
                Text(itemID.flatMap { GameData.items[$0]?.name } ?? "None")
                    .font(.custom("Menlo-Bold", size: 11))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(itemID.flatMap { GameData.items[$0]?.rarity.color } ?? .gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(7)
            .background(Color.slot)
            .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func overlayView(_ overlay: Overlay) -> some View {
        ZStack {
            Color.black.opacity(0.86).ignoresSafeArea()
            switch overlay {
            case .title: titleOverlay
            case .confirmNewRun: confirmOverlay
            case .shop: shopOverlay
            case .levelUp: levelOverlay
            case .death: deathOverlay
            case .help: helpOverlay
            }
        }
    }

    private var titleOverlay: some View {
        dialog(maxWidth: 520) {
            Text("DUNGEON DELVER")
                .font(.custom("Menlo-Bold", size: 32))
                .foregroundStyle(Color.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("MERCHANT'S CURSE")
                .foregroundStyle(Color.panelBorder)
            Text("Explore the depths, slay monsters, and loot treasures. Beware the Merchant: his greed grows with every purchase.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
            HStack {
                Button("New Run") { game.requestNewRun() }.buttonStyle(RetroButtonStyle())
                if game.canContinue {
                    Button("Continue") { game.continueRun() }.buttonStyle(RetroButtonStyle())
                }
            }
        }
    }

    private var confirmOverlay: some View {
        dialog {
            Text("Replace Saved Run?").font(.headline)
            Text("Starting a new run replaces the active save. Your best run remains.")
                .multilineTextAlignment(.center)
            HStack {
                Button("Start New Run") { game.startNewRun(clearSave: true) }.buttonStyle(RetroButtonStyle())
                Button("Cancel") { game.overlay = .title }.buttonStyle(RetroButtonStyle())
            }
        }
    }

    private var shopOverlay: some View {
        dialog(maxWidth: 560) {
            Text("The Greed-Witch").font(.headline).foregroundStyle(Color.gold)
            Text("\"Take a look, hero... if you can afford it.\"").italic()
            Picker("Tab", selection: Binding(get: { game.shopTab }, set: { game.setShopTab($0) })) {
                Text("Buy").tag(ShopTab.buy)
                Text("Sell").tag(ShopTab.sell)
            }
            .pickerStyle(.segmented)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    if game.shopTab == .buy {
                        ForEach(game.shopStock, id: \.self) { id in shopRow(id: id, buy: true) }
                    } else {
                        ForEach(Array(game.player.inventory.enumerated()), id: \.offset) { index, slot in
                            shopRow(id: slot.id, buy: false, inventoryIndex: index)
                        }
                    }
                }
            }
            .frame(maxHeight: 180)
            HStack {
                Text("Gold \(game.player.gold)")
                Spacer()
                Text("Curse \(game.shopGreed, specifier: "%.2f")x")
                Button("Exit") { game.closeShop() }.buttonStyle(RetroButtonStyle(compact: true))
            }
        }
    }

    private func shopRow(id: String, buy: Bool, inventoryIndex: Int? = nil) -> some View {
        let item = GameData.items[id]
        let price = buy ? Int(Double(item?.price ?? 0) * game.shopGreed) : Int(Double(item?.price ?? 0) * 0.4)
        return Button {
            if buy {
                game.buy(id)
            } else if let inventoryIndex {
                game.sellInventory(at: inventoryIndex)
            }
        } label: {
            HStack {
                Text(item.map(itemSymbol) ?? "?")
                    .foregroundStyle(item?.rarity.color ?? .white)
                Text(item?.name ?? id)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text("\(price)g").foregroundStyle(Color.gold)
            }
        }
        .buttonStyle(RetroButtonStyle(compact: true))
    }

    private var levelOverlay: some View {
        dialog {
            Text("Level Up!").font(.headline)
            HStack {
                ForEach(LevelStat.allCases) { stat in
                    Button(stat.title) { game.applyLevelUp(stat) }.buttonStyle(RetroButtonStyle())
                }
            }
        }
    }

    private var deathOverlay: some View {
        dialog {
            Text("You Perished").font(.headline).foregroundStyle(.red)
            if let summary = game.deathSummary {
                Text("Floor Reached: \(summary.floorReached)")
                Text("Elapsed: \(format(summary.elapsedSeconds))")
                Text("Monsters Defeated: \(summary.monstersDefeated)")
                Text("Gold Collected: \(summary.goldCollected)")
            }
            Text(game.deathWasNewBest ? "New Best Run!" : "Best Run: \(bestText)")
                .foregroundStyle(Color.gold)
            Button("New Run") { game.requestNewRun() }.buttonStyle(RetroButtonStyle())
        }
    }

    private var helpOverlay: some View {
        dialog {
            Text("Controls").font(.headline)
            Text("Use the directional buttons to move and attack.")
            Text("Tap inventory slots to use or equip items. Tap equipped gear to unequip.")
            Text("Map: @ hero, letters monsters, ! potion/bomb, / weapon, ] armor, = accessory, > stairs, $ shop, + shrine.")
                .multilineTextAlignment(.center)
            Button("Close") { game.closeHelp() }.buttonStyle(RetroButtonStyle())
        }
    }

    private func dialog<Content: View>(maxWidth: CGFloat = 430, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12, content: content)
            .font(.custom("Menlo", size: 13))
            .padding(18)
            .frame(maxWidth: maxWidth)
            .background(Color.panel.opacity(0.97))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gold, lineWidth: 2))
            .padding()
    }

    private var bestText: String {
        guard let highScore = game.highScore else { return "None" }
        return "F\(highScore.floorReached) \(format(highScore.elapsedSeconds))"
    }

    private func format(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

struct RetroButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Menlo-Bold", size: compact ? 11 : 13))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 9 : 12)
            .padding(.vertical, compact ? 7 : 9)
            .background(configuration.isPressed ? Color.highlight : Color.panelBorder)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gold, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct ControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Menlo-Bold", size: 20))
            .foregroundStyle(.white)
            .frame(width: 46, height: 38)
            .background(configuration.isPressed ? Color.highlight.opacity(0.9) : Color.panelBorder.opacity(0.85))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gold, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private extension View {
    func panelStyle() -> some View {
        self
            .padding(9)
            .frame(maxHeight: .infinity)
            .background(Color.panel.opacity(0.96))
            .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: 2))
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0)
    static let panel = Color(red: 0.10, green: 0.04, blue: 0.14)
    static let panelBorder = Color(red: 0.29, green: 0.16, blue: 0.35)
    static let highlight = Color(red: 0.54, green: 0.29, blue: 0.95)
    static let slot = Color(red: 0.15, green: 0.07, blue: 0.20)
}
