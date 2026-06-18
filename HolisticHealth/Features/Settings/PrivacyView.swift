import SwiftUI

/// Privacy & data controls (US-020): plain-language explanations, explicit
/// consent toggles, data export, and data deletion.
struct PrivacyView: View {
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var library: MacroLibraryStore
    @EnvironmentObject private var mealLog: MealLogStore
    @EnvironmentObject private var checkIns: CheckInStore
    @EnvironmentObject private var supplements: SupplementStore
    @EnvironmentObject private var lifestyle: LifestyleStore
    @EnvironmentObject private var exercise: ExerciseStore
    @EnvironmentObject private var assessments: AssessmentStore
    @EnvironmentObject private var aiConfig: AIConfigStore

    @State private var exportURL: URL?
    @State private var showDeleteConfirm = false
    @State private var showClearLibraryConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                explanationSection
                consentSection
                exportSection
                deletionSection
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Explanations

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "How it works", title: "Your data")
            explain("internaldrive", "Local-first", "Your logs and food library are stored on your device.")
            explain("icloud", "Optional iCloud sync", "iCloud sync is off by default; you can opt in below (extension point for a future release).")
            explain("sparkles", "AI context", "Gemini features only use your logged patterns when you turn on the relevant consent.")
            explain("camera", "Photos", "Meal and acne photos are sent for analysis and are not stored by default.")
            explain("square.and.arrow.up", "Export", "You can export your personal data as JSON at any time. Your API key is never included.")
            explain("trash", "Deletion", "You can delete your data and clear your food library whenever you like.")
        }
    }

    private func explain(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Image(systemName: icon).foregroundStyle(Theme.Colors.accentText).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Typography.bodyMedium).foregroundStyle(Theme.Colors.textPrimary)
                Text(body).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Consent

    private var consentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Consent", title: "What you allow")
            ForEach(ConsentType.allCases) { type in
                Toggle(isOn: Binding(
                    get: { profile.isGranted(type) },
                    set: { profile.setConsent(type, granted: $0) }
                )) {
                    Text(type.title)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .tint(Theme.Colors.accent)
            }
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Export", title: "Take your data")
            Button("Prepare export file") {
                let bundle = DataExport.buildBundle(
                    profile: profile, library: library, mealLog: mealLog, checkIns: checkIns,
                    supplements: supplements, lifestyle: lifestyle, exercise: exercise,
                    assessments: assessments, aiConfig: aiConfig)
                exportURL = try? DataExport.writeFile(bundle)
            }
            .buttonStyle(.decoSecondary)

            if let exportURL {
                ShareLink(item: exportURL) {
                    Text("Share export").frame(maxWidth: .infinity)
                }
                .buttonStyle(.decoPrimary)
            }
        }
    }

    // MARK: - Deletion

    private var deletionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Delete", title: "Remove data")

            Button("Clear food library") { showClearLibraryConfirm = true }
                .buttonStyle(.decoSecondary)

            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Text("Delete all personal data").frame(maxWidth: .infinity)
            }
            .buttonStyle(.decoSecondary)

            Text("Deleting is permanent. Your Gemini API key is kept unless you clear it in Gemini & Usage.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textFaint)
        }
        .alert("Clear food library?", isPresented: $showClearLibraryConfirm) {
            Button("Clear", role: .destructive) { library.clear() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all saved foods. Logged meals are kept.")
        }
        .alert("Delete all personal data?", isPresented: $showDeleteConfirm) {
            Button("Delete everything", role: .destructive) {
                DataReset.deleteAll(
                    profile: profile, library: library, mealLog: mealLog, checkIns: checkIns,
                    supplements: supplements, lifestyle: lifestyle, exercise: exercise,
                    assessments: assessments, aiConfig: aiConfig)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes your profile, logs, library, and assessments. This cannot be undone.")
        }
    }
}
