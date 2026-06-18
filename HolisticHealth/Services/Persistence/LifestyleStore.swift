import Foundation
import Combine

/// Stores lifestyle practice interactions (saved/started/completed/skipped +
/// ratings) for trend and assessment use.
@MainActor
final class LifestyleStore: ObservableObject {
    @Published private(set) var logs: [LifestylePracticeLog] = []

    private let persistence: DataPersisting
    private let fileName: String

    init(persistence: DataPersisting = FileDataStore(), fileName: String = "practice_logs.json") {
        self.persistence = persistence
        self.fileName = fileName
        logs = (try? persistence.load([LifestylePracticeLog].self, from: fileName)) ?? []
    }

    func record(_ practice: LifestylePractice, status: PracticeStatus, rating: Int? = nil) {
        logs.append(LifestylePracticeLog(
            practiceID: practice.id,
            practiceType: practice.type,
            status: status,
            rating: rating
        ))
        persist()
    }

    /// Most recent status for a practice type today, if any.
    func todaysStatus(for type: PracticeType, calendar: Calendar = .current) -> PracticeStatus? {
        logs
            .filter { $0.practiceType == type && calendar.isDateInToday($0.occurredAt) }
            .sorted { $0.occurredAt > $1.occurredAt }
            .first?.status
    }

    var completedCount: Int { logs.filter { $0.status == .completed }.count }

    func recent(_ count: Int) -> [LifestylePracticeLog] {
        logs.sorted { $0.occurredAt > $1.occurredAt }.prefix(count).map { $0 }
    }

    func clear() {
        logs.removeAll()
        persist()
    }

    private func persist() { try? persistence.save(logs, to: fileName) }
}
