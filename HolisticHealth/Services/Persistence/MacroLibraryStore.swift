import Foundation
import Combine

/// How an imported library is reconciled with the existing one.
enum ImportStrategy {
    case merge     // keep existing, add new, update matches
    case replace   // discard existing, use imported set
}

/// Result of an import for user feedback.
struct ImportResult: Equatable {
    var added: Int
    var updated: Int
    var total: Int
}

/// The local, JSON-backed macro library. This is the user's reusable food
/// database that grows over time. CRUD + search live here; the file IO is
/// delegated to `DataPersisting` so it is testable and iCloud-swappable.
@MainActor
final class MacroLibraryStore: ObservableObject {
    @Published private(set) var records: [MacroLibraryRecord] = []

    private let persistence: DataPersisting
    private let fileName: String

    init(persistence: DataPersisting = FileDataStore(), fileName: String = "macro_library.json") {
        self.persistence = persistence
        self.fileName = fileName
        load()
    }

    // MARK: - Loading / saving

    func load() {
        do {
            records = try persistence.load([MacroLibraryRecord].self, from: fileName) ?? []
        } catch {
            records = []
        }
    }

    private func persist() {
        try? persistence.save(records, to: fileName)
    }

    // MARK: - CRUD

    /// Inserts a new record or updates an existing one (matched by id).
    func upsert(_ record: MacroLibraryRecord) {
        var updated = record
        updated.updatedAt = Date()
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx] = updated
        } else {
            records.append(updated)
        }
        persist()
    }

    func update(_ record: MacroLibraryRecord) { upsert(record) }

    func delete(_ record: MacroLibraryRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        persist()
    }

    /// Removes all records (used by "clear library" in privacy settings).
    func clear() {
        records.removeAll()
        persist()
    }

    func record(withID id: UUID) -> MacroLibraryRecord? {
        records.first { $0.id == id }
    }

    // MARK: - Search

    /// Case-insensitive search over canonical name and aliases. Canonical-name
    /// matches rank ahead of alias matches; prefix matches ahead of contains.
    func search(_ query: String) -> [MacroLibraryRecord] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return records.sorted { $0.canonicalName < $1.canonicalName } }

        func score(_ r: MacroLibraryRecord) -> Int {
            let name = r.canonicalName.lowercased()
            if name == q { return 0 }
            if name.hasPrefix(q) { return 1 }
            if name.contains(q) { return 2 }
            if r.aliases.contains(where: { $0.lowercased() == q }) { return 3 }
            if r.aliases.contains(where: { $0.lowercased().hasPrefix(q) }) { return 4 }
            if r.aliases.contains(where: { $0.lowercased().contains(q) }) { return 5 }
            return Int.max
        }

        return records
            .map { ($0, score($0)) }
            .filter { $0.1 != Int.max }
            .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0.canonicalName < $1.0.canonicalName }
            .map { $0.0 }
    }

    /// Best single match for a typed food (used by library-first lookup, US-009).
    func bestMatch(for query: String) -> MacroLibraryRecord? {
        search(query).first
    }

    // MARK: - Import / Export

    func exportData() throws -> Data {
        try JSONCoding.encoder.encode(records)
    }

    /// Writes the library JSON to a temporary file and returns its URL for a
    /// share sheet.
    func exportToFile() throws -> URL {
        let data = try exportData()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("macro_library_export.json")
        try data.write(to: url, options: [.atomic])
        return url
    }

    @discardableResult
    func importLibrary(from data: Data, strategy: ImportStrategy) throws -> ImportResult {
        let imported = try JSONCoding.decoder.decode([MacroLibraryRecord].self, from: data)

        switch strategy {
        case .replace:
            records = imported
            persist()
            return ImportResult(added: imported.count, updated: 0, total: records.count)

        case .merge:
            var added = 0, updated = 0
            for incoming in imported {
                if let idx = index(matching: incoming) {
                    records[idx] = incoming
                    updated += 1
                } else {
                    records.append(incoming)
                    added += 1
                }
            }
            persist()
            return ImportResult(added: added, updated: updated, total: records.count)
        }
    }

    /// Matches an incoming record to an existing one by id, then by normalized
    /// canonical name (so re-imports don't create duplicates).
    private func index(matching incoming: MacroLibraryRecord) -> Int? {
        if let byID = records.firstIndex(where: { $0.id == incoming.id }) { return byID }
        let name = incoming.canonicalName.lowercased()
        return records.firstIndex { $0.canonicalName.lowercased() == name }
    }
}
