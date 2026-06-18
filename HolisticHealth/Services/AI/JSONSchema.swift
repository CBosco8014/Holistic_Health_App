import Foundation

/// Helpers for building Gemini `responseSchema` dictionaries (an OpenAPI subset
/// using UPPERCASE type names). Feature stories use these to force structured,
/// decodable JSON output.
enum JSONSchema {
    static let string: [String: Any] = ["type": "STRING"]
    static let number: [String: Any] = ["type": "NUMBER"]
    static let integer: [String: Any] = ["type": "INTEGER"]
    static let boolean: [String: Any] = ["type": "BOOLEAN"]

    static func array(of element: [String: Any]) -> [String: Any] {
        ["type": "ARRAY", "items": element]
    }

    static func object(properties: [String: [String: Any]], required: [String] = []) -> [String: Any] {
        var schema: [String: Any] = [
            "type": "OBJECT",
            "properties": properties
        ]
        if !required.isEmpty { schema["required"] = required }
        return schema
    }
}
