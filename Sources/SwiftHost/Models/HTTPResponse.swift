import Foundation

/// Represents an HTTP response with status code, headers, and optional body.
public struct HTTPResponse: Sendable {
    /// The HTTP status code for this response.
    public let statusCode: HTTPStatusCode
    /// HTTP headers as key-value pairs.
    public var headers: [String: String]
    /// Optional response body data.
    public let body: Data?

    /// Creates a new HTTP response.
    ///
    /// Automatically sets Content-Length header if body is present and header not already set.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code (default: .ok)
    ///   - headers: HTTP headers (default: empty)
    ///   - body: Optional response body data
    public init(
        statusCode: HTTPStatusCode = .ok,
        headers: [String : String] = [:],
        body: Data? = nil
    ) {
        self.statusCode = statusCode
        var updatedHeaders = headers
        if body != nil && updatedHeaders["Content-Length"] == nil {
            updatedHeaders["Content-Length"] = "\(body?.count ?? 0)"
        }
        self.headers = updatedHeaders
        self.body = body
    }

    /// Creates a plain text response.
    ///
    /// - Parameters:
    ///   - content: The text content
    ///   - statusCode: The HTTP status code (default: .ok)
    /// - Returns: An HTTPResponse with Content-Type set to text/plain
    public static func text(_ content: String, statusCode: HTTPStatusCode = .ok) -> HTTPResponse {
        let data = content.data(using: .utf8)
        return HTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "text/plain; charset=utf-8"],
            body: data
        )
    }

    /// Creates a JSON response from an encodable value.
    ///
    /// - Parameters:
    ///   - value: The encodable value to convert to JSON
    ///   - statusCode: The HTTP status code (default: .ok)
    /// - Returns: An HTTPResponse with Content-Type set to application/json
    /// - Throws: Encoding errors if the value cannot be encoded to JSON
    public static func json<T: Encodable>(_ value: T, statusCode: HTTPStatusCode = .ok) throws -> HTTPResponse {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(value)

        return HTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "application/json"],
            body: data
        )
    }

    /// Creates an HTML response.
    ///
    /// - Parameters:
    ///   - content: The HTML content
    ///   - statusCode: The HTTP status code (default: .ok)
    /// - Returns: An HTTPResponse with Content-Type set to text/html
    public static func html(_ content: String, statusCode: HTTPStatusCode = .ok) -> HTTPResponse {
        let data = content.data(using: .utf8)
        return HTTPResponse(
            statusCode: statusCode,
            headers: [
                "Content-Type": "text/html; charset=utf-8",
                "Connection": "close"
            ],
            body: data
        )
    }

    /// Converts the HTTP response to raw data for transmission.
    ///
    /// Formats the response as an HTTP/1.1 response with status line, headers, and body.
    ///
    /// - Returns: The complete HTTP response as Data
    func toData() -> Data {
        var response = "HTTP/1.1 \(statusCode.code) \(statusCode.message)\r\n"

        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }

        response += "\r\n"

        var data = response.data(using: .utf8) ?? Data()
        if let body = body {
            data.append(body)
        }

        return data
    }
}
