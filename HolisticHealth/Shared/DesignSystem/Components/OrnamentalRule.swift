import SwiftUI

/// An ornamental divider — a gold hairline centered on a small diamond, a
/// classic Art Deco rule used between sections.
struct OrnamentalRule: View {
    var body: some View {
        HStack(spacing: 8) {
            line
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(Theme.Colors.accent)
            line
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private var line: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Theme.Colors.accent.opacity(0), Theme.Colors.accent.opacity(0.7)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        OrnamentalRule().padding()
    }
}
