/// HTTP request methods as defined in RFC 7231 and related specifications.
public enum HTTPMethod: String, Sendable, CaseIterable {
    /// Retrieve a resource.
    case GET
    /// Submit data to create or process a resource.
    case POST
    /// Replace a resource entirely.
    case PUT
    /// Remove a resource.
    case DELETE
    /// Apply partial modifications to a resource.
    case PATCH
    /// Retrieve headers only (no body).
    case HEAD
    /// Describe communication options.
    case OPTIONS
    /// Perform a message loop-back test.
    case TRACE
    /// Establish a tunnel to the server.
    case CONNECT
}
