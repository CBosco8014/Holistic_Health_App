# Holistic Health App — MVP Verification Checklist

Maps each PRD user story to where it's implemented and how it was verified.
Build/test: `xcodegen generate && xcodebuild test -scheme HolisticHealth -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1'`.

| Story | Requirement | Implementation | Verified by |
|-------|-------------|----------------|-------------|
| US-001 | 4-tab shell + Settings | `RootView`, `AppTab` | Build, 2 tests, simulator launch |
| US-002 | Ristoro design system | `Shared/DesignSystem/*` | Build, 2 tests, simulator render |
| US-003 | Domain models | `Models/*` | 9 Codable round-trip tests |
| US-004 | Local JSON storage + import/export | `MacroLibraryStore`, `FileDataStore` | 8 storage tests |
| US-005 | Onboarding + profile | `OnboardingView`, `ProfileStore` | 3 tests + sim persistence |
| US-006 | Gemini key / model / cost | `KeychainService`, `AIConfigStore`, `GeminiSettingsView` | 6 tests + sim |
| US-007 | Gemini AI service | `GeminiService`, `AIGuardrails` | 7 tests (incl. fallbacks) |
| US-008 | Macro tab module | `MacroView`, `MealLogStore` | 2 tests + sim |
| US-009 | Library-first typed logging | `LogMealViewModel` | 6 tests |
| US-010 | Saved search + portions | `AddFoodViewModel` | 4 tests + sim |
| US-011 | Meal photo capture | `MealPhotoViewModel`, `CameraPicker` | 5 tests + sim |
| US-012 | Visualize Food | `VisualizeFoodViewModel` | 6 tests + sim |
| US-013 | Hormone & skin check-in | `CheckInStore`, `CheckInView` | 4 tests + sim |
| US-014 | Supplements + guidance | `SupplementStore`, `NutrientGuidanceViewModel` | 7 tests + sim |
| US-015 | Lifestyle recommendations | `PracticeCatalog`, `LifestyleStore` | 5 tests + sim |
| US-016 | Exercise tab | `ExerciseStore`, `ExerciseView` | 3 tests + sim |
| US-017 | Acne flare consult | `AcneConsultViewModel` | 5 tests + sim (image never stored) |
| US-018 | Consult + assessment | `ConsultViewModel`, `HealthAssessmentViewModel` | 10 tests + sim |
| US-019 | Visualizations | `InsightsBuilder`, `InsightsView` | 5 tests + sim |
| US-020 | Privacy / export / deletion | `PrivacyView`, `DataExport`, `DataReset` | 3 tests + sim |

## Cross-cutting state coverage

- **Empty states**: Macro Food Log, Exercise sessions, Insights (macro + signal), library/search "no match" copy.
- **Loading states**: every Gemini call shows a progress indicator (Log Meal, Meal Photo, Visualize, Supplements, Acne, Consult, Assessment).
- **Error states**: `AIError` maps to calm messages with a manual fallback; surfaced via `SafetyNote`.
- **Offline**: network failures map to `AIError.transport` with a retry/manual message.
- **Permission-denied**: camera availability + authorization handled in `CameraPicker`/`CameraPermission`; denied shows guidance and an upload alternative.

## Wellness-safety guarantees

- All AI prompts pass through `AIGuardrails` (no diagnosis/treatment/medication/triage).
- Acne assessments store no image (`AcneAssessment` has no image field).
- Gemini API key lives only in the Keychain and is excluded from exports.
- Macro features exclude calorie deficit, burn rate, weight-loss, and restriction framing.

## Privacy controls

- Plain-language explanations of storage, iCloud, AI context, photos, export, deletion.
- Explicit consent toggles for all `ConsentType` values.
- JSON export (key excluded) via share sheet.
- Clear-library and delete-all-data flows behind explicit confirmation alerts.
