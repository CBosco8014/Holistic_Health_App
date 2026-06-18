import SwiftUI

/// App entry point for the Holistic Health MVP.
///
/// The information architecture (set in US-001) is four primary bottom tabs —
/// Lifestyle, Supplements, Macro, Exercise — with Settings reachable from a
/// control outside the tab bar. Shared stores are created here and injected as
/// environment objects so every workflow can read profile/library context.
@main
struct HolisticHealthApp: App {
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var libraryStore = MacroLibraryStore()

    init() {
        ThemeAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(profileStore)
                .environmentObject(libraryStore)
                .tint(Theme.Colors.accentText)
        }
    }
}

/// Shows onboarding until it's completed, then the main tab shell.
struct AppRootView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    var body: some View {
        if profileStore.hasCompletedOnboarding {
            RootView()
        } else {
            OnboardingView()
        }
    }
}
