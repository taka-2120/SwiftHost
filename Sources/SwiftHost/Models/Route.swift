/// Represents a route that matches HTTP requests and handles them.
///
/// Routes can match specific HTTP methods and support path patterns including
/// wildcards (*) and dynamic parameters (:param).
public struct Route: Sendable {
    /// The HTTP method to match (nil matches all methods).
    public let method: HTTPMethod?
    /// The path pattern to match (supports wildcards and :params).
    public let path: String
    /// The async handler function that processes matching requests.
    public let handler: @Sendable (HTTPRequest) async -> HTTPResponse

    /// Creates a new route.
    ///
    /// - Parameters:
    ///   - method: HTTP method to match (nil matches all methods)
    ///   - path: Path pattern (supports "/path/*" wildcards and "/path/:id" parameters)
    ///   - handler: Async function to handle matching requests
    public init(
        method: HTTPMethod? = nil,
        path: String,
        handler: @escaping @Sendable (HTTPRequest) async -> HTTPResponse
    ) {
        self.method = method
        self.path = path
        self.handler = handler
    }

    /// Determines if this route matches the given request.
    ///
    /// - Parameter request: The HTTP request to match against
    /// - Returns: true if the route matches, false otherwise
    func matches(request: HTTPRequest) -> Bool {
        let methodMatches = method == nil || method == request.method
        let pathMatches = matchPath(pattern: path, path: request.path)
        return methodMatches && pathMatches
    }

    /// Matches a path pattern against a request path.
    ///
    /// Supports exact matches, wildcard suffixes ("/*"), and dynamic parameters (":param").
    ///
    /// - Parameters:
    ///   - pattern: The path pattern to match (e.g., "/users/:id" or "/static/*")
    ///   - requestPath: The actual request path
    /// - Returns: true if the pattern matches the request path
    private func matchPath(pattern: String, path requestPath: String) -> Bool {
        if pattern == requestPath {
            return true
        }

        if pattern.hasSuffix("*") {
            let prefix = String(pattern.dropLast())
            return requestPath.hasPrefix(prefix)
        }

        let patternComponents = pattern.split(separator: "/")
        let requestPathComponents = requestPath.split(separator: "/")

        guard patternComponents.count == requestPathComponents.count else {
            return false
        }

        for (patternComponent, requestPathComponent) in zip(patternComponents, requestPathComponents) {
            if patternComponent.hasPrefix(":") {
                continue
            }

            if patternComponent != requestPathComponent {
                return false
            }
        }

        return true
    }
}
