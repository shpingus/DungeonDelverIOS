# Dungeon Delver iOS

Native iPhone port of **Dungeon Delver: Merchant's Curse**.

The app is built with SwiftUI and SpriteKit. It is landscape-only and uses a retro dungeon layout: stats and equipment on the left, the dungeon map in the center, and inventory/log panels on the right.

## Features

- Procedural dungeon floors with fog of war.
- Turn-based movement and combat.
- Items, inventory, equipment, consumables, shop, shrines, and boss floors.
- Boss floors every 5 floors with locked stairs until the boss is defeated.
- Active run persistence and best-run high score persistence.
- Native iPhone full-screen landscape interface.

## Requirements

- Xcode 26.3 or newer.
- iOS 17.0+ target.
- XcodeGen installed.

## Build

```sh
xcodegen generate
xcodebuild -scheme DungeonDelverIOS -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/DungeonDelverIOSDerivedData build
```

## Test

```sh
xcodebuild test -scheme DungeonDelverIOS -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/DungeonDelverIOSDerivedData
```

## Project Layout

- `DungeonDelverIOS/` - app source.
- `DungeonDelverIOSTests/` - gameplay and persistence tests.
- `project.yml` - XcodeGen project definition.
