import Foundation

/// Minimal async HTTP abstraction so the Gemini service can be unit-tested with
/// a mock and never touches the network in tests.
protocol HTTPClient {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIError.transport("Non-HTTP response")
        }
        return (data, http)
    }
}
