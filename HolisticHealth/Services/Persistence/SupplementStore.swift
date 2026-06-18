import Foundation
import Combine

/// Stores tracked supplements and their daily adherence logs.
@MainActor
final class SupplementStore: ObservableObject {
    @Published private(set) var supplements: [Supplement] = []
    @Published private(set) var logs: [SupplementLogEntry] = []

    private let persistence: DataPersisting
    private let supplementsFile: String
    private let logsFile: String

    init(
        persistence: DataPersisting = FileDataStore(),
        supplementsFile: String = "supplements.json",
        logsFile: String = "supplement_logs.json"
    ) {
        self.persistence = persistence
        self.supplementsFile = supplementsFile
        self.logsFile = logsFile
        supplements = (try? persistence.load([Supplement].self, from: supplementsFile)) ?? []
        logs = (try? persistence.load([SupplementLogEntry].self, from: logsFile)) ?? []
    }

    var sorted: [Supplement] {
        supplements.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func save(_ supplement: Supplement) {
        var updated = supplement
        updated.updatedAt = Date()
        if let idx = supplements.firstIndex(where: { $0.id == supplement.id }) {
            supplements[idx] = updated
        } else {
            supplements.append(updated)
        }
        persistSupplements()
    }

    func delete(_ supplement: Supplement) {
        supplements.removeAll { $0.id == supplement.id }
        logs.removeAll { $0.supplementID == supplement.id }
        persistSupplements()
        persistLogs()
    }

    // MARK: - Adherence

    func isTakenToday(_ supplementID: UUID, calendar: Calendar = .current) -> Bool {
        logs.contains { $0.supplementID == supplementID && $0.taken && calendar.isDateInToday($0.date) }
    }

    /// Toggles today's adherence for a supplement.
    func setTakenToday(_ supplementID: UUID, taken: Bool, calendar: Calendar = .current) {
        logs.removeAll { $0.supplementID == supplementID && calendar.isDateInToday($0.date) }
        if taken {
            logs.append(SupplementLogEntry(supplementID: supplementID, taken: true))
        }
        persistLogs()
    }

    func clear() {
        supplements.removeAll()
        logs.removeAll()
        persistSupplements()
        persistLogs()
    }

    private func persistSupplements() { try? persistence.save(supplements, to: supplementsFile) }
    private func persistLogs() { try? persistence.save(logs, to: logsFile) }
}
