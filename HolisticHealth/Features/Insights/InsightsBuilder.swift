import Foundation

/// One day's macro totals for charting.
struct DayMacro: Identifiable, Equatable {
    let date: Date
    let protein: Double
    let carb: Double
    let fat: Double
    var id: Date { date }
}

/// One day's value for a chosen health signal (nil when nothing was logged).
struct DaySignal: Identifiable, Equatable {
    let date: Date
    let value: Double?
    var id: Date { date }
}

/// Health signals that can be compared against macro patterns.
enum SignalKind: String, CaseIterable, Identifiable {
    case stress, acne, sleep, mood, exerciseMinutes, supplementsTaken
    var id: String { rawValue }
    var title: String {
        switch self {
        case .stress: return "Stress"
        case .acne: return "Skin"
        case .sleep: return "Sleep"
        case .mood: return "Mood"
        case .exerciseMinutes: return "Exercise (min)"
        case .supplementsTaken: return "Supplements taken"
        }
    }
}

/// Pure builders for visualization data — no UI, fully unit-testable. Charts
/// intentionally exclude any calorie-deficit, burn, weight-loss, or restriction
/// concepts.
enum InsightsBuilder {
    /// The last `count` days as start-of-day dates, oldest first.
    static func recentDays(count: Int = 7, now: Date, calendar: Calendar = .current) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<count).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    static func weeklyMacros(entries: [MealLogEntry], days: [Date], calendar: Calendar = .current) -> [DayMacro] {
        days.map { day in
            let todays = entries.filter { calendar.isDate($0.loggedAt, inSameDayAs: day) }
            let totals = todays.reduce(MacroNutrients.zero) { $0 + $1.macros }
            return DayMacro(date: day, protein: totals.proteinGrams, carb: totals.carbGrams, fat: totals.fatGrams)
        }
    }

    static func signalSeries(
        kind: SignalKind,
        days: [Date],
        checkIns: [HormoneSkinCheckIn],
        sessions: [ExerciseSession],
        supplementLogs: [SupplementLogEntry],
        calendar: Calendar = .current
    ) -> [DaySignal] {
        days.map { day in
            DaySignal(date: day, value: value(for: kind, on: day, checkIns: checkIns,
                                              sessions: sessions, supplementLogs: supplementLogs, calendar: calendar))
        }
    }

    private static func value(
        for kind: SignalKind, on day: Date,
        checkIns: [HormoneSkinCheckIn], sessions: [ExerciseSession],
        supplementLogs: [SupplementLogEntry], calendar: Calendar
    ) -> Double? {
        switch kind {
        case .stress, .acne, .sleep, .mood:
            let dayCheckIn = checkIns
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .sorted { $0.date > $1.date }
                .first
            guard let c = dayCheckIn else { return nil }
            switch kind {
            case .stress: return c.stress.map(Double.init)
            case .acne: return c.acneSeverity.map(Double.init)
            case .sleep: return c.sleepQuality.map(Double.init)
            case .mood: return c.mood.map(Double.init)
            default: return nil
            }
        case .exerciseMinutes:
            let minutes = sessions.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationMinutes }
            return minutes == 0 ? nil : Double(minutes)
        case .supplementsTaken:
            let count = supplementLogs.filter { $0.taken && calendar.isDate($0.date, inSameDayAs: day) }.count
            return count == 0 ? nil : Double(count)
        }
    }

    /// True if any macro data exists across the days (drives empty states).
    static func hasMacroData(_ macros: [DayMacro]) -> Bool {
        macros.contains { $0.protein > 0 || $0.carb > 0 || $0.fat > 0 }
    }

    static func hasSignalData(_ signals: [DaySignal]) -> Bool {
        signals.contains { $0.value != nil }
    }
}
