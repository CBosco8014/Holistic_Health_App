import SwiftUI

struct SupplementsView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "pills",
            title: "Supplements",
            message: "Track supplements and review careful, non-diagnostic nutrient guidance here."
        )
    }
}

#Preview {
    NavigationStack { SupplementsView() }
}
