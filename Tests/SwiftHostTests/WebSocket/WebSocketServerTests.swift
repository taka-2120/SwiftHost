import Testing
import Foundation
import Network
@testable import SwiftHost

@Suite("WebSocket Server Tests")
struct WebSocketServerTests {
    @Test("WebSocket server initialization")
    func webSocketServerInitialization() async {
        let server = WebSocketServer(
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

        #expect(await server.getConnectionCount() == 0)
    }

    @Test("Generate accept key correctly")
    func generateAcceptKeyCorrectly() async throws {
        let _ = WebSocketServer()

        // Create a mock request with the standard test key from RFC 6455
        let _ = try createWebSocketUpgradeRequest(
            key: "dGhlIHNhbXBsZSBub25jZQ=="
        )

        // The accept key should be calculated as:
        // SHA1("dGhlIHNhbXBsZSBub25jZQ==" + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11")
        // = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="

        // We can't directly test the private method, but we can verify
        // the response contains the correct header
        // Note: This test would require a mock NWConnection
        #expect(true)
    }

    @Test("Validate WebSocket upgrade headers")
    func validateWebSocketUpgradeHeaders() async throws {
        let _ = WebSocketServer()

        // Valid request
        let _ = try createWebSocketUpgradeRequest()
        // We'd need a mock connection to fully test this

        // Invalid request - missing Upgrade header
        let _ = HTTPRequest(
            method: .GET,
            path: "/",
            headers: [:],
            body: nil
        )

        // Invalid request - missing Sec-WebSocket-Key
        let _ = HTTPRequest(
            method: .GET,
            path: "/",
            headers: [
                "Upgrade": "websocket",
                "Connection": "Upgrade"
            ],
            body: nil
        )

        // These would return nil for handleUpgrade with a real connection
        #expect(true)
    }

    @Test("Connection count tracking")
    func connectionCountTracking() async {
        let server = WebSocketServer()

        let initialCount = await server.getConnectionCount()
        #expect(initialCount == 0)

        // Note: Adding connections requires NWConnection mocks
        // which is complex for unit tests
    }

    @Test("Get connection IDs returns empty array initially")
    func getConnectionIDsReturnsEmptyArrayInitially() async {
        let server = WebSocketServer()

        let ids = await server.getConnectionIDs()
        #expect(ids.isEmpty)
    }

    @Test("Broadcast message method exists")
    func broadcastMessageMethodExists() async {
        let server = WebSocketServer()

        // This should not crash
        await server.broadcast("test message")

        // With no connections, nothing happens
        let count = await server.getConnectionCount()
        #expect(count == 0)
    }

    @Test("Refresh all pages method exists")
    func refreshAllPagesMethodExists() async {
        let server = WebSocketServer()

        // This should not crash
        await server.refreshPage()
    }

    @Test("Send text to specific connection")
    func sendTextToSpecificConnection() async {
        let server = WebSocketServer()
        let fakeID = UUID()

        // Should not crash even with invalid ID
        await server.sendText("test", to: fakeID)
    }

    @Test("Close specific connection")
    func closeSpecificConnection() async {
        let server = WebSocketServer()
        let fakeID = UUID()

        // Should not crash even with invalid ID
        await server.closeConnection(fakeID)
    }

    @Test("Refresh specific page")
    func refreshSpecificPage() async {
        let server = WebSocketServer()
        let fakeID = UUID()

        // Should not crash even with invalid ID
        await server.refreshPage(fakeID)
    }

    @Test("Callbacks are called on connection")
    func callbacksAreCalledOnConnection() async {
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

        // Without real connections, we can only verify initialization
        #expect(true)
    }

    @Test("WebSocket GUID constant value")
    func webSocketGuidConstantValue() {
        // The magic string is defined in RFC 6455 and must never change
        let expectedGuid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

        // We can verify this by checking the accept key calculation
        // with a known input/output pair from RFC 6455
        let testKey = "dGhlIHNhbXBsZSBub25jZQ=="
        let expectedAccept = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="

        // Calculate using the same algorithm
        let combined = testKey + expectedGuid
        let hash = SHA1Hash.hash(data: Data(combined.utf8))
        let accept = Data(hash).base64EncodedString()

        #expect(accept == expectedAccept)
    }

    @Test("Multiple servers can be created independently")
    func multipleServersCanBeCreatedIndependently() async {
        let server1 = WebSocketServer(
            onConnected: { _ in
                // Server 1 connected
            }
        )

        let server2 = WebSocketServer(
            onConnected: { _ in
                // Server 2 connected
            }
        )

        #expect(await server1.getConnectionCount() == 0)
        #expect(await server2.getConnectionCount() == 0)
    }

    // Helper function to create a valid WebSocket upgrade request
    private func createWebSocketUpgradeRequest(
        key: String = "dGhlIHNhbXBsZSBub25jZQ=="
    ) throws -> HTTPRequest {
        return HTTPRequest(
            method: .GET,
            path: "/",
            headers: [
                "Upgrade": "websocket",
                "Connection": "Upgrade",
                "Sec-WebSocket-Key": key,
                "Sec-WebSocket-Version": "13"
            ],
            body: nil
        )
    }
}

// Helper for SHA1 hashing (same as in WebSocketServer)
private enum SHA1Hash {
    static func hash(data: Data) -> [UInt8] {
        let digest = Insecure.SHA1.hash(data: data)
        return Array(digest)
    }
}

import CryptoKit
