import Testing
import Foundation
@testable import SwiftHost

@Suite("HTTP Request Tests")
struct HTTPRequestTests {
    @Test("Parse simple GET request")
    func parseSimpleGetRequest() throws {
        let requestString = """
        GET /test HTTP/1.1\r
        Host: localhost:8080\r
        User-Agent: TestClient/1.0\r
        \r
        """
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        #expect(request.method == .GET)
        #expect(request.path == "/test")
        #expect(request.headers["Host"] == "localhost:8080")
        #expect(request.headers["User-Agent"] == "TestClient/1.0")
    }

    @Test("Parse request with query parameters")
    func parseRequestWithQueryParameters() throws {
        let requestString = """
        GET /search?q=swift&lang=en HTTP/1.1\r
        Host: localhost:8080\r
        \r
        """
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        #expect(request.path == "/search")
        #expect(request.queryParameters["q"] == "swift")
        #expect(request.queryParameters["lang"] == "en")
    }

    @Test("Parse POST request with body")
    func parsePostRequestWithBody() throws {
        let requestString = """
        POST /api/data HTTP/1.1\r
        Host: localhost:8080\r
        Content-Type: application/json\r
        Content-Length: 13\r
        \r
        {"key":"value"}
        """
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        #expect(request.method == .POST)
        #expect(request.path == "/api/data")
        #expect(request.body != nil)
        #expect(request.headers["Content-Type"] == "application/json")

        let bodyString = String(data: request.body!, encoding: .utf8)
        #expect(bodyString?.contains("key") == true)
    }

    @Test("Parse request with multiple headers")
    func parseRequestWithMultipleHeaders() throws {
        let requestString = """
        GET /api HTTP/1.1\r
        Host: localhost:8080\r
        Accept: application/json\r
        Authorization: Bearer token123\r
        X-Custom-Header: CustomValue\r
        \r
        """
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        #expect(request.headers.count == 4)
        #expect(request.headers["Accept"] == "application/json")
        #expect(request.headers["Authorization"] == "Bearer token123")
        #expect(request.headers["X-Custom-Header"] == "CustomValue")
    }

    @Test("Parse different HTTP methods")
    func parseDifferentHttpMethods() throws {
        let methods: [HTTPMethod] = [.GET, .POST, .PUT, .DELETE, .PATCH, .HEAD, .OPTIONS]

        for method in methods {
            let requestString = """
            \(method.rawValue) /test HTTP/1.1\r
            Host: localhost\r
            \r
            """
            let data = requestString.data(using: .utf8)!
            let request = try HTTPRequest.parse(from: data)
            #expect(request.method == method)
        }
    }

    @Test("Parse request with special characters in query")
    func parseRequestWithSpecialCharactersInQuery() throws {
        let requestString = """
        GET /search?q=hello%20world&filter=test%26special HTTP/1.1\r
        Host: localhost\r
        \r
        """
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        #expect(request.queryParameters["q"] == "hello world")
        #expect(request.queryParameters["filter"] == "test&special")
    }

    @Test("Initialize request directly")
    func initializeRequestDirectly() {
        let request = HTTPRequest(
            method: .POST,
            path: "/api/users",
            headers: ["Content-Type": "application/json"],
            body: "{\"name\":\"John\"}".data(using: .utf8),
            queryParameters: ["id": "123"]
        )

        #expect(request.method == .POST)
        #expect(request.path == "/api/users")
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.queryParameters["id"] == "123")
    }

    @Test("Request with empty body")
    func requestWithEmptyBody() throws {
        let requestString = "DELETE /api/user/123 HTTP/1.1\r\nHost: localhost\r\n\r\n"
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        #expect(request.method == .DELETE)
        // Body should be nil or empty for requests with no content
        #expect(request.body == nil || (request.body?.count ?? 0) == 0)
    }

    @Test("Request with empty path")
    func requestWithEmptyPath() {
        let request = HTTPRequest(method: .GET, path: "")
        #expect(request.path == "")
    }

    @Test("Request with query parameter without value")
    func requestWithQueryParameterWithoutValue() throws {
        let requestString = """
        GET /search?q&lang=en HTTP/1.1\r
        Host: localhost\r
        \r
        """
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        #expect(request.path == "/search")
    }

    @Test("Request headers with whitespace")
    func requestHeadersWithWhitespace() throws {
        let requestString = """
        GET /test HTTP/1.1\r
        Host:   localhost:8080   \r
        User-Agent: TestClient\r
        \r
        """
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        #expect(request.headers["Host"] == "localhost:8080")
        #expect(request.headers["User-Agent"] == "TestClient")
    }

    @Test("Multiple query parameters with same key")
    func multipleQueryParametersWithSameKey() throws {
        let requestString = """
        GET /search?tag=swift&tag=ios&q=test HTTP/1.1\r
        Host: localhost\r
        \r
        """
        let data = requestString.data(using: .utf8)!
        let request = try HTTPRequest.parse(from: data)

        // Note: The parser takes the last value for duplicate keys
        #expect(request.queryParameters["q"] == "test")
    }
}
