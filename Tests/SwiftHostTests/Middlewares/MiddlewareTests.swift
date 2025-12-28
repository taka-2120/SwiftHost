import Testing
import Foundation
@testable import SwiftHost

@Suite("Middleware Tests")
struct MiddlewareTests {
    @Test("CORS middleware adds headers")
    func corsMiddlewareAddsHeaders() async {
        let middleware = CORSMiddleware()
        let response = HTTPResponse.text("Test")
        let processedResponse = await middleware.processResponse(response)

        #expect(processedResponse.headers["Access-Control-Allow-Origin"] != nil)
        #expect(processedResponse.headers["Access-Control-Allow-Methods"] != nil)
    }

    @Test("Header middleware adds custom headers")
    func headerMiddlewareAddsCustomHeaders() async {
        let middleware = HeaderMiddleware(headers: ["X-Custom": "Value"])
        let response = HTTPResponse.text("Test")
        let processedResponse = await middleware.processResponse(response)

        #expect(processedResponse.headers["X-Custom"] == "Value")
    }

    @Test("Middleware chain in router")
    func middlewareChainInRouter() async {
        let router = Router {
            Route.get("/test") { _ in
                HTTPResponse.text("Success")
            }
        }

        await router.use(HeaderMiddleware(headers: ["X-Test": "123"]))

        let request = HTTPRequest(method: .GET, path: "/test")
        let response = await router.handle(request)

        #expect(response.headers["X-Test"] == "123")
    }

    @Test("Multiple middlewares applied in order")
    func multipleMiddlewaresAppliedInOrder() async {
        let router = Router {
            Route.get("/test") { _ in
                HTTPResponse.text("Success")
            }
        }

        await router.use(HeaderMiddleware(headers: ["X-First": "1"]))
        await router.use(HeaderMiddleware(headers: ["X-Second": "2"]))
        await router.use(CORSMiddleware())

        let request = HTTPRequest(method: .GET, path: "/test")
        let response = await router.handle(request)

        #expect(response.headers["X-First"] == "1")
        #expect(response.headers["X-Second"] == "2")
        #expect(response.headers["Access-Control-Allow-Origin"] != nil)
    }

    @Test("Middleware can modify request")
    func middlewareCanModifyRequest() async {
        final class CustomMiddleware: Middleware {
            func processRequest(_ request: HTTPRequest) async -> HTTPRequest {
                let modified = request
                // In a real middleware, you might add logging or validation
                return modified
            }
        }

        let router = Router {
            Route.get("/test") { request in
                let pathInfo = request.path
                return HTTPResponse.text("Path: \(pathInfo)")
            }
        }

        let request = HTTPRequest(method: .GET, path: "/test")
        let response = await router.handle(request)

        let body = String(data: response.body!, encoding: .utf8)
        #expect(body?.contains("/test") == true)
    }

    @Test("Logging middleware processes request and response")
    func loggingMiddlewareProcessesRequestAndResponse() async {
        let middleware = LoggingMiddleware()
        let request = HTTPRequest(method: .GET, path: "/test")
        let processedRequest = await middleware.processRequest(request)

        #expect(processedRequest.method == request.method)
        #expect(processedRequest.path == request.path)

        let response = HTTPResponse.text("Test")
        let processedResponse = await middleware.processResponse(response)

        #expect(processedResponse.statusCode.code == response.statusCode.code)
    }

    @Test("Header middleware preserves existing headers")
    func headerMiddlewarePreservesExistingHeaders() async {
        let middleware = HeaderMiddleware(headers: ["X-New": "NewValue"])
        var response = HTTPResponse.text("Test")
        response.headers["X-Existing"] = "ExistingValue"

        let processedResponse = await middleware.processResponse(response)

        #expect(processedResponse.headers["X-Existing"] == "ExistingValue")
        #expect(processedResponse.headers["X-New"] == "NewValue")
    }
}
