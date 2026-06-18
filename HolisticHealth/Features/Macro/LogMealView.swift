import SwiftUI

/// Typed meal logging with library-first lookup. Fully implemented in US-009.
struct LogMealView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "text.badge.plus",
            title: "Log Meal",
            message: "Type what you ate. We'll check your saved foods first, then optionally ask Gemini.",
            eyebrow: "Macro"
        )
        .navigationTitle("Log Meal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
