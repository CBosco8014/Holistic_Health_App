import SwiftUI

/// App entry point for the Holistic Health MVP.
///
/// The information architecture (set in US-001) is four primary bottom tabs —
/// Lifestyle, Supplements, Macro, Exercise — with Settings reachable from a
/// control outside the tab bar. Later stories layer the Ristoro design system,
/// domain models, persistence, and feature behavior onto this shell.
@main
struct HolisticHealthApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
