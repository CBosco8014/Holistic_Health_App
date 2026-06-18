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
    @StateObject private var aiConfig = AIConfigStore()

    init() {
        ThemeAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(profileStore)
                .environmentObject(libraryStore)
                .environmentObject(aiConfig)
                .tint(Theme.Colors.accentText)
        }
    }
}

/// Shows onboarding until it's completed, then the main tab shell.
struct AppRootView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    var body: some View {
        #if DEBUG
        if let screen = ProcessInfo.processInfo.environment["HH_SCREEN"] {
            DebugScreenRouter(screen: screen)
        } else {
            content
        }
        #else
        content
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if profileStore.hasCompletedOnboarding {
            RootView()
        } else {
            OnboardingView()
        }
    }
}

#if DEBUG
/// DEBUG-only router used to screenshot navigation-gated screens deterministically
/// during verification. Activated by launching with `SIMCTL_CHILD_HH_SCREEN=<name>`.
/// Has no effect in release builds.
struct DebugScreenRouter: View {
    let screen: String

    var body: some View {
        NavigationStack {
            switch screen {
            case "settings": SettingsView()
            case "gemini": GeminiSettingsView()
            case "profile": ProfileEditView()
            case "onboarding": OnboardingView()
            default: RootView()
            }
        }
    }
}
#endif
