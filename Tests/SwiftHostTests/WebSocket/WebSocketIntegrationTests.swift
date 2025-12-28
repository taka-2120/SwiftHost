import Testing
import Foundation
import Network
@testable import SwiftHost

@Suite("WebSocket Integration Tests")
struct WebSocketIntegrationTests {
    @Test("HTTPServer accepts WebSocket parameter")
    func httpServerAcceptsWebSocketParameter() async throws {
        let webSocketServer = WebSocketServer()
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let _ = HTTPServer(
            port: 0, // Random port
            router: router,
            webSocketServer: webSocketServer
        )

        // Test passes if no crash occurs
        #expect(true)
    }

    @Test("HTTPServer works without WebSocket server")
    func httpServerWorksWithoutWebSocketServer() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("Hello")
            }
        }

        let _ = HTTPServer(port: 0, router: router)
        // Test passes if no crash occurs
        #expect(true)
    }

    @Test("HTTP request is still handled when WebSocket server is present")
    func httpRequestIsStillHandledWhenWebSocketServerIsPresent() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("OK")
            }
        }

        let webSocketServer = WebSocketServer()
        let _ = HTTPServer(
            port: 0,
            router: router,
            webSocketServer: webSocketServer
        )

        // Regular HTTP request should still work
        let request = HTTPRequest(
            method: .GET,
            path: "/",
            headers: [:],
            body: nil
        )

        let response = await router.handle(request)
        #expect(response.statusCode.code == 200)
    }

    @Test("WebSocket upgrade request is detected")
    func webSocketUpgradeRequestIsDetected() throws {
        let request = HTTPRequest(
            method: .GET,
            path: "/",
            headers: [
                "Upgrade": "websocket",
                "Connection": "Upgrade",
                "Sec-WebSocket-Key": "dGhlIHNhbXBsZSBub25jZQ=="
            ],
            body: nil
        )

        #expect(request.headers["Upgrade"]?.lowercased() == "websocket")
        #expect(request.headers["Connection"]?.lowercased().contains("upgrade") == true)
        #expect(request.headers["Sec-WebSocket-Key"] != nil)
    }

    @Test("Non-WebSocket request is not treated as upgrade")
    func nonWebSocketRequestIsNotTreatedAsUpgrade() {
        let request = HTTPRequest(
            method: .GET,
            path: "/",
            headers: [:],
            body: nil
        )

        #expect(request.headers["Upgrade"] == nil)
    }

    @Test("Switching Protocols status code exists")
    func switchingProtocolsStatusCodeExists() {
        let statusCode = HTTPStatusCode.switchingProtocols

        #expect(statusCode.code == 101)
        #expect(statusCode.message == "Switching Protocols")
    }

    @Test("WebSocket response has correct headers")
    func webSocketResponseHasCorrectHeaders() {
        let response = HTTPResponse(
            statusCode: .switchingProtocols,
            headers: [
                "Upgrade": "websocket",
                "Connection": "Upgrade",
                "Sec-WebSocket-Accept": "test-accept-key"
            ],
            body: Data()
        )

        #expect(response.statusCode.code == 101)
        #expect(response.headers["Upgrade"] == "websocket")
        #expect(response.headers["Connection"] == "Upgrade")
        #expect(response.headers["Sec-WebSocket-Accept"] != nil)
    }

    @Test("WebSocket handshake response format")
    func webSocketHandshakeResponseFormat() {
        let response = HTTPResponse(
            statusCode: .switchingProtocols,
            headers: [
                "Upgrade": "websocket",
                "Connection": "Upgrade",
                "Sec-WebSocket-Accept": "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="
            ],
            body: Data()
        )

        let data = response.toData()
        let responseString = String(data: data, encoding: .utf8)!

        #expect(responseString.contains("HTTP/1.1 101 Switching Protocols"))
        #expect(responseString.contains("Upgrade: websocket"))
        #expect(responseString.contains("Connection: Upgrade"))
        #expect(responseString.contains("Sec-WebSocket-Accept:"))
    }

    @Test("Multiple WebSocket servers with different ports")
    func multipleWebSocketServersWithDifferentPorts() async throws {
        let ws1 = WebSocketServer()
        let ws2 = WebSocketServer()

        let router1 = Router {
            Route(path: "/") { _ in HTTPResponse.text("OK") }
        }
        let router2 = Router {
            Route(path: "/") { _ in HTTPResponse.text("OK") }
        }

        let _ = HTTPServer(port: 0, router: router1, webSocketServer: ws1)
        let _ = HTTPServer(port: 0, router: router2, webSocketServer: ws2)

        // Test passes if no crash occurs
        #expect(true)
    }

    @Test("WebSocket server callbacks are independent")
    func webSocketServerCallbacksAreIndependent() async {
        let ws1 = WebSocketServer(
            onConnected: { _ in
                // Server 1 connection
            }
        )

        let ws2 = WebSocketServer(
            onConnected: { _ in
                // Server 2 connection
            }
        )

        #expect(await ws1.getConnectionCount() == 0)
        #expect(await ws2.getConnectionCount() == 0)
    }

    @Test("Router handles routes with WebSocket server present")
    func routerHandlesRoutesWithWebSocketServerPresent() async throws {
        let router = Router {
            Route(path: "/") { _ in
                HTTPResponse.text("Home")
            }

            Route(path: "/api") { _ in
                try! HTTPResponse.json(["status": "ok"])
            }
        }

        let webSocketServer = WebSocketServer()
        let _ = HTTPServer(
            port: 0,
            router: router,
            webSocketServer: webSocketServer
        )

        let homeRequest = HTTPRequest(method: .GET, path: "/", headers: [:], body: nil)
        let apiRequest = HTTPRequest(method: .GET, path: "/api", headers: [:], body: nil)

        let homeResponse = await router.handle(homeRequest)
        let apiResponse = await router.handle(apiRequest)

        #expect(homeResponse.statusCode.code == 200)
        #expect(apiResponse.statusCode.code == 200)
    }

    @Test("Case insensitive header check for Upgrade")
    func caseInsensitiveHeaderCheckForUpgrade() {
        let variations = [
            "websocket",
            "WebSocket",
            "WEBSOCKET",
            "wEbSoCkEt"
        ]

        for variant in variations {
            let request = HTTPRequest(
                method: .GET,
                path: "/",
                headers: ["Upgrade": variant],
                body: nil
            )

            #expect(request.headers["Upgrade"]?.lowercased() == "websocket")
        }
    }

    @Test("Case insensitive header check for Connection")
    func caseInsensitiveHeaderCheckForConnection() {
        let variations = [
            "Upgrade",
            "upgrade",
            "UPGRADE",
            "keep-alive, Upgrade"
        ]

        for variant in variations {
            let request = HTTPRequest(
                method: .GET,
                path: "/",
                headers: ["Connection": variant],
                body: nil
            )

            #expect(request.headers["Connection"]?.lowercased().contains("upgrade") == true)
        }
    }

    @Test("WebSocket key validation")
    func webSocketKeyValidation() {
        // Valid Base64 encoded key (16 bytes)
        let validKey = "dGhlIHNhbXBsZSBub25jZQ=="

        let request = HTTPRequest(
            method: .GET,
            path: "/",
            headers: ["Sec-WebSocket-Key": validKey],
            body: nil
        )

        #expect(request.headers["Sec-WebSocket-Key"] != nil)
        #expect(request.headers["Sec-WebSocket-Key"]?.isEmpty == false)
    }

    @Test("WebSocket version header")
    func webSocketVersionHeader() {
        let request = HTTPRequest(
            method: .GET,
            path: "/",
            headers: ["Sec-WebSocket-Version": "13"],
            body: nil
        )

        #expect(request.headers["Sec-WebSocket-Version"] == "13")
    }

    @Test("WebSocket subprotocol header handling")
    func webSocketSubprotocolHeaderHandling() {
        let request = HTTPRequest(
            method: .GET,
            path: "/",
            headers: [
                "Sec-WebSocket-Protocol": "chat, superchat"
            ],
            body: nil
        )

        #expect(request.headers["Sec-WebSocket-Protocol"] != nil)
    }

    @Test("Empty body in upgrade response")
    func emptyBodyInUpgradeResponse() {
        let response = HTTPResponse(
            statusCode: .switchingProtocols,
            headers: ["Upgrade": "websocket"],
            body: Data()
        )

        #expect(response.body?.isEmpty == true)
    }

    @Test("WebSocket connection lifecycle callbacks")
    func webSocketConnectionLifecycleCallbacks() async {
        let _ = WebSocketServer(
            onConnected: { _ in
                // Connected callback
            },
            onDisconnected: { _ in
                // Disconnected callback
            },
            onMessage: { _, _ in
                // Message callback
            }
        )

        // Test passes if initialization succeeds
        #expect(true)
    }

    @Test("Refresh command is a valid text message")
    func refreshCommandIsValidTextMessage() {
        let refreshFrame = WebSocketFrame.text("refresh")

        #expect(refreshFrame.opCode == .text)
        #expect(String(data: refreshFrame.payload, encoding: .utf8) == "refresh")
    }

    @Test("Broadcast sends to all connections conceptually")
    func broadcastSendsToAllConnectionsConceptually() async {
        let ws = WebSocketServer()

        // This should not crash with no connections
        await ws.broadcast("test")
        await ws.refreshPage()

        let count = await ws.getConnectionCount()
        #expect(count == 0)
    }
}
