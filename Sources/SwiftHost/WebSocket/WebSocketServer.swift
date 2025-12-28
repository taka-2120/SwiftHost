import Network
import Foundation

/// Manages WebSocket connections and provides callbacks for connection events.
public actor WebSocketServer {
    private let magicString = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    private var connections: [UUID: WebSocketConnection] = [:]
    private let onConnected: @Sendable (UUID) -> Void
    private let onDisconnected: @Sendable (UUID) -> Void
    private let onMessage: @Sendable (UUID, String) -> Void

    /// Creates a new WebSocket server.
    ///
    /// - Parameters:
    ///   - onConnected: Callback when a client connects (receives connection ID)
    ///   - onDisconnected: Callback when a client disconnects (receives connection ID)
    ///   - onMessage: Callback when a message is received (receives connection ID and message)
    public init(
        onConnected: @escaping @Sendable (UUID) -> Void = { _ in },
        onDisconnected: @escaping @Sendable (UUID) -> Void = { _ in },
        onMessage: @escaping @Sendable (UUID, String) -> Void = { _, _ in }
    ) {
        self.onConnected = onConnected
        self.onDisconnected = onDisconnected
        self.onMessage = onMessage
    }

    /// Handles a WebSocket upgrade request.
    ///
    /// - Parameters:
    ///   - request: The HTTP upgrade request
    ///   - connection: The network connection to upgrade
    /// - Returns: An HTTP response for the upgrade, or nil if the upgrade fails
    func handleUpgrade(request: HTTPRequest, connection: NWConnection) async -> HTTPResponse? {
        // Validate WebSocket upgrade headers
        guard request.headers["Upgrade"]?.lowercased() == "websocket",
              request.headers["Connection"]?.lowercased().contains("upgrade") == true,
              let key = request.headers["Sec-WebSocket-Key"] else {
            return nil
        }

        // Generate accept key
        let acceptKey = generateAcceptKey(from: key)

        // Generate connection ID upfront to avoid capture issues
        let connectionID = UUID()

        // Create WebSocket connection
        let wsConnection = WebSocketConnection(
            id: connectionID,
            connection: connection,
            onMessage: { [weak self] message in
                self?.onMessage(connectionID, message)
            },
            onClose: { [weak self] in
                Task { [weak self] in
                    await self?.removeConnection(connectionID)
                }
            }
        )

        connections[connectionID] = wsConnection

        // Start receiving frames
        await wsConnection.startReceiving()

        // Notify about connection
        onConnected(connectionID)

        // Return upgrade response
        var headers: [String: String] = [
            "Upgrade": "websocket",
            "Connection": "Upgrade",
            "Sec-WebSocket-Accept": acceptKey
        ]

        if let subProtocol = request.headers["Sec-WebSocket-Protocol"] {
            headers["Sec-WebSocket-Protocol"] = subProtocol
        }

        return HTTPResponse(
            statusCode: .switchingProtocols,
            headers: headers,
            body: Data()
        )
    }

    /// Generates the WebSocket accept key from the client key.
    ///
    /// - Parameter key: The client's Sec-WebSocket-Key
    /// - Returns: The computed Sec-WebSocket-Accept value
    private func generateAcceptKey(from key: String) -> String {
        let combined = key + magicString
        let hash = SHA1.hash(data: Data(combined.utf8))
        return Data(hash).base64EncodedString()
    }

    /// Sends a text message to a specific connection.
    ///
    /// - Parameters:
    ///   - text: The text to send
    ///   - connectionID: The ID of the connection to send to
    public func sendText(_ text: String, to connectionID: UUID? = nil) async {
        if let connectionID {
            guard let connection = connections[connectionID] else { return }
            await connection.sendText(text)
            return
        }

        for connection in connections.values {
            await connection.sendText(text)
        }
    }

    /// Broadcasts a text message to all connected clients.
    ///
    /// - Parameter text: The text to broadcast
    public func broadcast(_ text: String) async {
        for connection in connections.values {
            await connection.sendText(text)
        }
    }

    /// Sends a refresh command to a specific web page or all connected pages.
    ///
    /// - Parameter connectionID: The ID of the connection to refresh, or nil to refresh all
    public func refreshPage(_ connectionID: UUID? = nil) async {
        if let connectionID {
            await sendText("refresh", to: connectionID)
            return
        }

        await broadcast("refresh")
    }

    /// Closes a specific connection.
    ///
    /// - Parameter connectionID: The ID of the connection to close
    public func closeConnection(_ connectionID: UUID? = nil) async {
        if let connectionID {
            guard let connection = connections[connectionID] else { return }
            await connection.close()
            return
        }

        for connection in connections.values {
            await connection.close()
        }
    }

    /// Removes a connection from the active connections.
    ///
    /// - Parameter connectionID: The ID of the connection to remove
    private func removeConnection(_ connectionID: UUID) async {
        connections.removeValue(forKey: connectionID)
        onDisconnected(connectionID)
    }

    /// Gets the number of active connections.
    ///
    /// - Returns: The count of active connections
    public func getConnectionCount() -> Int {
        return connections.count
    }

    /// Gets all active connection IDs.
    ///
    /// - Returns: An array of connection IDs
    public func getConnectionIDs() -> [UUID] {
        return Array(connections.keys)
    }
}
