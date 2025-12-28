/// Represents HTTP status codes for responses.
///
/// Includes common status codes (1xx, 2xx, 3xx, 4xx, 5xx) and supports custom status codes.
public enum HTTPStatusCode: Sendable {
    case switchingProtocols
    case ok
    case created
    case accepted
    case noContent
    case movedPermanently
    case found
    case notModified
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case methodNotAllowed
    case internalServerError
    case notImplemented
    case serviceUnavailable
    case custom(Int, String)

    /// The numeric HTTP status code.
    public var code: Int {
        switch self {
        case .switchingProtocols: return 101
        case .ok: return 200
        case .created: return 201
        case .accepted: return 202
        case .noContent: return 204
        case .movedPermanently: return 301
        case .found: return 302
        case .notModified: return 304
        case .badRequest: return 400
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .methodNotAllowed: return 405
        case .internalServerError: return 500
        case .notImplemented: return 501
        case .serviceUnavailable: return 503
        case .custom(let code, _): return code
        }
    }

    /// The human-readable status message corresponding to the status code.
    public var message: String {
        switch self {
        case .switchingProtocols: return "Switching Protocols"
        case .ok: return "OK"
        case .created: return "Created"
        case .accepted: return "Accepted"
        case .noContent: return "No Content"
        case .movedPermanently: return "Moved Permanently"
        case .found: return "Found"
        case .notModified: return "Not Modified"
        case .badRequest: return "Bad Request"
        case .unauthorized: return "Unauthorized"
        case .forbidden: return "Forbidden"
        case .notFound: return "Not Found"
        case .methodNotAllowed: return "Method Not Allowed"
        case .internalServerError: return "Internal Server Error"
        case .notImplemented: return "Not Implemented"
        case .serviceUnavailable: return "Service Unavailable"
        case .custom(_, let message): return message
        }
    }
}
