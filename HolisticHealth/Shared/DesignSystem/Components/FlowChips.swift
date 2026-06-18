import SwiftUI

/// A left-aligned wrapping layout (flow layout) for chips and tags.
struct WrapLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxRowWidth = max(maxRowWidth, x - spacing)
        }
        return CGSize(width: min(maxRowWidth, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// A wrapping group of selectable chips driven by closures, used for goals,
/// cycle phase, amounts, etc.
struct FlowChips<Item: Hashable>: View {
    let items: [Item]
    let isSelected: (Item) -> Bool
    let label: (Item) -> String
    var icon: (Item) -> String? = { _ in nil }
    let toggle: (Item) -> Void

    var body: some View {
        WrapLayout {
            ForEach(items, id: \.self) { item in
                Button {
                    toggle(item)
                } label: {
                    Chip(text: label(item), systemImage: icon(item), isSelected: isSelected(item))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
