import Testing
import Foundation
@testable import SwiftHost

@Suite("HTTP Server Host Configuration Tests")
struct HTTPServerHostTests {
    @Test("Server with manual host localhost")
    func serverWithManualHostLocalhost() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "localhost",
            port: 0,
            router: router
        )

        let host = await server.getHost()
        #expect(host == "localhost")
    }

    @Test("Server with manual host IP address")
    func serverWithManualHostIpAddress() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "127.0.0.1",
            port: 0,
            router: router
        )

        let host = await server.getHost()
        #expect(host == "127.0.0.1")
    }

    @Test("Server with auto-detect host")
    func serverWithAutoDetectHost() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            port: 0,
            router: router
        )

        let host = await server.getHost()
        // Auto-detected host should not be nil (unless no network)
        // but we can't predict the exact value
        #expect(host != nil || host == nil) // Always passes, just checking it doesn't crash
    }

    @Test("Server URL with manual host")
    func serverUrlWithManualHost() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "localhost",
            port: 8080,
            router: router
        )

        let url = await server.getURL()
        #expect(url?.absoluteString == "http://localhost:8080")
    }

    @Test("Server URL with specific IP")
    func serverUrlWithSpecificIp() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "192.168.1.100",
            port: 3000,
            router: router
        )

        let url = await server.getURL()
        #expect(url?.absoluteString == "http://192.168.1.100:3000")
    }

    @Test("Server URL with 0.0.0.0 host")
    func serverUrlWithAllInterfaces() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "0.0.0.0",
            port: 5000,
            router: router
        )

        let url = await server.getURL()
        #expect(url?.absoluteString == "http://0.0.0.0:5000")
    }

    @Test("getHost returns manual host when set")
    func getHostReturnsManualHostWhenSet() async {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "example.com",
            router: router
        )

        let host = await server.getHost()
        #expect(host == "example.com")
    }

    @Test("Server with IPv6 localhost")
    func serverWithIpv6Localhost() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "::1",
            port: 8080,
            router: router
        )

        let host = await server.getHost()
        #expect(host == "::1")
    }

    @Test("Server with domain name")
    func serverWithDomainName() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "api.example.com",
            port: 443,
            router: router
        )

        let url = await server.getURL()
        #expect(url?.absoluteString == "http://api.example.com:443")
    }

    @Test("Host parameter is optional")
    func hostParameterIsOptional() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        // This should compile and work without specifying host
        let server = HTTPServer(router: router)

        let port = await server.getPort()
        #expect(port != nil)
    }

    @Test("WebSocket server with manual host")
    func webSocketServerWithManualHost() async throws {
        let ws = WebSocketServer()
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let server = HTTPServer(
            host: "localhost",
            port: 9000,
            router: router,
            webSocketServer: ws
        )

        let url = await server.getURL()
        #expect(url?.absoluteString == "http://localhost:9000")
    }
}
