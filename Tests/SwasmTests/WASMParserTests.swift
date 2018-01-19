@testable import Swasm
import XCTest

class WASMParserTests: XCTestCase {}

extension WASMParserTests {
    func testVector() {
        expect(WASMParser.vector(of: WASMParser.byte(0x01)), ByteStream(bytes: [0x01]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.vector(of: WASMParser.byte(0x01)), ByteStream(bytes: [0x00]),
               toBe: ParserStreamError<ByteStream>.vectorInvalidLength(0, location: 0))

        expect(WASMParser.vector(of: WASMParser.byte(0x01)), ByteStream(bytes: [0x02, 0x01, 0x01]),
               toBe: [0x01, 0x01])
    }

    func testByte() {
        expect(WASMParser.byte(0x01), ByteStream(bytes: [0x01]),
               toBe: 0x01)

        expect(WASMParser.byte(0x01), ByteStream(bytes: []),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.byte(0x01), ByteStream(bytes: [0x02]),
               toBe: ParserStreamError<ByteStream>.unexpected(0x02, location: 0))
    }

    func testByteInRange() {
        expect(WASMParser.byte(in: 0x01 ..< 0x03), ByteStream(bytes: [0x02]),
               toBe: 0x02)

        expect(WASMParser.byte(in: 0x01 ..< 0x03), ByteStream(bytes: [0x02]),
               toBe: 0x02)

        expect(WASMParser.byte(in: 0x01 ..< 0x03), ByteStream(bytes: []),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.byte(in: 0x01 ..< 0x03), ByteStream(bytes: [0x00]),
               toBe: ParserStreamError<ByteStream>.unexpected(0x00, location: 0))
    }

    func testByteInSet() {
        expect(WASMParser.byte(in: Set([0x01, 0x02, 0x03])), ByteStream(bytes: [0x02]),
               toBe: 0x02)

        expect(WASMParser.byte(in: Set([0x01, 0x02, 0x03])), ByteStream(bytes: []),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.byte(in: Set([0x01, 0x02, 0x03])), ByteStream(bytes: [0x00]),
               toBe: ParserStreamError<ByteStream>.unexpected(0x00, location: 0))
    }

    func testBytes() {
        expect(WASMParser.bytes([0x01, 0x02, 0x03]), ByteStream(bytes: [0x01]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.bytes([0x01, 0x02, 0x03]), ByteStream(bytes: [0x01, 0x02, 0x03]),
               toBe: [0x01, 0x02, 0x03])

        expect(WASMParser.bytes([0x01, 0x02, 0x03]), ByteStream(bytes: [0x01, 0x09]),
               toBe: ParserStreamError<ByteStream>.unexpected(0x09, location: 1))
    }
}

extension WASMParserTests {
    func testUInt() {
        expect(WASMParser.uint(8), ByteStream(bytes: [0b0111_1111]),
               toBe: 0b0111_1111)

        expect(WASMParser.uint(8), ByteStream(bytes: [0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.uint(8), ByteStream(bytes: [0b1000_0000, 0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpected(0b1000_0000, location: 1))

        expect(WASMParser.uint(1), ByteStream(bytes: [0b1000_0000, 0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpected(0b1000_0000, location: 0))

        expect(WASMParser.uint(8), ByteStream(bytes: [0b1000_0010, 0b0000_0001]),
               toBe: 0b00_0000_1000_0010)

        expect(WASMParser.uint(16), ByteStream(bytes: [0b1000_0011, 0b1000_0010, 0b0000_0001]),
               toBe: 0b0_0000_0100_0001_0000_0011)
    }

    func testSInt() {
        expect(WASMParser.sint(8), ByteStream(bytes: [0b0100_0001]),
               toBe: -0b0011_1111)

        expect(WASMParser.sint(8), ByteStream(bytes: [0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.sint(8), ByteStream(bytes: [0b1000_0000, 0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpected(0b1000_0000, location: 1))

        expect(WASMParser.sint(1), ByteStream(bytes: [0b1000_0000, 0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpected(0b1000_0000, location: 0))

        expect(WASMParser.sint(8), ByteStream(bytes: [0b1000_0000, 0b0111_1111]),
               toBe: -0b1000_0000)

        expect(WASMParser.sint(16), ByteStream(bytes: [0b1100_0010, 0b1100_0001, 0b0111_1111]),
               toBe: -0b01_1111_0011_1110)
    }

    func testInt() {
        expect(WASMParser.int(8), ByteStream(bytes: [0b0100_0001]),
               toBe: -0b0011_1111)

        expect(WASMParser.int(8), ByteStream(bytes: [0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.int(8), ByteStream(bytes: [0b1000_0000, 0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpected(0b1000_0000, location: 1))

        expect(WASMParser.int(1), ByteStream(bytes: [0b1000_0000, 0b1000_0000]),
               toBe: ParserStreamError<ByteStream>.unexpected(0b1000_0000, location: 0))

        expect(WASMParser.int(8), ByteStream(bytes: [0b1000_0000, 0b0111_1111]),
               toBe: -0b1000_0000)

        expect(WASMParser.int(16), ByteStream(bytes: [0b1100_0010, 0b1100_0001, 0b0111_1111]),
               toBe: -0b01_1111_0011_1110)

        expect(WASMParser.int(64), ByteStream(bytes: [0x81, 0x80, 0x80, 0x80, 0x10]),
               toBe: 4_294_967_297)
    }
}

extension WASMParserTests {
    func testFloat32() {
        expect(WASMParser.float32(), ByteStream(bytes: [0b1111_1111, 0b1111_1111]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.float32(), ByteStream(bytes: [0b0011_1111, 0b1000_0000, 0b0000_0000, 0b0000_0000]),
               toBe: 1.0)

        expect(WASMParser.float32(), ByteStream(bytes: [0b0100_0000, 0b0100_1001, 0b0000_1111, 0b1101_1010]),
               toBe: .pi)
    }

    func testFloat64() {
        expect(WASMParser.float64(), ByteStream(bytes: [
            0b1111_1111, 0b1111_1111, 0b1111_1111, 0b1111_1111,
        ]), toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.float64(), ByteStream(bytes: [
            0b0011_1111, 0b1111_0000, 0b0000_0000, 0b0000_0000,
            0b0000_0000, 0b0000_0000, 0b0000_0000, 0b0000_0000,
        ]), toBe: 1.0)

        expect(WASMParser.float64(), ByteStream(bytes: [
            0b0100_0000, 0b0000_1001, 0b0010_0001, 0b1111_1011,
            0b0101_0100, 0b0100_0100, 0b0010_1101, 0b0001_1000,
        ]), toBe: .pi)
    }
}

extension WASMParserTests {
    func testUnicode() {
        expect(WASMParser.name(), ByteStream(bytes: [0x01, 0x61]),
               toBe: "a")

        expect(WASMParser.name(), ByteStream(bytes: [0x01]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.name(), ByteStream(bytes: [0x02, 0xC3, 0xA6]),
               toBe: "æ")

        expect(WASMParser.name(), ByteStream(bytes: [0x02, 0xC3]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.name(), ByteStream(bytes: [0x03, 0xE3, 0x81, 0x82]),
               toBe: "あ")

        expect(WASMParser.name(), ByteStream(bytes: [0x03, 0xE3, 0x81]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.name(), ByteStream(bytes: [0x04, 0xF0, 0x9F, 0x8D, 0xA3]),
               toBe: "🍣")

        expect(WASMParser.name(), ByteStream(bytes: [0x04, 0xF0, 0x9F, 0x8D]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)
    }

    func testName() {
        expect(WASMParser.name(), ByteStream(bytes: [
            0x09, 0xE3, 0x81, 0x82, 0xE3, 0x81, 0x84, 0xE3, 0x81, 0x86,
        ]), toBe: "あいう")
    }
}

extension WASMParserTests {
    func testValueType() {
        expect(WASMParser.valueType(), ByteStream(bytes: []),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.valueType(), ByteStream(bytes: [0x7F]),
               toBe: Int32.self)

        expect(WASMParser.valueType(), ByteStream(bytes: [0x7E]),
               toBe: Int64.self)

        expect(WASMParser.valueType(), ByteStream(bytes: [0x7D]),
               toBe: Float32.self)

        expect(WASMParser.valueType(), ByteStream(bytes: [0x7C]),
               toBe: Float64.self)

        expect(WASMParser.valueType(), ByteStream(bytes: [0x7B]),
               toBe: ParserStreamError<ByteStream>.unexpected(0x7B, location: 0))
    }

    func testResultType() {
        expect(WASMParser.resultType(), ByteStream(bytes: []),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.resultType(), ByteStream(bytes: [0x40]),
               toBe: [])

        expect(WASMParser.resultType(), ByteStream(bytes: [0x7F]),
               toBe: [Int32.self])

        expect(WASMParser.resultType(), ByteStream(bytes: [0x7E]),
               toBe: [Int64.self])

        expect(WASMParser.resultType(), ByteStream(bytes: [0x7D]),
               toBe: [Float32.self])

        expect(WASMParser.resultType(), ByteStream(bytes: [0x7C]),
               toBe: [Float64.self])

        expect(WASMParser.resultType(), ByteStream(bytes: [0x7B]),
               toBe: ParserStreamError<ByteStream>.unexpected(0x7B, location: 0))
    }

    func testFunctionType() {
        expect(WASMParser.functionType(), ByteStream(bytes: [0x60, 0x01, 0x7E, 0x01, 0x7D]),
               toBe: FunctionType(parameters: [Int64.self], results: [Float32.self]))
    }

    func testLimits() {
        expect(WASMParser.limits(), ByteStream(bytes: [0x00, 0x01]),
               toBe: Limits(min: 1, max: nil))

        expect(WASMParser.limits(), ByteStream(bytes: [0x01, 0x01, 0x02]),
               toBe: Limits(min: 1, max: 0x02))
    }

    func testMemoryType() {
        expect(WASMParser.memoryType(), ByteStream(bytes: [0x00, 0x01]),
               toBe: MemoryType(min: 1, max: nil))

        expect(WASMParser.memoryType(), ByteStream(bytes: [0x01, 0x01, 0x02]),
               toBe: MemoryType(min: 1, max: 0x02))
    }

    func testTableType() {
        expect(WASMParser.tableType(), ByteStream(bytes: [0x70, 0x00, 0x01]),
               toBe: TableType(limits: Limits(min: 1, max: nil)))

        expect(WASMParser.tableType(), ByteStream(bytes: [0x70, 0x01, 0x01, 0x02]),
               toBe: TableType(limits: Limits(min: 1, max: 0x02)))
    }

    func testGlobalType() {
        expect(WASMParser.globalType(), ByteStream(bytes: [0x7F, 0x00]),
               toBe: GlobalType(mutability: .constant, valueType: Int32.self))

        expect(WASMParser.globalType(), ByteStream(bytes: [0x7F, 0x01]),
               toBe: GlobalType(mutability: .variable, valueType: Int32.self))
    }
}

extension WASMParserTests {
    func testExpression() {
        expect(WASMParser.expression(), ByteStream(bytes: [0x00]),
               toBe: ParserStreamError<ByteStream>.unexpectedEnd)

        expect(WASMParser.expression(), ByteStream(bytes: [0x01, 0x0B]),
               toBe: Expression(instructions: [ControlInstruction.nop, PseudoInstruction.end]))

        expect(WASMParser.expression(), ByteStream(bytes: [0x02, 0x40, 0x01, 0x0B, 0x0B]),
               toBe: Expression(instructions: [
                   ControlInstruction.block([], [
                       ControlInstruction.nop,
                       PseudoInstruction.end,
                   ]),
                   PseudoInstruction.end,
        ]))

        expect(WASMParser.expression(), ByteStream(bytes: [
            0x41, 0x00, 0x41, 0x00, 0x28, 0x02, 0x04, 0x41, 0x10, 0x6B, 0x22,
            0x01, 0x36, 0x02, 0x04, 0x20, 0x01, 0x20, 0x00, 0x36, 0x02, 0x08, 0x02, 0x40, 0x02, 0x40, 0x20,
            0x00, 0x41, 0x01, 0x4A, 0x0D, 0x00, 0x20, 0x01, 0x41, 0x01, 0x36, 0x02, 0x0C, 0x0C, 0x01, 0x0B,
            0x20, 0x01, 0x20, 0x01, 0x28, 0x02, 0x08, 0x41, 0x7F, 0x6A, 0x10, 0x00, 0x20, 0x01, 0x28, 0x02,
            0x08, 0x41, 0x7E, 0x6A, 0x10, 0x00, 0x6A, 0x36, 0x02, 0x0C, 0x0B, 0x20, 0x01, 0x28, 0x02, 0x0C,
            0x21, 0x00, 0x41, 0x00, 0x20, 0x01, 0x41, 0x10, 0x6A, 0x36, 0x02, 0x04, 0x20, 0x00, 0x0B,
        ]),
        toBe: Expression(instructions: [
            NumericInstruction.i32.const(0),
            NumericInstruction.i32.const(0),
            MemoryInstruction.i32.load((2, 4)),
            NumericInstruction.i32.const(16),
            NumericInstruction.i32.sub,
            VariableInstruction.teeLocal(1),
            MemoryInstruction.i32.store((2, 4)),
            VariableInstruction.getLocal(1),
            VariableInstruction.getLocal(0),
            MemoryInstruction.i32.store((2, 8)),
            ControlInstruction.block([], [
                ControlInstruction.block([], [
                    VariableInstruction.getLocal(0),
                    NumericInstruction.i32.const(1),
                    NumericInstruction.i32.gtS,
                    ControlInstruction.brIf(0),
                    VariableInstruction.getLocal(1),
                    NumericInstruction.i32.const(1),
                    MemoryInstruction.i32.store((2, 12)),
                    ControlInstruction.br(1),
                    PseudoInstruction.end,
                ]),
                VariableInstruction.getLocal(1),
                VariableInstruction.getLocal(1),
                MemoryInstruction.i32.load((2, 8)),
                NumericInstruction.i32.const(-1),
                NumericInstruction.i32.add,
                ControlInstruction.call(0),
                VariableInstruction.getLocal(1),
                MemoryInstruction.i32.load((2, 8)),
                NumericInstruction.i32.const(-2),
                NumericInstruction.i32.add,
                ControlInstruction.call(0),
                NumericInstruction.i32.add,
                MemoryInstruction.i32.store((2, 12)),
                PseudoInstruction.end,
            ]),
            VariableInstruction.getLocal(1),
            MemoryInstruction.i32.load((2, 12)),
            VariableInstruction.setLocal(0),
            NumericInstruction.i32.const(0),
            VariableInstruction.getLocal(1),
            NumericInstruction.i32.const(16),
            NumericInstruction.i32.add,
            MemoryInstruction.i32.store((2, 4)),
            VariableInstruction.getLocal(0),
            PseudoInstruction.end,
        ]))

        expect(WASMParser.expression(), ByteStream(bytes: [
            0x41, 0x00, 0x28, 0x02, 0x04, 0x41, 0x20, 0x6B, 0x22, 0x02, 0x22, 0x03,
            0x20, 0x00, 0x36, 0x02, 0x18, 0x02, 0x40, 0x20, 0x00, 0x41, 0x01, 0x4A, 0x0D, 0x00, 0x20, 0x03,
            0x41, 0x01, 0x36, 0x02, 0x1C, 0x20, 0x03, 0x28, 0x02, 0x1C, 0x0F, 0x0B, 0x20, 0x03, 0x28, 0x02,
            0x18, 0x21, 0x00, 0x20, 0x03, 0x20, 0x02, 0x36, 0x02, 0x10, 0x20, 0x02, 0x20, 0x00, 0x41, 0x02,
            0x74, 0x41, 0x0F, 0x6A, 0x41, 0x70, 0x71, 0x6B, 0x22, 0x01, 0x1A, 0x20, 0x01, 0x42, 0x81, 0x80,
            0x80, 0x80, 0x10, 0x37, 0x03, 0x00, 0x20, 0x03, 0x41, 0x02, 0x36, 0x02, 0x0C, 0x02, 0x40, 0x03,
            0x40, 0x20, 0x03, 0x28, 0x02, 0x0C, 0x20, 0x03, 0x28, 0x02, 0x18, 0x4E, 0x0D, 0x01, 0x20, 0x01,
            0x20, 0x03, 0x28, 0x02, 0x0C, 0x22, 0x02, 0x41, 0x02, 0x74, 0x6A, 0x22, 0x00, 0x20, 0x00, 0x41,
            0x7C, 0x6A, 0x28, 0x02, 0x00, 0x20, 0x00, 0x41, 0x78, 0x6A, 0x28, 0x02, 0x00, 0x6A, 0x36, 0x02,
            0x00, 0x20, 0x03, 0x20, 0x02, 0x41, 0x01, 0x6A, 0x36, 0x02, 0x0C, 0x0C, 0x00, 0x0B, 0x0B, 0x20,
            0x03, 0x20, 0x01, 0x20, 0x03, 0x28, 0x02, 0x18, 0x41, 0x02, 0x74, 0x6A, 0x28, 0x02, 0x00, 0x36,
            0x02, 0x1C, 0x20, 0x03, 0x28, 0x02, 0x10, 0x1A, 0x20, 0x03, 0x28, 0x02, 0x1C, 0x0B,
        ]),
        toBe: Expression(instructions: [
            NumericInstruction.i32.const(0),
            MemoryInstruction.i32.load((2, 4)),
            NumericInstruction.i32.const(32),
            NumericInstruction.i32.sub,
            VariableInstruction.teeLocal(2),
            VariableInstruction.teeLocal(3),
            VariableInstruction.getLocal(0),
            MemoryInstruction.i32.store((2, 24)),
            ControlInstruction.block([], [
                VariableInstruction.getLocal(0),
                NumericInstruction.i32.const(1),
                NumericInstruction.i32.gtS,
                ControlInstruction.brIf(0),
                VariableInstruction.getLocal(3),
                NumericInstruction.i32.const(1),
                MemoryInstruction.i32.store((2, 28)),
                VariableInstruction.getLocal(3),
                MemoryInstruction.i32.load((2, 28)),
                ControlInstruction.return,
                PseudoInstruction.end,
            ]),
            VariableInstruction.getLocal(3),
            MemoryInstruction.i32.load((2, 24)),
            VariableInstruction.setLocal(0),
            VariableInstruction.getLocal(3),
            VariableInstruction.getLocal(2),
            MemoryInstruction.i32.store((2, 16)),
            VariableInstruction.getLocal(2),
            VariableInstruction.getLocal(0),
            NumericInstruction.i32.const(2),
            NumericInstruction.i32.shl,
            NumericInstruction.i32.const(15),
            NumericInstruction.i32.add,
            NumericInstruction.i32.const(-16),
            NumericInstruction.i32.add,
            NumericInstruction.i32.sub,
            VariableInstruction.teeLocal(1),
            ParametricInstruction.drop,
            VariableInstruction.getLocal(1),
            NumericInstruction.i64.const(4_294_967_297),
            MemoryInstruction.i64.store((3, 0)),
            VariableInstruction.getLocal(3),
            NumericInstruction.i32.const(2),
            MemoryInstruction.i32.store((2, 12)),
            ControlInstruction.block([], [
                ControlInstruction.loop([], [
                    VariableInstruction.getLocal(3),
                    MemoryInstruction.i32.load((2, 12)),
                    VariableInstruction.getLocal(3),
                    MemoryInstruction.i32.load((2, 24)),
                    NumericInstruction.i32.geS,
                    ControlInstruction.brIf(1),
                    VariableInstruction.getLocal(1),
                    VariableInstruction.getLocal(3),
                    MemoryInstruction.i32.load((2, 12)),
                    VariableInstruction.teeLocal(2),
                    NumericInstruction.i32.const(2),
                    NumericInstruction.i32.shl,
                    NumericInstruction.i32.add,
                    VariableInstruction.teeLocal(0),
                    VariableInstruction.getLocal(0),
                    NumericInstruction.i32.const(-4),
                    NumericInstruction.i32.add,
                    MemoryInstruction.i32.load((2, 0)),
                    VariableInstruction.getLocal(0),
                    NumericInstruction.i32.const(-8),
                    NumericInstruction.i32.add,
                    MemoryInstruction.i32.load((2, 0)),
                    NumericInstruction.i32.add,
                    MemoryInstruction.i32.store((2, 0)),
                    VariableInstruction.getLocal(3),
                    VariableInstruction.getLocal(2),
                    NumericInstruction.i32.const(1),
                    NumericInstruction.i32.add,
                    MemoryInstruction.i32.store((2, 12)),
                    ControlInstruction.br(0),
                    PseudoInstruction.end,
                ]),
                PseudoInstruction.end,
            ]),
            VariableInstruction.getLocal(3),
            VariableInstruction.getLocal(1),
            VariableInstruction.getLocal(3),
            MemoryInstruction.i32.load((2, 24)),
            NumericInstruction.i32.const(2),
            NumericInstruction.i32.shl,
            NumericInstruction.i32.add,
            MemoryInstruction.i32.load((2, 0)),
            MemoryInstruction.i32.store((2, 28)),
            VariableInstruction.getLocal(3),
            MemoryInstruction.i32.load((2, 16)),
            ParametricInstruction.drop,
            VariableInstruction.getLocal(3),
            MemoryInstruction.i32.load((2, 28)),
            PseudoInstruction.end,
        ]))
    }
}

extension WASMParserTests {
    func testIndex() {
        expect(WASMParser.index(), ByteStream(bytes: [0x7F]),
               toBe: 0x7F)
    }

    func testTypeSection() {
        expect(WASMParser.typeSection(), ByteStream(bytes: [
            0x01, // Section ID
            0x0B, // Content Size
            0x02, // Vector Length
            0x60, 0x01, 0x7F, 0x01, 0x7E, // Function Type
            0x60, 0x01, 0x7D, 0x01, 0x7C, // Function Type
        ]), toBe: [
            FunctionType(parameters: [Int32.self], results: [Int64.self]),
            FunctionType(parameters: [Float32.self], results: [Float64.self]),
        ])

        expect(WASMParser.typeSection(), ByteStream(bytes: [
            0x01, 0x04, 0x01, 0x60, 0x01, 0x7F, 0x01, 0x7E,
        ]), toBe: ParserStreamError<ByteStream>.sectionInvalidSize(6, expected: 4, location: 2))
    }

    func testImportSection() {
        expect(WASMParser.importSection(), ByteStream(bytes: [
            0x02, // Section ID
            0x0D, // Content Size
            0x02, // Vector Length
            0x01, 0x61, // Module Name
            0x01, 0x62, // Import Name
            0x00, 0x12, // Import Descriptor (function)
            0x01, 0x63, // Module Name
            0x01, 0x64, // Import Name
            0x00, 0x34, // Import Descriptor (function)
        ]), toBe: [
            Import(module: "a", name: "b", descripter: .function(18)),
            Import(module: "c", name: "d", descripter: .function(52)),
        ])
    }

    func testFunctionSection() {
        expect(WASMParser.functionSection(), ByteStream(bytes: [
            0x03, // Section ID
            0x03, // Content Size
            0x02, // Vector Length
            0x01, 0x02, // Function Indices
        ]), toBe: [0x01, 0x02])
    }

    func testTableSection() {
        expect(WASMParser.tableSection(), ByteStream(bytes: [
            0x04, // Section ID
            0x08, // Content Size
            0x02, // Vector Length
            0x70, // Element Type
            0x00, 0x12, // Limits
            0x70, // Element Type
            0x01, 0x34, 0x56, // Limits
        ]), toBe: [
            Table(type: TableType(limits: Limits(min: 18, max: nil))),
            Table(type: TableType(limits: Limits(min: 52, max: 86))),
        ])
    }

    func testMemorySection() {
        expect(WASMParser.memorySection(), ByteStream(bytes: [
            0x05, // Section ID
            0x06, // Content Size
            0x02, // Vector Length
            0x00, 0x12, // Limits
            0x01, 0x34, 0x56, // Limits
        ]), toBe: [
            Memory(type: MemoryType(min: 18, max: nil)),
            Memory(type: MemoryType(min: 52, max: 86)),
        ])
    }

    func testGlobalSection() {
        expect(WASMParser.globalSection(), ByteStream(bytes: [
            0x06, // Section ID
            0x07, // Content Size
            0x02, // Vector Length
            0x7F, // Value Type
            0x00, // Mutability.constant
            0x0B, // Expression end
            0x7E, // Value Type
            0x01, // Mutability.variable
            0x0B, // Expression end
        ]), toBe: [
            Global(
                type: GlobalType(mutability: .constant, valueType: Int32.self),
                initializer: Expression(instructions: [PseudoInstruction.end])),
            Global(
                type: GlobalType(mutability: .variable, valueType: Int64.self),
                initializer: Expression(instructions: [PseudoInstruction.end])),
        ])
    }

    func testExportSection() {
        expect(WASMParser.exportSection(), ByteStream(bytes: [
            0x07, // Section ID
            0x05, // Content Size
            0x01, // Vector Length
            0x01, 0x61, // Name
            0x00, 0x12, // Descriptor
        ]), toBe: [
            Export(name: "a", descriptor: .function(18)),
        ])
    }

    func testStartSection() {
        expect(WASMParser.startSection(), ByteStream(bytes: [
            0x08, // Section ID
            0x01, // Content Size
            0x12, // Function Index
        ]), toBe: 18)
    }

    func testElementSection() {
        expect(WASMParser.elementSection(), ByteStream(bytes: [
            0x09, // Section ID
            0x09, // Content Size
            0x02, // Vector Length
            0x12, // Table Index
            0x0B, // Expression end
            0x01, // Vector Length
            0x34, // Function Index
            0x56, // Table Index
            0x0B, // Expression end
            0x01, // Vector Length
            0x78, // Function Index
        ]), toBe: [
            Element(table: 18, offset: Expression(instructions: [PseudoInstruction.end]), initializer: [52]),
            Element(table: 86, offset: Expression(instructions: [PseudoInstruction.end]), initializer: [120]),
        ])
    }

    func testCodeSection() {
        expect(WASMParser.codeSection(), ByteStream(bytes: [
            0x0A, // Section ID
            0x0D, // Content Size
            0x02, // Vector Length (code)
            0x04, // Code Size
            0x01, // Vector Length (locals)
            0x03, // n
            0x7F, // Int32.self
            0x0B, // Expression end
            0x06, // Code Size
            0x02, // Vector Length (locals)
            0x01, // n
            0x7E, // Int64.self
            0x02, // n
            0x7D, // Float32.self
            0x0B, // Expression end
        ]), toBe: [
            Code(locals: [Int32.self, Int32.self, Int32.self],
                 expression: Expression(instructions: [PseudoInstruction.end])),
            Code(locals: [Int64.self, Float32.self, Float32.self],
                 expression: Expression(instructions: [PseudoInstruction.end])),
        ])
    }

    func testDataSection() {
        expect(WASMParser.dataSection(), ByteStream(bytes: [
            0x0B, // Section ID
            0x0D, // Content Size
            0x02, // Vector Length
            0x12, // Memory Index
            0x0B, // Expression end
            0x04, // Vector Length (bytes)
            0x01, 0x02, 0x03, 0x04, // bytes
            0x34, // Memory Index
            0x0B, // Expression end
            0x02, // Vector Length (bytes)
            0x05, 0x06, // bytes
        ]), toBe: [
            Data(data: 18,
                 offset: Expression(instructions: [PseudoInstruction.end]),
                 initializer: [0x01, 0x02, 0x03, 0x04]),
            Data(data: 52,
                 offset: Expression(instructions: [PseudoInstruction.end]),
                 initializer: [0x05, 0x06]),
        ])
    }

    func testModule() {
        let bytes: [UInt8] = [
            0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60, 0x01, 0x7F, 0x01, 0x7F,
            0x03, 0x03, 0x02, 0x00, 0x00, 0x04, 0x04, 0x01, 0x70, 0x00, 0x00, 0x05, 0x03, 0x01, 0x00, 0x02,
            0x07, 0x1B, 0x03, 0x06, 0x6D, 0x65, 0x6D, 0x6F, 0x72, 0x79, 0x02, 0x00, 0x03, 0x66, 0x69, 0x62,
            0x00, 0x00, 0x08, 0x66, 0x69, 0x62, 0x5F, 0x6D, 0x65, 0x6D, 0x6F, 0x00, 0x01, 0x0A, 0x9E, 0x02,
            0x02, 0x5D, 0x01, 0x01, 0x7F, 0x41, 0x00, 0x41, 0x00, 0x28, 0x02, 0x04, 0x41, 0x10, 0x6B, 0x22,
            0x01, 0x36, 0x02, 0x04, 0x20, 0x01, 0x20, 0x00, 0x36, 0x02, 0x08, 0x02, 0x40, 0x02, 0x40, 0x20,
            0x00, 0x41, 0x01, 0x4A, 0x0D, 0x00, 0x20, 0x01, 0x41, 0x01, 0x36, 0x02, 0x0C, 0x0C, 0x01, 0x0B,
            0x20, 0x01, 0x20, 0x01, 0x28, 0x02, 0x08, 0x41, 0x7F, 0x6A, 0x10, 0x00, 0x20, 0x01, 0x28, 0x02,
            0x08, 0x41, 0x7E, 0x6A, 0x10, 0x00, 0x6A, 0x36, 0x02, 0x0C, 0x0B, 0x20, 0x01, 0x28, 0x02, 0x0C,
            0x21, 0x00, 0x41, 0x00, 0x20, 0x01, 0x41, 0x10, 0x6A, 0x36, 0x02, 0x04, 0x20, 0x00, 0x0B, 0xBD,
            0x01, 0x01, 0x03, 0x7F, 0x41, 0x00, 0x28, 0x02, 0x04, 0x41, 0x20, 0x6B, 0x22, 0x02, 0x22, 0x03,
            0x20, 0x00, 0x36, 0x02, 0x18, 0x02, 0x40, 0x20, 0x00, 0x41, 0x01, 0x4A, 0x0D, 0x00, 0x20, 0x03,
            0x41, 0x01, 0x36, 0x02, 0x1C, 0x20, 0x03, 0x28, 0x02, 0x1C, 0x0F, 0x0B, 0x20, 0x03, 0x28, 0x02,
            0x18, 0x21, 0x00, 0x20, 0x03, 0x20, 0x02, 0x36, 0x02, 0x10, 0x20, 0x02, 0x20, 0x00, 0x41, 0x02,
            0x74, 0x41, 0x0F, 0x6A, 0x41, 0x70, 0x71, 0x6B, 0x22, 0x01, 0x1A, 0x20, 0x01, 0x42, 0x81, 0x80,
            0x80, 0x80, 0x10, 0x37, 0x03, 0x00, 0x20, 0x03, 0x41, 0x02, 0x36, 0x02, 0x0C, 0x02, 0x40, 0x03,
            0x40, 0x20, 0x03, 0x28, 0x02, 0x0C, 0x20, 0x03, 0x28, 0x02, 0x18, 0x4E, 0x0D, 0x01, 0x20, 0x01,
            0x20, 0x03, 0x28, 0x02, 0x0C, 0x22, 0x02, 0x41, 0x02, 0x74, 0x6A, 0x22, 0x00, 0x20, 0x00, 0x41,
            0x7C, 0x6A, 0x28, 0x02, 0x00, 0x20, 0x00, 0x41, 0x78, 0x6A, 0x28, 0x02, 0x00, 0x6A, 0x36, 0x02,
            0x00, 0x20, 0x03, 0x20, 0x02, 0x41, 0x01, 0x6A, 0x36, 0x02, 0x0C, 0x0C, 0x00, 0x0B, 0x0B, 0x20,
            0x03, 0x20, 0x01, 0x20, 0x03, 0x28, 0x02, 0x18, 0x41, 0x02, 0x74, 0x6A, 0x28, 0x02, 0x00, 0x36,
            0x02, 0x1C, 0x20, 0x03, 0x28, 0x02, 0x10, 0x1A, 0x20, 0x03, 0x28, 0x02, 0x1C, 0x0B, 0x0B, 0x0A,
            0x01, 0x00, 0x41, 0x04, 0x0B, 0x04, 0x10, 0x00, 0x01, 0x00,
        ]

        let module = Module(
            types: [
                FunctionType(
                    parameters: [Int32.self],
                    results: [Int32.self]),
            ],
            functions: [
                Function(
                    type: 0,
                    locals: [Int32.self],
                    body: Expression(instructions: [
                        NumericInstruction.i32.const(0), NumericInstruction.i32.const(0),
                        MemoryInstruction.i32.load((2, 4)), NumericInstruction.i32.const(16),
                        NumericInstruction.i32.sub, VariableInstruction.teeLocal(1),
                        MemoryInstruction.i32.store((2, 4)), VariableInstruction.getLocal(1),
                        VariableInstruction.getLocal(0), MemoryInstruction.i32.store((2, 8)),
                        ControlInstruction.block([], [
                            ControlInstruction.block([], [
                                VariableInstruction.getLocal(0), NumericInstruction.i32.const(1),
                                NumericInstruction.i32.gtS, ControlInstruction.brIf(0), VariableInstruction.getLocal(1),
                                NumericInstruction.i32.const(1), MemoryInstruction.i32.store((2, 12)),
                                ControlInstruction.br(1), PseudoInstruction.end,
                            ]),
                            VariableInstruction.getLocal(1), VariableInstruction.getLocal(1),
                            MemoryInstruction.i32.load((2, 8)), NumericInstruction.i32.const(-1),
                            NumericInstruction.i32.add, ControlInstruction.call(0), VariableInstruction.getLocal(1),
                            MemoryInstruction.i32.load((2, 8)), NumericInstruction.i32.const(-2),
                            NumericInstruction.i32.add, ControlInstruction.call(0), NumericInstruction.i32.add,
                            MemoryInstruction.i32.store((2, 12)), PseudoInstruction.end,
                        ]),
                        VariableInstruction.getLocal(1), MemoryInstruction.i32.load((2, 12)),
                        VariableInstruction.setLocal(0), NumericInstruction.i32.const(0),
                        VariableInstruction.getLocal(1), NumericInstruction.i32.const(16), NumericInstruction.i32.add,
                        MemoryInstruction.i32.store((2, 4)), VariableInstruction.getLocal(0), PseudoInstruction.end,
                    ])
                ),
                Function(
                    type: 0,
                    locals: [Int32.self, Int32.self, Int32.self],
                    body: Expression(instructions: [
                        NumericInstruction.i32.const(0), MemoryInstruction.i32.load((2, 4)),
                        NumericInstruction.i32.const(32), NumericInstruction.i32.sub, VariableInstruction.teeLocal(2),
                        VariableInstruction.teeLocal(3), VariableInstruction.getLocal(0),
                        MemoryInstruction.i32.store((2, 24)),
                        ControlInstruction.block([], [
                            VariableInstruction.getLocal(0), NumericInstruction.i32.const(1),
                            NumericInstruction.i32.gtS, ControlInstruction.brIf(0), VariableInstruction.getLocal(3),
                            NumericInstruction.i32.const(1), MemoryInstruction.i32.store((2, 28)),
                            VariableInstruction.getLocal(3), MemoryInstruction.i32.load((2, 28)),
                            ControlInstruction.return, PseudoInstruction.end,
                        ]),
                        VariableInstruction.getLocal(3), MemoryInstruction.i32.load((2, 24)),
                        VariableInstruction.setLocal(0), VariableInstruction.getLocal(3),
                        VariableInstruction.getLocal(2), MemoryInstruction.i32.store((2, 16)),
                        VariableInstruction.getLocal(2), VariableInstruction.getLocal(0),
                        NumericInstruction.i32.const(2), NumericInstruction.i32.shl, NumericInstruction.i32.const(15),
                        NumericInstruction.i32.add, NumericInstruction.i32.const(-16), NumericInstruction.i32.add,
                        NumericInstruction.i32.sub, VariableInstruction.teeLocal(1), ParametricInstruction.drop,
                        VariableInstruction.getLocal(1), NumericInstruction.i64.const(4_294_967_297),
                        MemoryInstruction.i64.store((3, 0)), VariableInstruction.getLocal(3),
                        NumericInstruction.i32.const(2), MemoryInstruction.i32.store((2, 12)),
                        ControlInstruction.block([], [
                            ControlInstruction.loop([], [
                                VariableInstruction.getLocal(3), MemoryInstruction.i32.load((2, 12)),
                                VariableInstruction.getLocal(3), MemoryInstruction.i32.load((2, 24)),
                                NumericInstruction.i32.geS, ControlInstruction.brIf(1),
                                VariableInstruction.getLocal(1), VariableInstruction.getLocal(3),
                                MemoryInstruction.i32.load((2, 12)), VariableInstruction.teeLocal(2),
                                NumericInstruction.i32.const(2), NumericInstruction.i32.shl,
                                NumericInstruction.i32.add, VariableInstruction.teeLocal(0),
                                VariableInstruction.getLocal(0), NumericInstruction.i32.const(-4),
                                NumericInstruction.i32.add, MemoryInstruction.i32.load((2, 0)),
                                VariableInstruction.getLocal(0), NumericInstruction.i32.const(-8),
                                NumericInstruction.i32.add, MemoryInstruction.i32.load((2, 0)),
                                NumericInstruction.i32.add, MemoryInstruction.i32.store((2, 0)),
                                VariableInstruction.getLocal(3), VariableInstruction.getLocal(2),
                                NumericInstruction.i32.const(1), NumericInstruction.i32.add,
                                MemoryInstruction.i32.store((2, 12)), ControlInstruction.br(0),
                                PseudoInstruction.end,
                            ]),
                            PseudoInstruction.end,
                        ]),
                        VariableInstruction.getLocal(3), VariableInstruction.getLocal(1),
                        VariableInstruction.getLocal(3), MemoryInstruction.i32.load((2, 24)),
                        NumericInstruction.i32.const(2), NumericInstruction.i32.shl,
                        NumericInstruction.i32.add, MemoryInstruction.i32.load((2, 0)),
                        MemoryInstruction.i32.store((2, 28)), VariableInstruction.getLocal(3),
                        MemoryInstruction.i32.load((2, 16)), ParametricInstruction.drop,
                        VariableInstruction.getLocal(3), MemoryInstruction.i32.load((2, 28)),
                        PseudoInstruction.end,
                    ])
                ),
            ],
            tables: [Table(type: TableType(limits: Limits(min: 0, max: nil)))],
            memories: [Memory(type: MemoryType(min: 2, max: nil))],
            globals: [],
            elements: [],
            data: [
                Data(
                    data: 0,
                    offset: Expression(instructions: [NumericInstruction.i32.const(4), PseudoInstruction.end]),
                    initializer: [16, 0, 1, 0]),
            ],
            start: nil,
            imports: [],
            exports: [
                Export(name: "memory", descriptor: ExportDescriptor.memory(0)),
                Export(name: "fib", descriptor: ExportDescriptor.function(0)),
                Export(name: "fib_memo", descriptor: ExportDescriptor.function(1)),
            ]
        )

        expect(WASMParser.module(), ByteStream(bytes: bytes), toBe: module)
    }
}