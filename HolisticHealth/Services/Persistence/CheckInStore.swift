import Foundation
import Combine

/// Stores hormone & skin check-ins. These logged signals are read by
/// visualizations (US-019), lifestyle (US-015), supplements (US-014), acne
/// review (US-017), consult and health assessment (US-018) workflows.
@MainActor
final class CheckInStore: ObservableObject {
    @Published private(set) var checkIns: [HormoneSkinCheckIn] = []

    private let persistence: DataPersisting
    private let fileName: String

    init(persistence: DataPersisting = FileDataStore(), fileName: String = "checkins.json") {
        self.persistence = persistence
        self.fileName = fileName
        checkIns = (try? persistence.load([HormoneSkinCheckIn].self, from: fileName)) ?? []
    }

    /// All check-ins, newest first.
    var sorted: [HormoneSkinCheckIn] {
        checkIns.sorted { $0.date > $1.date }
    }

    var latest: HormoneSkinCheckIn? { sorted.first }

    func recent(_ count: Int) -> [HormoneSkinCheckIn] {
        Array(sorted.prefix(count))
    }

    func todays(calendar: Calendar = .current) -> HormoneSkinCheckIn? {
        sorted.first { calendar.isDateInToday($0.date) }
    }

    /// Inserts or updates a check-in (matched by id).
    func save(_ checkIn: HormoneSkinCheckIn) {
        if let idx = checkIns.firstIndex(where: { $0.id == checkIn.id }) {
            checkIns[idx] = checkIn
        } else {
            checkIns.append(checkIn)
        }
        persist()
    }

    func delete(_ checkIn: HormoneSkinCheckIn) {
        checkIns.removeAll { $0.id == checkIn.id }
        persist()
    }

    func clear() {
        checkIns.removeAll()
        persist()
    }

    private func persist() {
        try? persistence.save(checkIns, to: fileName)
    }
}
