import Testing
import Foundation
@testable import SwiftHost

@Suite("Edge Cases and Error Handling")
struct EdgeCasesAndErrorHandlingTests {
    @Test("Request with empty path")
    func requestWithEmptyPath() {
        let request = HTTPRequest(method: .GET, path: "")
        #expect(request.path == "")
    }

    @Test("Request with root path")
    func requestWithRootPath() async {
        let router = Router {
            Route.get("/") { _ in
                HTTPResponse.text("Home")
            }
        }

        let request = HTTPRequest(method: .GET, path: "/")
        let response = await router.handle(request)

        #expect(response.statusCode.code == 200)
        let body = String(data: response.body!, encoding: .utf8)
        #expect(body == "Home")
    }

    @Test("Response with nil body")
    func responseWithNilBody() {
        let response = HTTPResponse(statusCode: .noContent, headers: [:], body: nil)
        #expect(response.body == nil)
        #expect(response.statusCode.code == 204)
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

    @Test("Large response body")
    func largeResponseBody() {
        let largeContent = String(repeating: "x", count: 100000)
        let response = HTTPResponse.text(largeContent)

        #expect(response.body?.count == largeContent.data(using: .utf8)!.count)
    }

    @Test("Response data formatting includes proper HTTP headers")
    func responseDataFormattingIncludesProperHttpHeaders() {
        let response = HTTPResponse.text("Test", statusCode: .created)
        let data = response.toData()
        let dataString = String(data: data, encoding: .utf8)!

        #expect(dataString.contains("HTTP/1.1"))
        #expect(dataString.contains("201"))
        #expect(dataString.contains("Created"))
        #expect(dataString.contains("\r\n\r\n"))
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

    @Test("Different response status codes")
    func differentResponseStatusCodes() {
        let codes = [
            (HTTPStatusCode.ok, 200, "OK"),
            (HTTPStatusCode.created, 201, "Created"),
            (HTTPStatusCode.noContent, 204, "No Content"),
            (HTTPStatusCode.badRequest, 400, "Bad Request"),
            (HTTPStatusCode.unauthorized, 401, "Unauthorized"),
            (HTTPStatusCode.forbidden, 403, "Forbidden"),
            (HTTPStatusCode.notFound, 404, "Not Found"),
            (HTTPStatusCode.methodNotAllowed, 405, "Method Not Allowed"),
            (HTTPStatusCode.internalServerError, 500, "Internal Server Error"),
        ]

        for (status, expectedCode, expectedMessage) in codes {
            #expect(status.code == expectedCode)
            #expect(status.message == expectedMessage)
        }
    }
}
