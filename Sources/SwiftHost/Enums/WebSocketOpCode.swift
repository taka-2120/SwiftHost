import Foundation

/// WebSocket frame operation codes as defined in RFC 6455.
public enum WebSocketOpCode: UInt8 {
    case continuation = 0x0
    case text = 0x1
    case binary = 0x2
    case connectionClose = 0x8
    case ping = 0x9
    case pong = 0xA
}
