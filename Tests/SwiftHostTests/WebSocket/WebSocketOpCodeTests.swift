import Testing
import Foundation
@testable import SwiftHost

@Suite("WebSocket OpCode Tests")
struct WebSocketOpCodeTests {
    @Test("Continuation opcode value")
    func continuationOpcodeValue() {
        let opCode = WebSocketOpCode.continuation
        #expect(opCode.rawValue == 0x0)
    }

    @Test("Text opcode value")
    func textOpcodeValue() {
        let opCode = WebSocketOpCode.text
        #expect(opCode.rawValue == 0x1)
    }

    @Test("Binary opcode value")
    func binaryOpcodeValue() {
        let opCode = WebSocketOpCode.binary
        #expect(opCode.rawValue == 0x2)
    }

    @Test("Connection close opcode value")
    func connectionCloseOpcodeValue() {
        let opCode = WebSocketOpCode.connectionClose
        #expect(opCode.rawValue == 0x8)
    }

    @Test("Ping opcode value")
    func pingOpcodeValue() {
        let opCode = WebSocketOpCode.ping
        #expect(opCode.rawValue == 0x9)
    }

    @Test("Pong opcode value")
    func pongOpcodeValue() {
        let opCode = WebSocketOpCode.pong
        #expect(opCode.rawValue == 0xA)
    }

    @Test("Create opcode from raw value")
    func createOpcodeFromRawValue() {
        #expect(WebSocketOpCode(rawValue: 0x0) == .continuation)
        #expect(WebSocketOpCode(rawValue: 0x1) == .text)
        #expect(WebSocketOpCode(rawValue: 0x2) == .binary)
        #expect(WebSocketOpCode(rawValue: 0x8) == .connectionClose)
        #expect(WebSocketOpCode(rawValue: 0x9) == .ping)
        #expect(WebSocketOpCode(rawValue: 0xA) == .pong)
    }

    @Test("Invalid opcode returns nil")
    func invalidOpcodeReturnsNil() {
        #expect(WebSocketOpCode(rawValue: 0x3) == nil)
        #expect(WebSocketOpCode(rawValue: 0x7) == nil)
        #expect(WebSocketOpCode(rawValue: 0xB) == nil)
        #expect(WebSocketOpCode(rawValue: 0xF) == nil)
    }

    @Test("OpCode equality")
    func opCodeEquality() {
        #expect(WebSocketOpCode.text == WebSocketOpCode.text)
        #expect(WebSocketOpCode.ping == WebSocketOpCode.ping)
        #expect(WebSocketOpCode.text != WebSocketOpCode.binary)
        #expect(WebSocketOpCode.ping != WebSocketOpCode.pong)
    }

    @Test("All defined opcodes are unique")
    func allDefinedOpcodesAreUnique() {
        let opcodes: [WebSocketOpCode] = [
            .continuation,
            .text,
            .binary,
            .connectionClose,
            .ping,
            .pong
        ]

        let rawValues = opcodes.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)

        #expect(rawValues.count == uniqueRawValues.count)
    }

    @Test("Control frame opcodes are in correct range")
    func controlFrameOpcodesAreInCorrectRange() {
        // Control frames have opcodes >= 0x8
        #expect(WebSocketOpCode.connectionClose.rawValue >= 0x8)
        #expect(WebSocketOpCode.ping.rawValue >= 0x8)
        #expect(WebSocketOpCode.pong.rawValue >= 0x8)
    }

    @Test("Data frame opcodes are in correct range")
    func dataFrameOpcodesAreInCorrectRange() {
        // Data frames have opcodes < 0x8
        #expect(WebSocketOpCode.continuation.rawValue < 0x8)
        #expect(WebSocketOpCode.text.rawValue < 0x8)
        #expect(WebSocketOpCode.binary.rawValue < 0x8)
    }

    @Test("OpCode fits in 4 bits")
    func opCodeFitsIn4Bits() {
        let opcodes: [WebSocketOpCode] = [
            .continuation,
            .text,
            .binary,
            .connectionClose,
            .ping,
            .pong
        ]

        for opcode in opcodes {
            #expect(opcode.rawValue <= 0x0F)
        }
    }
}
