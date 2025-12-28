import Foundation

/// Represents an HTTP request with method, path, headers, body, and query parameters.
public struct HTTPRequest: Sendable {
    /// The HTTP method (GET, POST, etc.).
    public let method: HTTPMethod
    /// The request path (e.g., "/users/123").
    public let path: String
    /// HTTP headers as key-value pairs.
    public let headers: [String: String]
    /// Optional request body data.
    public let body: Data?
    /// Query parameters parsed from the URL.
    public let queryParameters: [String: String]

    /// Creates a new HTTP request.
    ///
    /// - Parameters:
    ///   - method: The HTTP method
    ///   - path: The request path
    ///   - headers: HTTP headers (default: empty)
    ///   - body: Optional request body data
    ///   - queryParameters: Query parameters (default: empty)
    public init(
        method: HTTPMethod,
        path: String,
        headers: [String: String] = [:],
        body: Data? = nil,
        queryParameters: [String: String] = [:]
    ) {
        self.method = method
        self.path = path
        self.headers = headers
        self.body = body
        self.queryParameters = queryParameters
    }

    /// Parses raw HTTP request data into an HTTPRequest instance.
    ///
    /// Parses the start-line, headers, query parameters, and body from raw HTTP data.
    ///
    /// - Parameter data: Raw HTTP request data
    /// - Returns: Parsed HTTPRequest instance
    /// - Throws: HTTPError.invalidRequest if parsing fails
    static func parse(from data: Data) throws -> Self {
        guard let requestString = String(data: data, encoding: .utf8) else {
            throw HTTPError.invalidRequest
        }

        let requestLines = requestString.components(separatedBy: "\r\n")
        guard let requestStartLine = requestLines.first else {
            throw HTTPError.invalidRequest
        }

        // Parse start-line
        let requestComponents = requestStartLine.components(separatedBy: " ")
        guard requestComponents.count == 3, let method = HTTPMethod(rawValue: requestComponents[0]) else {
            throw HTTPError.invalidRequest
        }

        let fullPath = requestComponents[1]
        var path = fullPath
        var queryParameters = [String: String]()

        if let queryStartIndex = fullPath.firstIndex(of: "?") {
            path = String(fullPath[..<queryStartIndex])
            let queryString = String(fullPath[fullPath.index(after: queryStartIndex)...])
            queryParameters = parseQueryString(queryString)
        }

        // Parse headers
        var headers = [String: String]()
        var bodyStartLineIndex = 0

        for (index, requestLine) in requestLines.enumerated() where index > 0 {
            if requestLine.isEmpty {
                bodyStartLineIndex = index + 1
                break
            }

            if let colonIndex = requestLine.firstIndex(of: ":") {
                let key = String(requestLine[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(
                    requestLine[requestLine.index(after: colonIndex)...]
                ).trimmingCharacters(in: .whitespaces)

                headers[key] = value
            }
        }

        // Parse body
        let body = parseBody(lines: requestLines, startsFrom: bodyStartLineIndex)

        return HTTPRequest(
            method: method,
            path: path,
            headers: headers,
            body: body,
            queryParameters: queryParameters
        )
    }

    /// Parses a query string into key-value pairs.
    ///
    /// Decodes percent-encoded values and splits on "&" and "=" delimiters.
    ///
    /// - Parameter query: The query string to parse (e.g., "key1=value1&key2=value2")
    /// - Returns: Dictionary of query parameters
    private static func parseQueryString(_ query: String) -> [String: String] {
        var parameters = [String: String]()
        let pairs = query.split(separator: "&")

        for pair in pairs {
            let keyValue = pair.split(separator: "=")
            if keyValue.count == 2 {
                let key = keyValue[0].removingPercentEncoding ?? String(keyValue[0])
                let value = keyValue[1].removingPercentEncoding ?? String(keyValue[1])
                parameters[key] = value
            }
        }

        return parameters
    }

    /// Parses the HTTP request body from request lines.
    ///
    /// - Parameters:
    ///   - lines: All lines from the HTTP request
    ///   - startIndex: The line index where the body starts
    /// - Returns: Body data, or nil if no body exists
    private static func parseBody(lines: [String], startsFrom startIndex: Int) -> Data? {
        guard startIndex < lines.count else { return nil }

        let bodyLines = lines[startIndex...].joined(separator: "\r\n")
        if !bodyLines.trimmingCharacters(in: .whitespaces).isEmpty {
            return bodyLines.data(using: .utf8)
        }

        return nil
    }
}
