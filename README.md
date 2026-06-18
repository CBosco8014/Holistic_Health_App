# Holistic Health App

Product planning and implementation workspace for a holistic women's health iPhone app centered on inside-out acne care, hormone health, protein-forward macro tracking, supplement tracking, lifestyle practices, exercise logging, Gemini-assisted analysis, and manual health assessments.

## Current PRD

- [Interactive HTML PRD](docs/prd/holistic-health-app-prd.html)
- [Ralph PRD JSON](prd.json)
- [Ralph Progress Log](progress.txt)

## Product Direction

- Native iPhone app written in Swift.
- Primary bottom tabs: Lifestyle, Supplements, Macro, and Exercise.
- Macro tracker, not a calorie tracker; protein, carbohydrates, and fat are primary, with calories only as secondary food data.
- Gemini-assisted typed food parsing, meal photo/upload macro analysis, acne flare review, Visualize Food, and manual health assessments.
- Confirmed foods and meals are saved to a reusable local JSON macro library with optional iCloud sync.
- Naturopathic and functional medicine-inspired guidance framed as wellness education, not diagnosis or treatment.
- Ristoro-inspired Italian Art Deco design direction: aged paper, midnight ink, antique gold, botanical verde, restrained rosso, framed cards, and calm wellness language.

## The App

A complete native SwiftUI MVP lives in `HolisticHealth/` (all 20 PRD user stories implemented). The Xcode project is generated with **XcodeGen** from `project.yml`.

### Build & run

```sh
brew install xcodegen          # one time
xcodegen generate              # regenerate HolisticHealth.xcodeproj after file/setting changes
xcodebuild build -project HolisticHealth.xcodeproj -scheme HolisticHealth \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -derivedDataPath build
xcodebuild test  -project HolisticHealth.xcodeproj -scheme HolisticHealth \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -derivedDataPath build
```

Open `HolisticHealth.xcodeproj` in Xcode to run in the simulator. To use AI features, add your own Gemini API key in **Settings → Gemini & Usage** (stored in the Keychain, never exported).

### Structure

- `HolisticHealth/App` — entry point + tab shell
- `HolisticHealth/Features/<area>` — Macro, Lifestyle, Supplements, Exercise, Onboarding, Settings, Consult, HealthLog, Insights
- `HolisticHealth/Services` — persistence (local JSON stores), Keychain, AI (Gemini service), data export
- `HolisticHealth/Shared/DesignSystem` — the Ristoro design system
- `HolisticHealthTests` — 93 unit tests
- `docs/verification-checklist.md` — story-by-story verification map

## Working Notes

The PRD is intended to stay readable and interactive in the browser. `prd.json` decomposes the PRD into Ralph-sized implementation stories (all now `passes: true`), and `progress.txt` is the Ralph execution log with a Codebase Patterns section at the top.
