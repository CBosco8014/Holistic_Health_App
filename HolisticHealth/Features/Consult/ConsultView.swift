import SwiftUI

/// Adaptive consult. Fully implemented in US-018.
struct ConsultView: View {
    let aiConfig: AIConfigStore
    var body: some View {
        PlaceholderScreen(systemImage: "bubble.left.and.bubble.right",
                          title: "Adaptive Consult",
                          message: "A few guided, one-at-a-time wellness questions.",
                          eyebrow: "Insights")
        .navigationTitle("Consult")
        .navigationBarTitleDisplayMode(.inline)
    }
}
