/// Errors that can occur during WebSocket operations.
enum WebSocketError: Error {
    /// The WebSocket frame contains an unrecognized or invalid operation code.
    case invalidOpCode
    /// The WebSocket handshake failed or was malformed.
    case invalidHandshake
    /// The WebSocket connection has been closed.
    case connectionClosed
}
