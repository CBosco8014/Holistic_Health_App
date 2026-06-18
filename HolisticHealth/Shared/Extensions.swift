import SwiftUI

extension String {
    /// Returns nil if the string is empty or only whitespace.
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension Binding where Value == String {
    /// Bridges a `Binding<String?>` to a non-optional `Binding<String>` for
    /// text fields, substituting a fallback (usually "") for nil.
    init(_ source: Binding<String?>, replacingNilWith fallback: String) {
        self.init(
            get: { source.wrappedValue ?? fallback },
            set: { source.wrappedValue = $0 }
        )
    }
}
