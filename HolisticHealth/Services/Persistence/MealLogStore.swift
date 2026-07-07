import Foundation
import Combine

/// The daily food log. Stores `MealLogEntry` values (already scaled to the
/// logged amount) and computes daily macro totals. Protein is the headline
/// metric; calories are secondary only. There is no deficit/burn concept here
/// by design.
@MainActor
final class MealLogStore: ObservableObject {
    @Published private(set) var entries: [MealLogEntry] = []

    private let persistence: DataPersisting
    private let fileName: String

    init(persistence: DataPersisting = FileDataStore(), fileName: String = "meal_log.json") {
        self.persistence = persistence
        self.fileName = fileName
        entries = (try? persistence.load([MealLogEntry].self, from: fileName)) ?? []
    }

    func add(_ entry: MealLogEntry) {
        entries.append(entry)
        persist()
    }

    func remove(_ entry: MealLogEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    func clear() {
        entries.removeAll()
        persist()
    }

    /// Entries logged on the given day, newest first.
    func entries(on date: Date = Date(), calendar: Calendar = .current) -> [MealLogEntry] {
        entries
            .filter { calendar.isDate($0.loggedAt, inSameDayAs: date) }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    /// Summed macros for the given day.
    func dailyTotals(on date: Date = Date(), calendar: Calendar = .current) -> MacroNutrients {
        entries(on: date, calendar: calendar)
            .reduce(MacroNutrients.zero) { $0 + $1.macros }
    }

    private func persist() {
        try? persistence.save(entries, to: fileName)
    }
}
