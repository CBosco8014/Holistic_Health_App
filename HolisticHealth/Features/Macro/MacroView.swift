import SwiftUI

struct MacroView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "fork.knife",
            title: "Macro",
            message: "Protein-forward macro tracking — add foods, log meals, and review daily totals here."
        )
    }
}

#Preview {
    NavigationStack { MacroView() }
}
