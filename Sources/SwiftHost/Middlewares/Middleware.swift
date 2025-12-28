/// A protocol for middleware that can intercept and process HTTP requests and responses.
///
/// Middleware is executed in a chain, allowing for cross-cutting concerns like
/// logging, authentication, CORS, and header manipulation.
public protocol Middleware: Sendable {
    /// Processes an HTTP request before it reaches the route handler.
    ///
    /// - Parameter request: The incoming HTTP request
    /// - Returns: A potentially modified HTTP request
    func processRequest(_ request: HTTPRequest) async -> HTTPRequest

    /// Processes an HTTP response before it's sent to the client.
    ///
    /// - Parameter response: The outgoing HTTP response
    /// - Returns: A potentially modified HTTP response
    func processResponse(_ response: HTTPResponse) async -> HTTPResponse
}

/// Default implementations that pass requests and responses through unchanged.
public extension Middleware {
    /// Default implementation that returns the request unchanged.
    func processRequest(_ request: HTTPRequest) async -> HTTPRequest {
        request
    }

    /// Default implementation that returns the response unchanged.
    func processResponse(_ response: HTTPResponse) async -> HTTPResponse {
        response
    }
}
