import SpriteKit
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var game = GameViewModel()
    @State private var scene = DungeonScene()

    var body: some View {
        GeometryReader { proxy in
            let viewport = proxy.size
            let isPortraitViewport = viewport.height > viewport.width
            let surfaceSize = isPortraitViewport
                ? CGSize(width: viewport.height, height: viewport.width)
                : viewport
            let surfaceInsets = isPortraitViewport
                ? EdgeInsets()
                : proxy.safeAreaInsets

            ZStack {
                Color.black.ignoresSafeArea()
                if isPortraitViewport {
                    gameSurface(in: surfaceSize, safeAreaInsets: surfaceInsets)
                        .frame(width: surfaceSize.width, height: surfaceSize.height)
                        .rotationEffect(.degrees(90))
                        .position(x: viewport.width / 2, y: viewport.height / 2)
                } else {
                    gameSurface(in: surfaceSize, safeAreaInsets: surfaceInsets)
                        .frame(width: surfaceSize.width, height: surfaceSize.height)
                }
            }
            .frame(width: viewport.width, height: viewport.height)
        }
        .ignoresSafeArea()
        .font(.custom("Menlo", size: 12))
        .foregroundStyle(.white)
        .statusBarHidden(true)
        .onAppear { scene.render(player: game.player, dungeon: game.dungeon) }
        .onReceive(game.$player.combineLatest(game.$dungeon)) { player, dungeon in
            scene.render(player: player, dungeon: dungeon)
        }
    }

    private func gameSurface(in size: CGSize, safeAreaInsets: EdgeInsets) -> some View {
        let metrics = LayoutMetrics(size: size, safeAreaInsets: safeAreaInsets)

        return ZStack {
            landscapeGame(metrics: metrics)
                .frame(width: metrics.contentSize.width, height: metrics.contentSize.height)
                .padding(.leading, metrics.leadingInset)
                .padding(.trailing, metrics.trailingInset)
                .padding(.top, metrics.topInset)
                .padding(.bottom, metrics.bottomInset)

            if let overlay = game.overlay {
                overlayView(overlay, metrics: metrics)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func landscapeGame(metrics: LayoutMetrics) -> some View {
        HStack(spacing: metrics.columnGap) {
            leftSidebar(metrics: metrics)
                .frame(width: metrics.leftSidebarWidth)
            centerBoard(metrics: metrics)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            rightSidebar(metrics: metrics)
                .frame(width: metrics.rightSidebarWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func centerBoard(metrics: LayoutMetrics) -> some View {
        ZStack {
            Color.black

            SpriteView(scene: scene)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(metrics.centerMapPadding)
                .allowsHitTesting(false)

            VStack {
                runStrip(metrics: metrics)
                Spacer()
            }
            .padding(.top, metrics.centerInset)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    controls(metrics: metrics)
                }
            }
            .padding(metrics.centerInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: metrics.borderWidth))
        .clipped()
    }

    private func leftSidebar(metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.sidebarSpacing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: metrics.sidebarSpacing) {
                    sectionTitle("Hero Stats", fontSize: metrics.titleFontSize)
                    statRow("Level", "\(game.player.level)", fontSize: metrics.bodyFontSize)
                    xpBar(metrics: metrics)
                    statRow("HP", "\(game.player.hp)/\(game.player.maxHP)", fontSize: metrics.bodyFontSize)
                    hpBar(metrics: metrics)
                    statRow("Attack", "\(game.player.attack)", fontSize: metrics.bodyFontSize)
                    statRow("Defense", "\(game.player.defense)", fontSize: metrics.bodyFontSize)
                    statRow("Gold", "\(game.player.gold)", fontSize: metrics.bodyFontSize)

                    sectionTitle("Run", fontSize: metrics.titleFontSize)
                        .padding(.top, metrics.sectionTopPadding)
                    statRow("Floor", "\(game.dungeon.floor)", fontSize: metrics.bodyFontSize)
                    statRow("Time", format(game.elapsedSeconds), fontSize: metrics.bodyFontSize)
                    statRow("Best", bestText, fontSize: metrics.bodyFontSize)

                    sectionTitle("Equipment", fontSize: metrics.titleFontSize)
                        .padding(.top, metrics.sectionTopPadding)
                    equipmentSlot("Weapon", .weapon, game.player.equipment.weapon, metrics: metrics)
                    equipmentSlot("Armor", .armor, game.player.equipment.armor, metrics: metrics)
                    equipmentSlot("Accessory", .accessory, game.player.equipment.accessory, metrics: metrics)
                }
            }

            Spacer(minLength: 0)
            Button("Help") { game.overlay = .help }
                .buttonStyle(RetroButtonStyle(compact: true, fontSize: metrics.buttonFontSize))
        }
        .panelStyle(metrics: metrics)
    }

    private func rightSidebar(metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.sidebarSpacing) {
            sectionTitle("Inventory", fontSize: metrics.titleFontSize)
            inventoryGrid(metrics: metrics)
                .frame(height: metrics.inventoryGridHeight)

            sectionTitle("Log", fontSize: metrics.titleFontSize)
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: metrics.logSpacing) {
                        ForEach(Array(game.messages.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .font(.custom("Menlo", size: metrics.logFontSize))
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
        .panelStyle(metrics: metrics)
    }

    private func runStrip(metrics: LayoutMetrics) -> some View {
        HStack(spacing: metrics.runStripSpacing) {
            Text("Floor \(game.dungeon.floor)")
            if game.dungeon.isBossFloor && !game.dungeon.bossDefeated {
                Text("Boss floor").foregroundStyle(.red).bold()
            }
            Text(format(game.elapsedSeconds))
            Text("Best \(bestText)")
        }
        .font(.custom("Menlo-Bold", size: metrics.runStripFontSize))
        .lineLimit(1)
        .minimumScaleFactor(0.65)
        .padding(.horizontal, metrics.runStripHorizontalPadding)
        .padding(.vertical, metrics.runStripVerticalPadding)
        .background(Color.panel.opacity(0.88))
        .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: 1))
        .fixedSize(horizontal: false, vertical: true)
    }

    private func controls(metrics: LayoutMetrics) -> some View {
        Grid(horizontalSpacing: metrics.controlSpacing, verticalSpacing: metrics.controlSpacing) {
            GridRow {
                Color.clear.frame(width: metrics.controlSize, height: metrics.controlSize)
                movementButton(systemName: "arrow.up", direction: .up, metrics: metrics)
                Color.clear.frame(width: metrics.controlSize, height: metrics.controlSize)
            }
            GridRow {
                movementButton(systemName: "arrow.left", direction: .left, metrics: metrics)
                movementButton(systemName: "arrow.down", direction: .down, metrics: metrics)
                movementButton(systemName: "arrow.right", direction: .right, metrics: metrics)
            }
        }
        .padding(metrics.controlPadding)
        .background(Color.black.opacity(0.46))
        .overlay(Rectangle().stroke(Color.panelBorder.opacity(0.75), lineWidth: 1))
    }

    private func movementButton(systemName: String, direction: Direction, metrics: LayoutMetrics) -> some View {
        Button {
            game.move(direction)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: max(18, metrics.controlSize * 0.42), weight: .bold))
                .frame(width: metrics.controlSize, height: metrics.controlSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(ControlButtonStyle(size: metrics.controlSize))
        .contentShape(Rectangle())
        .accessibilityLabel(direction.accessibilityLabel)
    }

    private func hpBar(metrics: LayoutMetrics) -> some View {
        bar(value: Double(game.player.hp), max: Double(game.player.maxHP), color: hpColor, height: metrics.barHeight)
    }

    private func xpBar(metrics: LayoutMetrics) -> some View {
        bar(value: Double(game.player.xp), max: Double(game.player.nextXP), color: .red, height: metrics.smallBarHeight)
    }

    private var hpColor: Color {
        let ratio = Double(game.player.hp) / Double(max(1, game.player.maxHP))
        if ratio < 0.3 { return .red }
        if ratio < 0.6 { return .yellow }
        return .green
    }

    private func bar(value: Double, max: Double, color: Color, height: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.black.opacity(0.75))
                Rectangle()
                    .fill(color)
                    .frame(width: proxy.size.width * CGFloat(min(1, value / Swift.max(max, 1))))
            }
            .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: 1))
        }
        .frame(height: height)
    }

    private func inventoryGrid(metrics: LayoutMetrics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(metrics.inventoryCellSize), spacing: metrics.inventoryGridSpacing), count: 4), spacing: metrics.inventoryGridSpacing) {
            ForEach(0..<16, id: \.self) { index in
                inventoryCell(index, size: metrics.inventoryCellSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func inventoryCell(_ index: Int, size: CGFloat) -> some View {
        Button {
            game.useInventory(at: index)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color.slot)
                    .overlay(Rectangle().stroke(inventoryBorder(index), lineWidth: 1.5))
                if game.player.inventory.indices.contains(index), let item = GameData.items[game.player.inventory[index].id] {
                    Image(uiImage: GameIcon.image(named: item.icon, size: min(28, size * 0.68)))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: size * 0.72, height: size * 0.72)
                    if game.player.inventory[index].count > 1 {
                        Text("\(game.player.inventory[index].count)")
                            .font(.custom("Menlo-Bold", size: min(9, size * 0.24)))
                            .padding(2)
                    }
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .disabled(!game.player.inventory.indices.contains(index))
    }

    private func inventoryBorder(_ index: Int) -> Color {
        guard game.player.inventory.indices.contains(index),
              let item = GameData.items[game.player.inventory[index].id] else { return Color.panelBorder }
        return item.rarity.color
    }

    private func sectionTitle(_ title: String, fontSize: CGFloat) -> some View {
        Text(title.uppercased())
            .font(.custom("Menlo-Bold", size: fontSize))
            .foregroundStyle(Color.gold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 3)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.panelBorder).frame(height: 1) }
    }

    private func statRow(_ label: String, _ value: String, fontSize: CGFloat) -> some View {
        HStack {
            Text("\(label):")
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
        }
        .font(.custom("Menlo", size: fontSize))
        .lineLimit(1)
        .minimumScaleFactor(0.68)
    }

    private func equipmentSlot(_ label: String, _ kind: ItemKind, _ itemID: String?, metrics: LayoutMetrics) -> some View {
        Button {
            game.unequip(kind)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom("Menlo", size: metrics.captionFontSize))
                    .foregroundStyle(.gray)
                Text(itemID.flatMap { GameData.items[$0]?.name } ?? "None")
                    .font(.custom("Menlo-Bold", size: metrics.bodyFontSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(itemID.flatMap { GameData.items[$0]?.rarity.color } ?? .gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: metrics.equipmentSlotHeight, alignment: .center)
            .padding(.horizontal, metrics.equipmentHorizontalPadding)
            .background(Color.slot)
            .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func overlayView(_ overlay: Overlay, metrics: LayoutMetrics) -> some View {
        ZStack {
            Color.black.opacity(0.86).ignoresSafeArea()
            switch overlay {
            case .title: titleOverlay(metrics: metrics)
            case .confirmNewRun: confirmOverlay(metrics: metrics)
            case .shop: shopOverlay(metrics: metrics)
            case .levelUp: levelOverlay(metrics: metrics)
            case .death: deathOverlay(metrics: metrics)
            case .help: helpOverlay(metrics: metrics)
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
    }

    private func titleOverlay(metrics: LayoutMetrics) -> some View {
        dialog(maxWidth: 520, metrics: metrics) {
            Text("DUNGEON DELVER")
                .font(.custom("Menlo-Bold", size: metrics.titleOverlayFontSize))
                .foregroundStyle(Color.gold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("MERCHANT'S CURSE")
                .font(.custom("Menlo-Bold", size: metrics.dialogBodyFontSize))
                .foregroundStyle(Color.panelBorder)
            Text("Explore the depths, slay monsters, and loot treasures. Beware the Merchant: his greed grows with every purchase.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
                .font(.custom("Menlo", size: metrics.dialogBodyFontSize))
                .lineLimit(3)
                .minimumScaleFactor(0.75)
            HStack(spacing: metrics.dialogButtonSpacing) {
                Button("New Run") { game.requestNewRun() }
                    .buttonStyle(RetroButtonStyle(fontSize: metrics.dialogButtonFontSize))
                if game.canContinue {
                    Button("Continue") { game.continueRun() }
                        .buttonStyle(RetroButtonStyle(fontSize: metrics.dialogButtonFontSize))
                }
            }
        }
    }

    private func confirmOverlay(metrics: LayoutMetrics) -> some View {
        dialog(metrics: metrics) {
            Text("Replace Saved Run?")
                .font(.custom("Menlo-Bold", size: metrics.dialogHeaderFontSize))
                .foregroundStyle(Color.gold)
            Text("Starting a new run replaces the active save. Your best run remains.")
                .multilineTextAlignment(.center)
                .font(.custom("Menlo", size: metrics.dialogBodyFontSize))
            HStack(spacing: metrics.dialogButtonSpacing) {
                Button("Start New Run") { game.startNewRun(clearSave: true) }
                    .buttonStyle(RetroButtonStyle(fontSize: metrics.dialogButtonFontSize))
                Button("Cancel") { game.overlay = .title }
                    .buttonStyle(RetroButtonStyle(fontSize: metrics.dialogButtonFontSize))
            }
        }
    }

    private func shopOverlay(metrics: LayoutMetrics) -> some View {
        dialog(maxWidth: 640, metrics: metrics) {
            Text("The Greed-Witch")
                .font(.custom("Menlo-Bold", size: metrics.dialogHeaderFontSize))
                .foregroundStyle(Color.gold)
            Text("\"Take a look, hero... if you can afford it.\"")
                .font(.custom("Menlo", size: metrics.dialogBodyFontSize))
                .italic()
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
            .frame(maxHeight: metrics.shopListMaxHeight)
            HStack(spacing: metrics.dialogButtonSpacing) {
                Text("Gold \(game.player.gold)")
                Spacer()
                Text("Curse \(game.shopGreed, specifier: "%.2f")x")
                Button("Exit") { game.closeShop() }
                    .buttonStyle(RetroButtonStyle(compact: true, fontSize: metrics.dialogButtonFontSize))
            }
            .font(.custom("Menlo", size: metrics.dialogBodyFontSize))
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
                Image(uiImage: GameIcon.image(named: item?.icon ?? "unknown", size: 22))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(item?.name ?? id)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text("\(price)g").foregroundStyle(Color.gold)
            }
        }
        .buttonStyle(RetroButtonStyle(compact: true))
    }

    private func levelOverlay(metrics: LayoutMetrics) -> some View {
        dialog(metrics: metrics) {
            Text("Level Up!")
                .font(.custom("Menlo-Bold", size: metrics.dialogHeaderFontSize))
                .foregroundStyle(Color.gold)
            HStack(spacing: metrics.dialogButtonSpacing) {
                ForEach(LevelStat.allCases) { stat in
                    Button(stat.title) { game.applyLevelUp(stat) }
                        .buttonStyle(RetroButtonStyle(fontSize: metrics.dialogButtonFontSize))
                }
            }
        }
    }

    private func deathOverlay(metrics: LayoutMetrics) -> some View {
        dialog(metrics: metrics) {
            Text("You Perished")
                .font(.custom("Menlo-Bold", size: metrics.dialogHeaderFontSize))
                .foregroundStyle(.red)
            if let summary = game.deathSummary {
                Text("Floor Reached: \(summary.floorReached)")
                Text("Elapsed: \(format(summary.elapsedSeconds))")
                Text("Monsters Defeated: \(summary.monstersDefeated)")
                Text("Gold Collected: \(summary.goldCollected)")
            }
            Text(game.deathWasNewBest ? "New Best Run!" : "Best Run: \(bestText)")
                .foregroundStyle(Color.gold)
            Button("New Run") { game.requestNewRun() }
                .buttonStyle(RetroButtonStyle(fontSize: metrics.dialogButtonFontSize))
        }
    }

    private func helpOverlay(metrics: LayoutMetrics) -> some View {
        dialog(metrics: metrics) {
            Text("Controls")
                .font(.custom("Menlo-Bold", size: metrics.dialogHeaderFontSize))
                .foregroundStyle(Color.gold)
            Text("Use the directional buttons to move and attack.")
            Text("Tap inventory slots to use or equip items. Tap equipped gear to unequip.")
            Text("Map uses sprite icons for the hero, monsters, loot, stairs, shop, and shrines.")
                .multilineTextAlignment(.center)
            Button("Close") { game.closeHelp() }
                .buttonStyle(RetroButtonStyle(fontSize: metrics.dialogButtonFontSize))
        }
    }

    private func dialog<Content: View>(maxWidth: CGFloat = 430, metrics: LayoutMetrics, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12, content: content)
            .font(.custom("Menlo", size: metrics.dialogBodyFontSize))
            .padding(metrics.dialogPadding)
            .frame(maxWidth: min(maxWidth, metrics.dialogMaxWidth))
            .background(Color.panel.opacity(0.97))
            .overlay(Rectangle().stroke(Color.gold, lineWidth: metrics.borderWidth))
            .padding(.horizontal, metrics.dialogHorizontalMargin)
            .padding(.vertical, metrics.dialogVerticalMargin)
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
    var fontSize: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Menlo-Bold", size: fontSize ?? (compact ? 11 : 13)))
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 9 : 12)
            .padding(.vertical, compact ? 7 : 9)
            .background(configuration.isPressed ? Color.highlight : Color.panelBorder)
            .overlay(Rectangle().stroke(Color.gold, lineWidth: 1.5))
    }
}

private struct LayoutMetrics {
    let size: CGSize
    let contentSize: CGSize
    let leadingInset: CGFloat
    let trailingInset: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat
    let columnGap: CGFloat
    let leftSidebarWidth: CGFloat
    let rightSidebarWidth: CGFloat
    let borderWidth: CGFloat
    let panelPadding: CGFloat
    let sidebarSpacing: CGFloat
    let sectionTopPadding: CGFloat
    let titleFontSize: CGFloat
    let bodyFontSize: CGFloat
    let captionFontSize: CGFloat
    let buttonFontSize: CGFloat
    let barHeight: CGFloat
    let smallBarHeight: CGFloat
    let equipmentSlotHeight: CGFloat
    let equipmentHorizontalPadding: CGFloat
    let inventoryGridSpacing: CGFloat
    let inventoryCellSize: CGFloat
    let inventoryGridHeight: CGFloat
    let logSpacing: CGFloat
    let logFontSize: CGFloat
    let centerInset: CGFloat
    let centerMapPadding: CGFloat
    let runStripSpacing: CGFloat
    let runStripFontSize: CGFloat
    let runStripHorizontalPadding: CGFloat
    let runStripVerticalPadding: CGFloat
    let controlSize: CGFloat
    let controlSpacing: CGFloat
    let controlPadding: CGFloat
    let dialogMaxWidth: CGFloat
    let dialogHorizontalMargin: CGFloat
    let dialogVerticalMargin: CGFloat
    let dialogPadding: CGFloat
    let dialogHeaderFontSize: CGFloat
    let dialogBodyFontSize: CGFloat
    let dialogButtonFontSize: CGFloat
    let dialogButtonSpacing: CGFloat
    let titleOverlayFontSize: CGFloat
    let shopListMaxHeight: CGFloat

    init(size: CGSize, safeAreaInsets: EdgeInsets) {
        self.size = size

        let horizontalCurveInset: CGFloat = size.width > size.height ? 22 : 14
        let verticalCurveInset: CGFloat = size.width > size.height ? 8 : 14
        leadingInset = max(safeAreaInsets.leading, horizontalCurveInset)
        trailingInset = max(safeAreaInsets.trailing, horizontalCurveInset)
        topInset = max(safeAreaInsets.top, verticalCurveInset)
        bottomInset = max(safeAreaInsets.bottom, verticalCurveInset)

        let contentWidth = max(1, size.width - leadingInset - trailingInset)
        let contentHeight = max(1, size.height - topInset - bottomInset)
        contentSize = CGSize(width: contentWidth, height: contentHeight)

        let compact = contentHeight < 410 || contentWidth < 820
        columnGap = compact ? 2 : 4
        borderWidth = compact ? 1.5 : 2
        panelPadding = compact ? 7 : 10
        sidebarSpacing = compact ? 4 : 7
        sectionTopPadding = compact ? 2 : 5
        titleFontSize = compact ? 10 : 12
        bodyFontSize = compact ? 10 : 12
        captionFontSize = compact ? 8 : 9
        buttonFontSize = compact ? 10 : 11
        barHeight = compact ? 8 : 11
        smallBarHeight = compact ? 6 : 8
        equipmentSlotHeight = compact ? 29 : 38
        equipmentHorizontalPadding = compact ? 6 : 8
        inventoryGridSpacing = compact ? 4 : 5
        logSpacing = compact ? 4 : 5
        logFontSize = compact ? 9 : 10
        centerInset = compact ? 7 : 12
        centerMapPadding = 0
        runStripSpacing = compact ? 9 : 14
        runStripFontSize = compact ? 10 : 12
        runStripHorizontalPadding = compact ? 9 : 12
        runStripVerticalPadding = compact ? 5 : 7
        controlSize = compact ? 40 : 52
        controlSpacing = compact ? 4 : 5
        controlPadding = compact ? 4 : 6

        var leftWidth = compact
            ? min(max(contentWidth * 0.20, 132), 164)
            : min(max(contentWidth * 0.18, 190), 260)
        var rightWidth = compact
            ? min(max(contentWidth * 0.24, 162), 198)
            : min(max(contentWidth * 0.23, 230), 320)
        let minimumCenterWidth = compact ? max(360, contentHeight * 1.15) : max(480, contentHeight * 1.25)
        let sideBudget = max(0, contentWidth - (columnGap * 2) - minimumCenterWidth)
        if leftWidth + rightWidth > sideBudget {
            let scale = sideBudget / max(1, leftWidth + rightWidth)
            leftWidth = max(compact ? 118 : 150, floor(leftWidth * scale))
            rightWidth = max(compact ? 138 : 170, floor(rightWidth * scale))
        }

        leftSidebarWidth = leftWidth
        rightSidebarWidth = rightWidth

        let gridAvailableWidth = max(1, rightWidth - (panelPadding * 2) - (inventoryGridSpacing * 3))
        inventoryCellSize = floor(gridAvailableWidth / 4)
        inventoryGridHeight = (inventoryCellSize * 4) + (inventoryGridSpacing * 3)

        dialogHorizontalMargin = leadingInset + trailingInset + 10
        dialogVerticalMargin = topInset + bottomInset + 8
        dialogMaxWidth = max(280, contentWidth * (compact ? 0.74 : 0.62))
        dialogPadding = compact ? 14 : 18
        dialogHeaderFontSize = compact ? 17 : 20
        dialogBodyFontSize = compact ? 11 : 13
        dialogButtonFontSize = compact ? 11 : 13
        dialogButtonSpacing = compact ? 8 : 12
        titleOverlayFontSize = compact ? 24 : 28
        shopListMaxHeight = max(110, min(190, contentHeight * 0.42))
    }
}

struct ControlButtonStyle: ButtonStyle {
    var size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .background(configuration.isPressed ? Color.highlight.opacity(0.9) : Color.panelBorder.opacity(0.72))
            .overlay(Rectangle().stroke(Color.gold, lineWidth: 1.5))
    }
}

private extension Direction {
    var accessibilityLabel: String {
        switch self {
        case .up: return "Move up"
        case .down: return "Move down"
        case .left: return "Move left"
        case .right: return "Move right"
        case .wait: return "Wait"
        }
    }
}

private extension View {
    func panelStyle(metrics: LayoutMetrics) -> some View {
        self
            .padding(metrics.panelPadding)
            .frame(maxHeight: .infinity)
            .background(Color.panel.opacity(0.96))
            .overlay(Rectangle().stroke(Color.panelBorder, lineWidth: metrics.borderWidth))
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0)
    static let panel = Color(red: 0.10, green: 0.04, blue: 0.14)
    static let panelBorder = Color(red: 0.29, green: 0.16, blue: 0.35)
    static let highlight = Color(red: 0.54, green: 0.29, blue: 0.95)
    static let slot = Color(red: 0.15, green: 0.07, blue: 0.20)
}
