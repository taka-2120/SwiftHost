/// An actor that manages HTTP routes and middleware for request handling.
///
/// The router processes requests through middleware chains and dispatches to matching route handlers.
public actor Router {
    private var routes: [Route]
    private var middlewares = [any Middleware]()

    /// Creates a new router with the specified routes.
    ///
    /// - Parameter routes: A result builder closure that defines the routes
    public init(@RouteBuilder routes: () -> [Route]) {
        self.routes = routes()
    }

    /// Adds a route to the router dynamically.
    ///
    /// - Parameter route: The route to add
    public func add(route: Route) {
        routes.append(route)
    }

    /// Registers middleware to process all requests and responses.
    ///
    /// Middleware is executed in the order it's added.
    ///
    /// - Parameter middleware: The middleware to register
    public func use(_ middleware: any Middleware) {
        middlewares.append(middleware)
    }

    /// Handles an HTTP request by processing it through middleware and matching routes.
    ///
    /// First processes the request through all middleware, then finds a matching route
    /// and executes its handler, finally processes the response through middleware.
    ///
    /// - Parameter request: The HTTP request to handle
    /// - Returns: An HTTP response, either from a matched route or a 404 response
    public func handle(_ request: HTTPRequest) async -> HTTPResponse {
        var currentRequest = request

        for middleware in middlewares {
            currentRequest = await middleware.processRequest(currentRequest)
        }

        for route in routes {
            guard route.matches(request: request) else { continue }

            var response = await route.handler(currentRequest)

            for middleware in middlewares {
                response = await middleware.processResponse(response)
            }

            return response
        }

        return HTTPResponse.text(HTTPStatusCode.notFound.message, statusCode: .notFound)
    }
}

/// A result builder for constructing route arrays with declarative syntax.
///
/// Enables SwiftUI-like syntax for defining routes in a readable way.
@resultBuilder
public struct RouteBuilder {
    /// Builds a route array from individual routes.
    public static func buildBlock(_ routes: Route...) -> [Route] {
        routes
    }

    /// Flattens an array of route arrays into a single array.
    public static func buildArray(_ routes: [[Route]]) -> [Route] {
        routes.flatMap { $0 }
    }

    /// Handles optional route arrays.
    public static func buildOptional(_ routes: [Route]?) -> [Route] {
        routes ?? []
    }

    /// Handles the first branch of a conditional statement.
    public static func buildEither(first routes: [Route]) -> [Route] {
        routes
    }

    /// Handles the second branch of a conditional statement.
    public static func buildEither(second routes: [Route]) -> [Route] {
        routes
    }

    /// Handles routes with limited availability attributes.
    public static func buildLimitedAvailability(_ routes: [Route]) -> [Route] {
        routes
    }
}
