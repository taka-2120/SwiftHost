import Foundation

/// Represents a WebSocket frame according to RFC 6455.
struct WebSocketFrame {
    let fin: Bool
    let opCode: WebSocketOpCode
    let payload: Data

    /// Parses a WebSocket frame from raw data.
    ///
    /// - Parameter data: The raw frame data
    /// - Returns: A parsed WebSocketFrame and the number of bytes consumed
    /// - Throws: An error if the frame is invalid
    static func parse(from data: Data) throws -> (frame: WebSocketFrame, bytesRead: Int)? {
        guard data.count >= 2 else { return nil }

        var offset = 0
        let byte0 = data[offset]
        let byte1 = data[offset + 1]
        offset += 2

        let fin = (byte0 & 0x80) != 0
        let opCodeRaw = byte0 & 0x0F
        guard let opCode = WebSocketOpCode(rawValue: opCodeRaw) else {
            throw WebSocketError.invalidOpCode
        }

        let masked = (byte1 & 0x80) != 0
        var payloadLength = UInt64(byte1 & 0x7F)

        // Handle extended payload lengths
        if payloadLength == 126 {
            guard data.count >= offset + 2 else { return nil }
            payloadLength = UInt64(data[offset]) << 8 | UInt64(data[offset + 1])
            offset += 2
        } else if payloadLength == 127 {
            guard data.count >= offset + 8 else { return nil }
            payloadLength = 0
            for i in 0..<8 {
                payloadLength = payloadLength << 8 | UInt64(data[offset + i])
            }
            offset += 8
        }

        // Read mask key if present
        var maskKey: [UInt8]?
        if masked {
            guard data.count >= offset + 4 else { return nil }
            maskKey = Array(data[offset..<offset + 4])
            offset += 4
        }

        // Read payload
        guard data.count >= offset + Int(payloadLength) else { return nil }
        var payload = Data(data[offset..<offset + Int(payloadLength)])
        offset += Int(payloadLength)

        // Unmask payload if needed
        if let maskKey = maskKey {
            for i in 0..<payload.count {
                payload[i] ^= maskKey[i % 4]
            }
        }

        let frame = WebSocketFrame(fin: fin, opCode: opCode, payload: payload)
        return (frame, offset)
    }

    /// Creates frame data ready to send.
    ///
    /// - Returns: The serialized frame data
    func toData() -> Data {
        var data = Data()

        // Byte 0: FIN + opcode
        var byte0: UInt8 = opCode.rawValue
        if fin {
            byte0 |= 0x80
        }
        data.append(byte0)

        // Byte 1: Mask + payload length
        let payloadLength = payload.count
        var byte1: UInt8 = 0 // Server-to-client frames are not masked

        if payloadLength < 126 {
            byte1 |= UInt8(payloadLength)
            data.append(byte1)
        } else if payloadLength < 65536 {
            byte1 |= 126
            data.append(byte1)
            data.append(UInt8((payloadLength >> 8) & 0xFF))
            data.append(UInt8(payloadLength & 0xFF))
        } else {
            byte1 |= 127
            data.append(byte1)
            for i in stride(from: 56, through: 0, by: -8) {
                data.append(UInt8((payloadLength >> i) & 0xFF))
            }
        }

        // Payload
        data.append(payload)

        return data
    }

    /// Creates a text frame.
    ///
    /// - Parameter text: The text message to send
    /// - Returns: A WebSocket frame containing the text
    static func text(_ text: String) -> WebSocketFrame {
        let payload = text.data(using: .utf8) ?? Data()
        return WebSocketFrame(fin: true, opCode: .text, payload: payload)
    }

    /// Creates a close frame.
    ///
    /// - Returns: A WebSocket close frame
    static func close() -> WebSocketFrame {
        return WebSocketFrame(fin: true, opCode: .connectionClose, payload: Data())
    }

    /// Creates a pong frame in response to a ping.
    ///
    /// - Parameter payload: The payload from the ping frame
    /// - Returns: A WebSocket pong frame
    static func pong(payload: Data = Data()) -> WebSocketFrame {
        return WebSocketFrame(fin: true, opCode: .pong, payload: payload)
    }
}
