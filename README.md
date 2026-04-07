# CalorieFit

CalorieFit is a local-first Flutter calorie and nutrition tracking app.

## Features

- Daily food logging with meal categories (Breakfast, Morning Snack, Lunch, Afternoon Snack, Dinner, Post Dinner Snack)
- Named serving size presets per food (for example `1 egg` or `1 tbsp`) that can prefill logging amounts
- Online food search via USDA FoodData Central to auto-fill nutrition or log directly
- USDA search fallback to `DEMO_KEY` when no app-specific USDA key is bundled
- My Foods library with full nutrition editing
- Global food and meal template library (system-seeded)
- Meal template creation, editing, duplication, and import from system library
- Edit food amounts inside meal templates
- Macro and calorie progress bars with compact nutrient display
- Extra nutrient tracking for cholesterol, saturated fat, and trans fat
- Per-date and default macro targets with BMI / calorie tools
- History view with date picker
- Data retention setting with automatic cleanup
- Side menu with community features (upcoming)

## Tech Stack

- Flutter (Dart) with Material 3
- SQLite via `sqflite` / `sqflite_common_ffi`
- `shared_preferences` for settings
- `http` for USDA food search
- Local-first operation with no account required and optional internet use only for search

## Getting Started

```bash
flutter pub get
flutter run --dart-define-from-file=env/dart_defines.local.json
```

In VS Code, use the `CalorieFit` launch configuration so the USDA key is included automatically. If no USDA key is bundled, the app falls back to USDA `DEMO_KEY`, but a real key is still recommended for release reliability and rate limits.

Targets: Android, iOS, macOS, Linux, Windows, Web.

## Version

Current version: **1.1.1+4**
Database version: **17**
