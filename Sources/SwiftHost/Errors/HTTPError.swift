/// Errors that can occur during HTTP request processing.
public enum HTTPError: Error {
    /// The HTTP request is malformed or cannot be parsed.
    case invalidRequest

    /// A server-side error occurred with an associated error message.
    case serverError(String)
}
