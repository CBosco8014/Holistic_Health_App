import SwiftUI

/// Manual health assessment. Fully implemented in US-018.
struct HealthAssessmentView: View {
    let aiConfig: AIConfigStore
    var body: some View {
        PlaceholderScreen(systemImage: "doc.text.magnifyingglass",
                          title: "Health Assessment",
                          message: "Summarize your recent patterns into a gentle wellness reflection.",
                          eyebrow: "Insights")
        .navigationTitle("Assessment")
        .navigationBarTitleDisplayMode(.inline)
    }
}
