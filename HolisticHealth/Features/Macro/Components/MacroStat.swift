import SwiftUI

/// A single macro statistic (value + label), used in totals and rows. Protein
/// can be emphasized to keep it the headline metric.
struct MacroStat: View {
    let value: Double
    let label: String
    var emphasized: Bool = false
    var tint: Color = Theme.Colors.textPrimary

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(value.rounded()))")
                .font(emphasized ? Theme.Typography.display(30) : Theme.Typography.sansBold(18))
                .foregroundStyle(tint)
            Text(label)
                .font(Theme.Typography.poster(11))
                .tracking(1.5)
                .foregroundStyle(Theme.Colors.textFaint)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Formats grams/calories consistently.
enum MacroFormat {
    static func grams(_ value: Double) -> String { "\(Int(value.rounded())) g" }
    static func calories(_ value: Double) -> String { "\(Int(value.rounded())) cal" }
}
