import SwiftUI

/// Macro & health visualizations. Fully implemented in US-019.
struct InsightsView: View {
    var body: some View {
        PlaceholderScreen(systemImage: "chart.bar",
                          title: "Visualizations",
                          message: "Protein, carb, and fat trends alongside your health signals.",
                          eyebrow: "Insights")
        .navigationTitle("Visualizations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
