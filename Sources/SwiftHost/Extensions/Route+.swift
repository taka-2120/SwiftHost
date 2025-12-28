/// Extension providing convenient static builder methods for creating routes with specific HTTP methods.
public extension Route {
    /// Creates a GET route.
    /// - Parameters:
    ///   - path: The request path pattern.
    ///   - handler: The async handler function for this route.
    /// - Returns: A Route configured for GET requests.
    static func get(
        _ path: String,
        handler: @escaping @Sendable (HTTPRequest) async -> HTTPResponse
    ) -> Route {
        Route(method: .GET, path: path, handler: handler)
    }

    /// Creates a POST route.
    /// - Parameters:
    ///   - path: The request path pattern.
    ///   - handler: The async handler function for this route.
    /// - Returns: A Route configured for POST requests.
    static func post(
        _ path: String,
        handler: @escaping @Sendable (HTTPRequest) async -> HTTPResponse
    ) -> Route {
        Route(method: .POST, path: path, handler: handler)
    }

    /// Creates a PUT route.
    /// - Parameters:
    ///   - path: The request path pattern.
    ///   - handler: The async handler function for this route.
    /// - Returns: A Route configured for PUT requests.
    static func put(
        _ path: String,
        handler: @escaping @Sendable (HTTPRequest) async -> HTTPResponse
    ) -> Route {
        Route(method: .PUT, path: path, handler: handler)
    }

    /// Creates a DELETE route.
    /// - Parameters:
    ///   - path: The request path pattern.
    ///   - handler: The async handler function for this route.
    /// - Returns: A Route configured for DELETE requests.
    static func delete(
        _ path: String,
        handler: @escaping @Sendable (HTTPRequest) async -> HTTPResponse
    ) -> Route {
        Route(method: .DELETE, path: path, handler: handler)
    }

    /// Creates a PATCH route.
    /// - Parameters:
    ///   - path: The request path pattern.
    ///   - handler: The async handler function for this route.
    /// - Returns: A Route configured for PATCH requests.
    static func patch(
        _ path: String,
        handler: @escaping @Sendable (HTTPRequest) async -> HTTPResponse
    ) -> Route {
        Route(method: .PATCH, path: path, handler: handler)
    }
}
