import Testing
import Foundation
@testable import SwiftHost

@Suite("WebSocket Frame Tests")
struct WebSocketFrameTests {
    @Test("Parse text frame without mask")
    func parseTextFrameWithoutMask() throws {
        // Text frame: "Hello"
        var data = Data()
        data.append(0x81) // FIN + Text opcode
        data.append(0x05) // No mask + length 5
        data.append(contentsOf: "Hello".utf8)

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, bytesRead) = result!
        #expect(frame.fin == true)
        #expect(frame.opCode == .text)
        #expect(String(data: frame.payload, encoding: .utf8) == "Hello")
        #expect(bytesRead == 7)
    }

    @Test("Parse text frame with mask")
    func parseTextFrameWithMask() throws {
        // Masked text frame: "Test"
        var data = Data()
        data.append(0x81) // FIN + Text opcode
        data.append(0x84) // Mask + length 4

        // Mask key
        let maskKey: [UInt8] = [0x37, 0xFA, 0x21, 0x3D]
        data.append(contentsOf: maskKey)

        // Masked payload
        let original = "Test".utf8.map { UInt8($0) }
        let masked = original.enumerated().map { $0.element ^ maskKey[$0.offset % 4] }
        data.append(contentsOf: masked)

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, bytesRead) = result!
        #expect(frame.fin == true)
        #expect(frame.opCode == .text)
        #expect(String(data: frame.payload, encoding: .utf8) == "Test")
        #expect(bytesRead == 10)
    }

    @Test("Parse ping frame")
    func parsePingFrame() throws {
        var data = Data()
        data.append(0x89) // FIN + Ping opcode
        data.append(0x00) // No mask + length 0

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, bytesRead) = result!
        #expect(frame.fin == true)
        #expect(frame.opCode == .ping)
        #expect(frame.payload.isEmpty)
        #expect(bytesRead == 2)
    }

    @Test("Parse pong frame")
    func parsePongFrame() throws {
        var data = Data()
        data.append(0x8A) // FIN + Pong opcode
        data.append(0x00) // No mask + length 0

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, _) = result!
        #expect(frame.opCode == .pong)
    }

    @Test("Parse close frame")
    func parseCloseFrame() throws {
        var data = Data()
        data.append(0x88) // FIN + Close opcode
        data.append(0x00) // No mask + length 0

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, _) = result!
        #expect(frame.opCode == .connectionClose)
    }

    @Test("Parse frame with extended payload length (126)")
    func parseFrameWithExtendedLength126() throws {
        // Frame with length 126 (requires 2 extra bytes)
        var data = Data()
        data.append(0x81) // FIN + Text opcode
        data.append(0x7E) // No mask + extended length indicator
        data.append(0x00) // Length high byte
        data.append(0x7E) // Length low byte (126)

        let payload = String(repeating: "x", count: 126)
        data.append(contentsOf: payload.utf8)

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, bytesRead) = result!
        #expect(frame.payload.count == 126)
        #expect(bytesRead == 4 + 126)
    }

    @Test("Parse frame with extended payload length (127)")
    func parseFrameWithExtendedLength127() throws {
        // Frame with length > 65535 (requires 8 extra bytes)
        var data = Data()
        data.append(0x81) // FIN + Text opcode
        data.append(0x7F) // No mask + extended length indicator

        // 8 bytes for length (only using last byte for this test)
        let length: UInt64 = 200
        for i in stride(from: 56, through: 0, by: -8) {
            data.append(UInt8((length >> i) & 0xFF))
        }

        let payload = String(repeating: "y", count: 200)
        data.append(contentsOf: payload.utf8)

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, bytesRead) = result!
        #expect(frame.payload.count == 200)
        #expect(bytesRead == 10 + 200)
    }

    @Test("Parse returns nil for incomplete frame")
    func parseReturnsNilForIncompleteFrame() throws {
        var data = Data()
        data.append(0x81) // FIN + Text opcode
        // Missing length byte

        let result = try WebSocketFrame.parse(from: data)
        #expect(result == nil)
    }

    @Test("Parse returns nil for incomplete payload")
    func parseReturnsNilForIncompletePayload() throws {
        var data = Data()
        data.append(0x81) // FIN + Text opcode
        data.append(0x05) // Length 5
        data.append(contentsOf: "Hi".utf8) // Only 2 bytes instead of 5

        let result = try WebSocketFrame.parse(from: data)
        #expect(result == nil)
    }

    @Test("Create text frame and serialize")
    func createTextFrameAndSerialize() {
        let frame = WebSocketFrame.text("Hello")

        #expect(frame.fin == true)
        #expect(frame.opCode == .text)
        #expect(String(data: frame.payload, encoding: .utf8) == "Hello")
    }

    @Test("Serialize text frame to data")
    func serializeTextFrameToData() {
        let frame = WebSocketFrame.text("Hi")
        let data = frame.toData()

        #expect(data.count == 4) // 2 header bytes + 2 payload bytes
        #expect(data[0] == 0x81) // FIN + Text
        #expect(data[1] == 0x02) // Length 2
        #expect(data[2] == UInt8(ascii: "H"))
        #expect(data[3] == UInt8(ascii: "i"))
    }

    @Test("Serialize close frame to data")
    func serializeCloseFrameToData() {
        let frame = WebSocketFrame.close()
        let data = frame.toData()

        #expect(data.count == 2)
        #expect(data[0] == 0x88) // FIN + Close
        #expect(data[1] == 0x00) // Length 0
    }

    @Test("Serialize pong frame to data")
    func serializePongFrameToData() {
        let frame = WebSocketFrame.pong()
        let data = frame.toData()

        #expect(data[0] == 0x8A) // FIN + Pong
        #expect(data[1] == 0x00) // Length 0
    }

    @Test("Serialize frame with 126 byte payload")
    func serializeFrameWith126BytePayload() {
        let payload = String(repeating: "x", count: 126)
        let frame = WebSocketFrame.text(payload)
        let data = frame.toData()

        #expect(data[0] == 0x81) // FIN + Text
        #expect(data[1] == 0x7E) // Extended length indicator
        #expect(data[2] == 0x00) // Length high byte
        #expect(data[3] == 0x7E) // Length low byte (126)
        #expect(data.count == 4 + 126)
    }

    @Test("Serialize frame with large payload")
    func serializeFrameWithLargePayload() {
        let payload = String(repeating: "x", count: 70000)
        let frame = WebSocketFrame.text(payload)
        let data = frame.toData()

        #expect(data[0] == 0x81) // FIN + Text
        #expect(data[1] == 0x7F) // 64-bit length indicator
        #expect(data.count == 10 + 70000)
    }

    @Test("Round trip: serialize and parse")
    func roundTripSerializeAndParse() throws {
        let original = WebSocketFrame.text("Round trip test")
        let serialized = original.toData()

        let result = try WebSocketFrame.parse(from: serialized)
        #expect(result != nil)

        let (parsed, _) = result!
        #expect(parsed.fin == original.fin)
        #expect(parsed.opCode == original.opCode)
        #expect(parsed.payload == original.payload)
    }

    @Test("Parse multiple frames from buffer")
    func parseMultipleFramesFromBuffer() throws {
        var buffer = Data()

        // Add two text frames
        let frame1 = WebSocketFrame.text("First")
        let frame2 = WebSocketFrame.text("Second")
        buffer.append(frame1.toData())
        buffer.append(frame2.toData())

        // Parse first frame
        let result1 = try WebSocketFrame.parse(from: buffer)
        #expect(result1 != nil)
        let (parsed1, bytesRead1) = result1!
        #expect(String(data: parsed1.payload, encoding: .utf8) == "First")

        // Remove first frame from buffer
        buffer.removeFirst(bytesRead1)

        // Parse second frame
        let result2 = try WebSocketFrame.parse(from: buffer)
        #expect(result2 != nil)
        let (parsed2, _) = result2!
        #expect(String(data: parsed2.payload, encoding: .utf8) == "Second")
    }

    @Test("Parse binary frame")
    func parseBinaryFrame() throws {
        var data = Data()
        data.append(0x82) // FIN + Binary opcode
        data.append(0x04) // Length 4
        data.append(contentsOf: [0x01, 0x02, 0x03, 0x04])

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, _) = result!
        #expect(frame.opCode == .binary)
        #expect(frame.payload == Data([0x01, 0x02, 0x03, 0x04]))
    }

    @Test("Parse continuation frame")
    func parseContinuationFrame() throws {
        var data = Data()
        data.append(0x00) // No FIN + Continuation opcode
        data.append(0x03) // Length 3
        data.append(contentsOf: "abc".utf8)

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, _) = result!
        #expect(frame.fin == false)
        #expect(frame.opCode == .continuation)
    }

    @Test("Serialize and parse empty text frame")
    func serializeAndParseEmptyTextFrame() throws {
        let frame = WebSocketFrame.text("")
        let data = frame.toData()

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (parsed, _) = result!
        #expect(parsed.payload.isEmpty)
        #expect(String(data: parsed.payload, encoding: .utf8) == "")
    }

    @Test("Parse frame with UTF-8 multibyte characters")
    func parseFrameWithUtf8MultibyteCharacters() throws {
        let text = "Hello 世界 🌍"
        var data = Data()
        let payload = text.data(using: .utf8)!

        data.append(0x81) // FIN + Text
        data.append(UInt8(payload.count)) // Length
        data.append(payload)

        let result = try WebSocketFrame.parse(from: data)
        #expect(result != nil)

        let (frame, _) = result!
        #expect(String(data: frame.payload, encoding: .utf8) == text)
    }
}
