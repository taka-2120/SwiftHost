import Foundation

/// A middleware that logs HTTP request and response information to the console.
///
/// This middleware prints formatted log messages for incoming requests (with timestamp, method, and path)
/// and outgoing responses (with status code and message).
public struct LoggingMiddleware: Middleware {
    /// Creates a new logging middleware instance.
    public init() {}

    /// Processes an incoming HTTP request and logs its details.
    ///
    /// Prints a log entry with ISO8601 timestamp, HTTP method, and request path.
    ///
    /// - Parameter request: The incoming HTTP request to process
    /// - Returns: The unmodified request, passed through to the next middleware or handler
    public func processRequest(_ request: HTTPRequest) async -> HTTPRequest {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] \(request.method.rawValue) \(request.path)")
        return request
    }

    /// Processes an outgoing HTTP response and logs its status.
    ///
    /// Prints a log entry with the response status code and status message.
    ///
    /// - Parameter response: The outgoing HTTP response to process
    /// - Returns: The unmodified response, passed through to the client
    public func processResponse(_ response: HTTPResponse) async -> HTTPResponse {
        print("  → \(response.statusCode.code) \(response.statusCode.message)")
        return response
    }
}
