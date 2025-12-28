/// A middleware that adds Cross-Origin Resource Sharing (CORS) headers to responses.
///
/// Enables web browsers to make cross-origin requests to this server by setting
/// appropriate Access-Control-* headers.
public struct CORSMiddleware: Middleware {
    private let allowedOrigins: [String]
    private let allowedMethods: [HTTPMethod]
    private let allowedHeaders: [String]

    /// Creates a new CORS middleware with the specified policies.
    ///
    /// - Parameters:
    ///   - allowedOrigins: List of allowed origins (default: ["*"] for all origins)
    ///   - allowedMethods: List of allowed HTTP methods (default: GET, POST, PUT, DELETE, PATCH, OPTIONS)
    ///   - allowedHeaders: List of allowed request headers (default: Content-Type, Authorization)
    public init(
        allowedOrigins: [String] = ["*"],
        allowedMethods: [HTTPMethod] = [.GET, .POST, .PUT, .DELETE, .PATCH, .OPTIONS],
        allowedHeaders: [String] = ["Content-Type", "Authorization"]
    ) {
        self.allowedOrigins = allowedOrigins
        self.allowedMethods = allowedMethods
        self.allowedHeaders = allowedHeaders
    }

    /// Adds CORS headers to the response.
    ///
    /// - Parameter response: The HTTP response to modify
    /// - Returns: The response with CORS headers added
    public func processResponse(_ response: HTTPResponse) async -> HTTPResponse {
        var newResponse = response
        newResponse.headers["Access-Control-Allow-Origin"] = allowedOrigins.joined(separator: ", ")
        newResponse.headers["Access-Control-Allow-Methods"] = allowedMethods.map(\.rawValue).joined(separator: ", ")
        newResponse.headers["Access-Control-Allow-Headers"] = allowedHeaders.joined(separator: ", ")
        return newResponse
    }
}
