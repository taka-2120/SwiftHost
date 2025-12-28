/// A middleware that adds custom headers to all HTTP responses.
///
/// Useful for setting common headers like security headers, caching directives, or custom metadata.
public struct HeaderMiddleware: Middleware {
    private let headers: [String: String]

    /// Creates a new header middleware with the specified headers.
    ///
    /// - Parameter headers: Dictionary of header key-value pairs to add to responses
    public init(headers: [String: String]) {
        self.headers = headers
    }

    /// Adds the configured headers to the response.
    ///
    /// - Parameter response: The HTTP response to modify
    /// - Returns: The response with additional headers
    public func processResponse(_ response: HTTPResponse) async -> HTTPResponse {
        var newResponse = response
        for (key, value) in headers {
            newResponse.headers[key] = value
        }
        return newResponse
    }
}
