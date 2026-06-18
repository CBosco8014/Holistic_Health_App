import SwiftUI
import Charts

/// Macro & health visualizations (US-019). Protein/carb/fat trends plus a chosen
/// health signal to compare against. No deficit, burn, weight-loss, or
/// restriction framing.
struct InsightsView: View {
    @EnvironmentObject private var mealLog: MealLogStore
    @EnvironmentObject private var checkIns: CheckInStore
    @EnvironmentObject private var exercise: ExerciseStore
    @EnvironmentObject private var supplements: SupplementStore

    @State private var signal: SignalKind = .stress

    private var days: [Date] { InsightsBuilder.recentDays(now: Date()) }
    private var macros: [DayMacro] { InsightsBuilder.weeklyMacros(entries: mealLog.entries, days: days) }
    private var signalSeries: [DaySignal] {
        InsightsBuilder.signalSeries(kind: signal, days: days, checkIns: checkIns.checkIns,
                                     sessions: exercise.sessions, supplementLogs: supplements.logs)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                macroSection
                signalSection
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Visualizations")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Macros

    private var macroSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "This week", title: "Macros")
            if InsightsBuilder.hasMacroData(macros) {
                FramedCard {
                    Chart {
                        ForEach(macros) { day in
                            BarMark(x: .value("Day", day.date, unit: .day),
                                    y: .value("Protein", day.protein))
                                .foregroundStyle(by: .value("Macro", "Protein"))
                            BarMark(x: .value("Day", day.date, unit: .day),
                                    y: .value("Carbs", day.carb))
                                .foregroundStyle(by: .value("Macro", "Carbs"))
                            BarMark(x: .value("Day", day.date, unit: .day),
                                    y: .value("Fat", day.fat))
                                .foregroundStyle(by: .value("Macro", "Fat"))
                        }
                    }
                    .chartForegroundStyleScale([
                        "Protein": Theme.Colors.accent,
                        "Carbs": Theme.Colors.success,
                        "Fat": Theme.Palette.ink2
                    ])
                    .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    } }
                    .frame(height: 200)
                }
                Text("Protein, carbohydrate, and fat over the last 7 days.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
            } else {
                emptyCard("Log a few meals to see your protein, carb, and fat trends here. Start with Log Meal on the Macro tab.")
            }
        }
    }

    // MARK: - Signal

    private var signalSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Compare", title: "Health Signal")
            Picker("Signal", selection: $signal) {
                ForEach(SignalKind.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.menu)
            .tint(Theme.Colors.accentText)

            if InsightsBuilder.hasSignalData(signalSeries) {
                FramedCard {
                    Chart {
                        ForEach(signalSeries.filter { $0.value != nil }) { point in
                            LineMark(x: .value("Day", point.date, unit: .day),
                                     y: .value(signal.title, point.value ?? 0))
                                .foregroundStyle(Theme.Colors.accent)
                            PointMark(x: .value("Day", point.date, unit: .day),
                                      y: .value(signal.title, point.value ?? 0))
                                .foregroundStyle(Theme.Colors.accentText)
                        }
                    }
                    .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    } }
                    .frame(height: 180)
                }
                Text("\(signal.title) over the last 7 days, to notice patterns alongside your macros.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
            } else {
                emptyCard("No \(signal.title.lowercased()) data this week yet. Add a check-in or log activity to see this trend — no pressure.")
            }
        }
    }

    private func emptyCard(_ message: String) -> some View {
        FramedCard {
            VStack(spacing: Theme.Spacing.s) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Theme.Colors.accentText)
                Text(message)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
