# HolisticHealth app — developer notes

This is a native SwiftUI iPhone app generated with **XcodeGen**.

## Build / test / run
- `project.yml` is the source of truth. After adding/removing files or settings: `xcodegen generate`.
- Build: `xcodebuild build -project HolisticHealth.xcodeproj -scheme HolisticHealth -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1' -derivedDataPath build`
- Test: same with `test`. Always pin `OS=18.3.1` (bare device name is ambiguous).
- The generated `.xcodeproj` is gitignored — never edit it by hand; change `project.yml`.

## Layout
- `App/` — entry point + `RootView` (tab shell). `AppTab` enum order = bottom-bar order; Settings is a sheet, not a tab.
- `Features/<Feature>/` — one folder per feature area.
- `Shared/` — reusable views/components (design system lands here in US-002).
- `Resources/` — `Assets.xcassets`.

## Conventions
- iOS 17 deployment target, Swift 5 language mode.
- Bundle id `com.holistichealth.app`.
- Info.plist is generated; add keys via `INFOPLIST_KEY_*` in `project.yml`.
- Wellness-only product: copy must never diagnose/treat/cure. Keep this in all user-facing strings and AI prompts.
