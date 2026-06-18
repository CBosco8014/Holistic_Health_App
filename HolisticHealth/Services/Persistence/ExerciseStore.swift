import Foundation
import Combine

/// Stores exercise sessions. Lightweight by design — no calorie-burn or deficit.
@MainActor
final class ExerciseStore: ObservableObject {
    @Published private(set) var sessions: [ExerciseSession] = []

    private let persistence: DataPersisting
    private let fileName: String

    init(persistence: DataPersisting = FileDataStore(), fileName: String = "exercise_sessions.json") {
        self.persistence = persistence
        self.fileName = fileName
        sessions = (try? persistence.load([ExerciseSession].self, from: fileName)) ?? []
    }

    func add(_ session: ExerciseSession) {
        sessions.append(session)
        persist()
    }

    func remove(_ session: ExerciseSession) {
        sessions.removeAll { $0.id == session.id }
        persist()
    }

    /// Sessions on a given day, newest first.
    func sessions(on date: Date = Date(), calendar: Calendar = .current) -> [ExerciseSession] {
        sessions
            .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func totalMinutes(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        sessions(on: date, calendar: calendar).reduce(0) { $0 + $1.durationMinutes }
    }

    func clear() {
        sessions.removeAll()
        persist()
    }

    private func persist() { try? persistence.save(sessions, to: fileName) }
}
