import Testing
import Foundation
@testable import SwiftHost

@Suite("HTTP Response Tests")
struct HTTPResponseTests {
    @Test("Create text response")
    func createTextResponse() {
        let response = HTTPResponse.text("Hello, World!")

        #expect(response.statusCode.code == 200)
        #expect(response.headers["Content-Type"]?.contains("text/plain") == true)

        let bodyString = String(data: response.body!, encoding: .utf8)
        #expect(bodyString == "Hello, World!")
    }

    @Test("Create JSON response")
    func createJsonResponse() throws {
        let data = ["name": "SwiftHost", "version": "1.0"]
        let response = try HTTPResponse.json(data)

        #expect(response.statusCode.code == 200)
        #expect(response.headers["Content-Type"] == "application/json")
        #expect(response.body != nil)
    }

    @Test("Create HTML response")
    func createHtmlResponse() {
        let html = "<h1>Hello</h1>"
        let response = HTTPResponse.html(html)

        #expect(response.statusCode.code == 200)
        #expect(response.headers["Content-Type"]?.contains("text/html") == true)
    }

    @Test("Response to data conversion")
    func responseToDataConversion() {
        let response = HTTPResponse.text("Test", statusCode: .ok)
        let data = response.toData()
        let dataString = String(data: data, encoding: .utf8)!

        #expect(dataString.contains("HTTP/1.1 200 OK"))
        #expect(dataString.contains("Content-Type: text/plain"))
        #expect(dataString.contains("Test"))
    }

    @Test("Response with custom headers")
    func responseWithCustomHeaders() {
        let headers = ["X-Custom": "Value", "Cache-Control": "no-cache"]
        let response = HTTPResponse(
            statusCode: .ok,
            headers: headers,
            body: "Content".data(using: .utf8)
        )

        #expect(response.headers["X-Custom"] == "Value")
        #expect(response.headers["Cache-Control"] == "no-cache")
    }

    @Test("Response with different status codes")
    func responseWithDifferentStatusCodes() {
        let statuses: [HTTPStatusCode] = [.ok, .created, .badRequest, .notFound, .internalServerError]

        for status in statuses {
            let response = HTTPResponse.text("Test", statusCode: status)
            #expect(response.statusCode.code == status.code)
        }
    }

    @Test("Response body is UTF-8 encoded")
    func responseBodyIsUtf8Encoded() {
        let content = "Hello, 世界"
        let response = HTTPResponse.text(content)

        let bodyString = String(data: response.body!, encoding: .utf8)
        #expect(bodyString == content)
    }

    @Test("JSON response with array")
    func jsonResponseWithArray() throws {
        let items = ["item1", "item2", "item3"]
        let response = try HTTPResponse.json(items)

        #expect(response.statusCode.code == 200)
        #expect(response.headers["Content-Type"] == "application/json")

        let decoded = try JSONDecoder().decode([String].self, from: response.body!)
        #expect(decoded.count == 3)
    }

    @Test("Response auto-sets Content-Length")
    func responseAutoSetsContentLength() {
        let content = "Test"
        let response = HTTPResponse.text(content)

        #expect(response.headers["Content-Length"] != nil)
        let contentLength = Int(response.headers["Content-Length"]!)
        #expect(contentLength == content.data(using: .utf8)?.count)
    }

    @Test("Response with nil body")
    func responseWithNilBody() {
        let response = HTTPResponse(statusCode: .noContent, headers: [:], body: nil)
        #expect(response.body == nil)
        #expect(response.statusCode.code == 204)
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

    @Test("Text response content type")
    func textResponseContentType() {
        let response = HTTPResponse.text("Hello")
        #expect(response.headers["Content-Type"]?.contains("text/plain") == true)
        #expect(response.headers["Content-Type"]?.contains("charset=utf-8") == true)
    }

    @Test("JSON response content type")
    func jsonResponseContentType() throws {
        let response = try HTTPResponse.json(["key": "value"])
        #expect(response.headers["Content-Type"] == "application/json")
    }

    @Test("HTML response content type")
    func htmlResponseContentType() {
        let response = HTTPResponse.html("<h1>Title</h1>")
        #expect(response.headers["Content-Type"]?.contains("text/html") == true)
        #expect(response.headers["Content-Type"]?.contains("charset=utf-8") == true)
    }

    @Test("Custom content type header")
    func customContentTypeHeader() {
        let response = HTTPResponse(
            statusCode: .ok,
            headers: ["Content-Type": "application/xml"],
            body: "<root/>".data(using: .utf8)
        )
        #expect(response.headers["Content-Type"] == "application/xml")
    }
}
