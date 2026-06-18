import SwiftUI

struct LifestyleView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "leaf",
            title: "Lifestyle",
            message: "Calm, data-reactive practices for stress and nervous-system support will live here."
        )
    }
}

#Preview {
    NavigationStack { LifestyleView() }
}
