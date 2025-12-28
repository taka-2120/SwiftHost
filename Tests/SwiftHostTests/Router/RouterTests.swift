import Testing
import Foundation
@testable import SwiftHost

@Suite("Router Tests")
struct RouterTests {
    @Test("Route matching - exact path")
    func routeMatchingExactPath() async {
        let router = Router {
            Route.get("/test") { _ in
                HTTPResponse.text("Success")
            }
        }

        let request = HTTPRequest(method: .GET, path: "/test")
        let response = await router.handle(request)

        #expect(response.statusCode.code == 200)
        let body = String(data: response.body!, encoding: .utf8)
        #expect(body == "Success")
    }

    @Test("Route matching - not found")
    func routeMatchingNotFound() async {
        let router = Router {
            Route.get("/test") { _ in
                HTTPResponse.text("Success")
            }
        }

        let request = HTTPRequest(method: .GET, path: "/nonexistent")
        let response = await router.handle(request)

        #expect(response.statusCode.code == 404)
    }

    @Test("Route matching - different methods")
    func routeMatchingDifferentMethods() async {
        let router = Router {
            Route.get("/api") { _ in
                HTTPResponse.text("GET")
            }
            Route.post("/api") { _ in
                HTTPResponse.text("POST")
            }
        }

        let getRequest = HTTPRequest(method: .GET, path: "/api")
        let getResponse = await router.handle(getRequest)
        let getBody = String(data: getResponse.body!, encoding: .utf8)
        #expect(getBody == "GET")

        let postRequest = HTTPRequest(method: .POST, path: "/api")
        let postResponse = await router.handle(postRequest)
        let postBody = String(data: postResponse.body!, encoding: .utf8)
        #expect(postBody == "POST")
    }

    @Test("Route with path parameters")
    func routeWithPathParameters() async {
        let router = Router {
            Route.get("/api/users/:id") { _ in
                HTTPResponse.text("User details")
            }
        }

        let request = HTTPRequest(method: .GET, path: "/api/users/123")
        let response = await router.handle(request)

        #expect(response.statusCode.code == 200)
        let body = String(data: response.body!, encoding: .utf8)
        #expect(body == "User details")
    }

    @Test("Route with wildcard path")
    func routeWithWildcardPath() async {
        let router = Router {
            Route.get("/api/*") { _ in
                HTTPResponse.text("API endpoint")
            }
        }

        let request1 = HTTPRequest(method: .GET, path: "/api/users")
        let response1 = await router.handle(request1)
        #expect(response1.statusCode.code == 200)

        let request2 = HTTPRequest(method: .GET, path: "/api/posts/123")
        let response2 = await router.handle(request2)
        #expect(response2.statusCode.code == 200)
    }

    @Test("Multiple routes with same path different methods")
    func multipleRoutesWithSamePathDifferentMethods() async {
        let router = Router {
            Route.get("/resource") { _ in
                HTTPResponse.text("GET")
            }
            Route.post("/resource") { _ in
                HTTPResponse.text("POST")
            }
            Route.put("/resource") { _ in
                HTTPResponse.text("PUT")
            }
            Route.delete("/resource") { _ in
                HTTPResponse.text("DELETE")
            }
        }

        for method in [HTTPMethod.GET, .POST, .PUT, .DELETE] {
            let request = HTTPRequest(method: method, path: "/resource")
            let response = await router.handle(request)
            #expect(response.statusCode.code == 200)
        }
    }

    @Test("Router returns 404 for unmapped methods")
    func routerReturns404ForUnmappedMethods() async {
        let router = Router {
            Route.get("/test") { _ in
                HTTPResponse.text("GET only")
            }
        }

        let request = HTTPRequest(method: .POST, path: "/test")
        let response = await router.handle(request)

        #expect(response.statusCode.code == 404)
    }

    @Test("Route with access to request data")
    func routeWithAccessToRequestData() async {
        let router = Router {
            Route.post("/users") { request in
                if request.body != nil {
                    return HTTPResponse.text("Body received", statusCode: .created)
                } else {
                    return HTTPResponse.text("No body", statusCode: .badRequest)
                }
            }
        }

        let body = "{\"name\":\"John\"}".data(using: .utf8)
        let request = HTTPRequest(method: .POST, path: "/users", body: body)
        let response = await router.handle(request)

        #expect(response.statusCode.code == 201)
    }

    @Test("Router with no routes returns 404")
    func routerWithNoRoutesReturns404() async {
        let router = Router {}

        let request = HTTPRequest(method: .GET, path: "/anything")
        let response = await router.handle(request)

        #expect(response.statusCode.code == 404)
    }

    @Test("Add route dynamically")
    func addRouteDynamically() async {
        let router = Router {}

        await router.add(route: Route.get("/dynamic") { _ in
            HTTPResponse.text("Dynamic route")
        })

        let request = HTTPRequest(method: .GET, path: "/dynamic")
        let response = await router.handle(request)

        #expect(response.statusCode.code == 200)
        let body = String(data: response.body!, encoding: .utf8)
        #expect(body == "Dynamic route")
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

    @Test("Route with trailing slash vs without")
    func routeWithTrailingSlashVsWithout() async {
        let router = Router {
            Route.get("/api") { _ in
                HTTPResponse.text("Match")
            }
        }

        let request1 = HTTPRequest(method: .GET, path: "/api")
        let response1 = await router.handle(request1)
        #expect(response1.statusCode.code == 200)

        let request2 = HTTPRequest(method: .GET, path: "/api/")
        let response2 = await router.handle(request2)
        // Note: "/api/" is treated as different from "/api" in this implementation
        #expect(response2.statusCode.code == 200)
    }

    @Test("Nested path routes")
    func nestedPathRoutes() async {
        let router = Router {
            Route.get("/api/users") { _ in
                HTTPResponse.text("Users")
            }
            Route.get("/api/users/active") { _ in
                HTTPResponse.text("Active users")
            }
            Route.get("/api/posts") { _ in
                HTTPResponse.text("Posts")
            }
        }

        let request1 = HTTPRequest(method: .GET, path: "/api/users")
        let response1 = await router.handle(request1)
        let body1 = String(data: response1.body!, encoding: .utf8)
        #expect(body1 == "Users")

        let request2 = HTTPRequest(method: .GET, path: "/api/users/active")
        let response2 = await router.handle(request2)
        let body2 = String(data: response2.body!, encoding: .utf8)
        #expect(body2 == "Active users")
    }

    @Test("Route matching with multiple parameters")
    func routeMatchingWithMultipleParameters() async {
        let router = Router {
            Route.get("/api/users/:id/posts/:postId") { _ in
                HTTPResponse.text("Post details")
            }
        }

        let request = HTTPRequest(method: .GET, path: "/api/users/123/posts/456")
        let response = await router.handle(request)

        #expect(response.statusCode.code == 200)
    }

    @Test("Wildcard route catches all remaining paths")
    func wildcardRouteCatchesAllRemainingPaths() async {
        let router = Router {
            Route.get("/api/specific") { _ in
                HTTPResponse.text("Specific")
            }
            Route.get("/api/*") { _ in
                HTTPResponse.text("Wildcard")
            }
        }

        let request1 = HTTPRequest(method: .GET, path: "/api/specific")
        let response1 = await router.handle(request1)
        let body1 = String(data: response1.body!, encoding: .utf8)
        #expect(body1 == "Specific")

        let request2 = HTTPRequest(method: .GET, path: "/api/other/deep/path")
        let response2 = await router.handle(request2)
        let body2 = String(data: response2.body!, encoding: .utf8)
        #expect(body2 == "Wildcard")
    }
}
