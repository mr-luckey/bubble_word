# BubbleWord

Merge letter balls to form words — a Flutter casual word puzzle game.

## Features

- **Two-phase gameplay**: Merge letter fragments into words, then merge word-balls into a super-ball
- **1000 levels** loaded from `assets/data/levels.json`
- **Clean Architecture** with BLoC state management
- **3D bubble balls** with smooth animations
- **Boosters**: Hint, Magnet, Add Ball, Magic Wand, Extra Moves
- **Economy**: Coins, lives, shop (stub IAP), test AdMob ads

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
flutter analyze
```

## Architecture

```
lib/
├── core/          constants, theme, utils, widgets, router, di
├── data/          datasources, models, repositories
├── domain/        entities, repositories, usecases
└── presentation/  bloc, screens, widgets
```

## Level Data

Levels are in `assets/data/levels.json` (1000 levels). Move budget is computed at runtime based on difficulty.
