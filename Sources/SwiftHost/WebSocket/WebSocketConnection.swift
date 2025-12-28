import Network
import Foundation

/// Represents a single WebSocket connection.
public actor WebSocketConnection {
    public let id: UUID
    private let connection: NWConnection
    private var isOpen = true
    private var receiveTask: Task<Void, Never>?
    private let onMessage: @Sendable (String) -> Void
    private let onClose: @Sendable () -> Void

    /// Creates a new WebSocket connection.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this connection
    ///   - connection: The underlying network connection
    ///   - onMessage: Callback when a text message is received
    ///   - onClose: Callback when the connection closes
    init(
        id: UUID = UUID(),
        connection: NWConnection,
        onMessage: @escaping @Sendable (String) -> Void = { _ in },
        onClose: @escaping @Sendable () -> Void = {}
    ) {
        self.id = id
        self.connection = connection
        self.onMessage = onMessage
        self.onClose = onClose
    }

    /// Starts receiving WebSocket frames.
    func startReceiving() {
        receiveTask = Task {
            await receiveLoop()
        }
    }

    /// Main receive loop for processing incoming frames.
    private func receiveLoop() async {
        var buffer = Data()

        while isOpen && !Task.isCancelled {
            do {
                guard let data = try await receiveData() else {
                    break
                }

                buffer.append(data)

                // Try to parse frames from buffer
                while let (frame, bytesRead) = try WebSocketFrame.parse(from: buffer) {
                    buffer.removeFirst(bytesRead)
                    try await handleFrame(frame)
                }
            } catch {
                break
            }
        }

        await close()
    }

    /// Handles a received WebSocket frame.
    ///
    /// - Parameter frame: The frame to handle
    private func handleFrame(_ frame: WebSocketFrame) async throws {
        switch frame.opCode {
        case .text:
            if let text = String(data: frame.payload, encoding: .utf8) {
                onMessage(text)
            }

        case .binary:
            // Binary messages not handled in this implementation
            break

        case .connectionClose:
            await close()

        case .ping:
            let pongFrame = WebSocketFrame.pong(payload: frame.payload)
            await send(frame: pongFrame)

        case .pong:
            // Pong received, no action needed
            break

        case .continuation:
            // Continuation frames not handled in this simple implementation
            break
        }
    }

    /// Receives data from the connection.
    ///
    /// - Returns: The received data, or nil if connection closed
    private func receiveData() async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            connection.receive(
                minimumIncompleteLength: 1,
                maximumLength: connection.maximumDatagramSize
            ) { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let data {
                    continuation.resume(returning: data)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    /// Sends a WebSocket frame.
    ///
    /// - Parameter frame: The frame to send
    private func send(frame: WebSocketFrame) async {
        guard isOpen else { return }

        let data = frame.toData()
        await withCheckedContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { _ in
                continuation.resume()
            })
        }
    }

    /// Sends a text message to the client.
    ///
    /// - Parameter text: The text message to send
    public func sendText(_ text: String) async {
        let frame = WebSocketFrame.text(text)
        await send(frame: frame)
    }

    /// Closes the WebSocket connection.
    public func close() async {
        guard isOpen else { return }
        isOpen = false

        let closeFrame = WebSocketFrame.close()
        await send(frame: closeFrame)

        receiveTask?.cancel()
        connection.cancel()
        onClose()
    }

    /// Checks if the connection is still open.
    ///
    /// - Returns: True if the connection is open
    public func isConnectionOpen() -> Bool {
        return isOpen
    }
}
