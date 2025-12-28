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

        let byte0 = data[data.startIndex]
        let byte1 = data[data.startIndex + 1]
        var offset = 2

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
            let idx = data.startIndex + offset
            payloadLength = UInt64(data[idx]) << 8 | UInt64(data[idx + 1])
            offset += 2
        } else if payloadLength == 127 {
            guard data.count >= offset + 8 else { return nil }
            payloadLength = 0
            for i in 0..<8 {
                let idx = data.startIndex + offset + i
                payloadLength = payloadLength << 8 | UInt64(data[idx])
            }
            offset += 8
        }

        // Read mask key if present
        var maskKey: [UInt8]?
        if masked {
            guard data.count >= offset + 4 else { return nil }
            let startIdx = data.startIndex + offset
            maskKey = Array(data[startIdx..<startIdx + 4])
            offset += 4
        }

        // Read payload
        let payloadSize = Int(payloadLength)
        guard payloadSize >= 0, data.count >= offset + payloadSize else { return nil }
        let startIdx = data.startIndex + offset
        var payload = Data(data[startIdx..<startIdx + payloadSize])
        offset += payloadSize

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
