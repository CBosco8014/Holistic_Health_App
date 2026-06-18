import SwiftUI

/// Visualize a dish from a menu photo, screenshot, or text, then estimate macros.
/// Fully implemented in US-012.
struct VisualizeFoodView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "wand.and.stars",
            title: "Visualize Food",
            message: "Photograph a menu, upload a screenshot, or describe a dish to estimate its macros.",
            eyebrow: "Macro"
        )
        .navigationTitle("Visualize Food")
        .navigationBarTitleDisplayMode(.inline)
    }
}
