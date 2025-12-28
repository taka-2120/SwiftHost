import Testing
import Foundation
@testable import SwiftHost

@Suite("HTTP Status Code Tests")
struct HTTPStatusCodeTests {
    @Test("Status code values")
    func statusCodeValues() {
        #expect(HTTPStatusCode.ok.code == 200)
        #expect(HTTPStatusCode.created.code == 201)
        #expect(HTTPStatusCode.badRequest.code == 400)
        #expect(HTTPStatusCode.notFound.code == 404)
        #expect(HTTPStatusCode.internalServerError.code == 500)
    }

    @Test("Custom status code")
    func customStatusCode() {
        let custom = HTTPStatusCode.custom(418, "I'm a teapot")
        #expect(custom.code == 418)
        #expect(custom.message == "I'm a teapot")
    }

    @Test("All status codes have proper codes")
    func allStatusCodesHaveProperCodes() {
        #expect(HTTPStatusCode.accepted.code == 202)
        #expect(HTTPStatusCode.noContent.code == 204)
        #expect(HTTPStatusCode.movedPermanently.code == 301)
        #expect(HTTPStatusCode.found.code == 302)
        #expect(HTTPStatusCode.notModified.code == 304)
        #expect(HTTPStatusCode.unauthorized.code == 401)
        #expect(HTTPStatusCode.forbidden.code == 403)
        #expect(HTTPStatusCode.methodNotAllowed.code == 405)
        #expect(HTTPStatusCode.notImplemented.code == 501)
        #expect(HTTPStatusCode.serviceUnavailable.code == 503)
    }

    @Test("Status code messages are properly set")
    func statusCodeMessagesAreProperlySet() {
        #expect(HTTPStatusCode.ok.message == "OK")
        #expect(HTTPStatusCode.created.message == "Created")
        #expect(HTTPStatusCode.notFound.message == "Not Found")
        #expect(HTTPStatusCode.internalServerError.message == "Internal Server Error")
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
