import Foundation

/// Abstraction over reading/writing Codable values to named JSON files. Kept as
/// a protocol so stores can be unit-tested against a temp directory and so an
/// iCloud-backed implementation can be dropped in later.
protocol DataPersisting {
    func load<T: Decodable>(_ type: T.Type, from file: String) throws -> T?
    func save<T: Encodable>(_ value: T, to file: String) throws
    func delete(file: String) throws
    func fileURL(for file: String) -> URL
}

/// Where files live. `.local` uses the app's Documents directory. `.iCloud` is
/// the documented extension point for optional iCloud sync (US-004 leaves the
/// hook; wiring a ubiquity container is a later, opt-in step).
enum StorageLocation {
    case local
    case iCloud
}

/// Local filesystem implementation of `DataPersisting`.
final class FileDataStore: DataPersisting {
    private let baseDirectory: URL

    /// - Parameter baseDirectory: override for tests; defaults to Documents.
    init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            self.baseDirectory = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
        try? FileManager.default.createDirectory(at: self.baseDirectory, withIntermediateDirectories: true)
    }

    /// EXTENSION POINT for iCloud sync. A future implementation returns the
    /// ubiquity container URL when `location == .iCloud` and falls back to local
    /// when iCloud is unavailable. Today only `.local` is wired.
    static func directory(for location: StorageLocation) -> URL? {
        switch location {
        case .local:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        case .iCloud:
            // return FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            //     .appendingPathComponent("Documents")
            return nil // not yet enabled
        }
    }

    func fileURL(for file: String) -> URL {
        baseDirectory.appendingPathComponent(file)
    }

    func load<T: Decodable>(_ type: T.Type, from file: String) throws -> T? {
        let url = fileURL(for: file)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONCoding.decoder.decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, to file: String) throws {
        let data = try JSONCoding.encoder.encode(value)
        let url = fileURL(for: file)
        try data.write(to: url, options: [.atomic])
    }

    func delete(file: String) throws {
        let url = fileURL(for: file)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
