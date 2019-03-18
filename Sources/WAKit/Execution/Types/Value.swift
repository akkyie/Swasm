/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/types.html#value-types>

public typealias ValueType = Value.Type
public class Value: Equatable, Hashable {
    public static func == (lhs: Value, rhs: Value) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    required init() {
        precondition(type(of: self) != Value.self, "Subclasses of Value have to be used")
    }

    public func hash(into _: inout Hasher) {
        preconditionFailure("Subclasses of Value must override `hash(into:)`")
    }
}

public protocol RawRepresentableValue where Self: Value {
    associatedtype RawValue

    var rawValue: RawValue { get }

    init(_ rawValue: RawValue)
}

// Integers
/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/values.html#integers>

public typealias IntValueType = IntValue.Type
public class IntValue: Value {
    required init() {
        super.init()
        precondition(type(of: self) != IntValue.self, "Subclasses of IntValue have to be used")
    }

    public override func hash(into _: inout Hasher) {
        preconditionFailure("Subclasses of IntValue must override `hash(into:)`")
    }
}

public final class I32: IntValue, RawRepresentableValue, CustomStringConvertible {
    public let rawValue: UInt32

    required init() {
        rawValue = 0
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public var description: String {
        return "\(type(of: self))(\(rawValue))"
    }

    public override func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

public final class I64: IntValue, RawRepresentableValue, CustomStringConvertible {
    public let rawValue: UInt64

    required init() {
        rawValue = 0
    }

    public init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public var description: String {
        return "\(type(of: self))(\(rawValue))"
    }

    public override func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

public protocol RawUnsignedInteger: FixedWidthInteger & UnsignedInteger {
    associatedtype Signed: RawSignedInteger where Signed.Unsigned == Self
}

public protocol RawSignedInteger: FixedWidthInteger & SignedInteger {
    associatedtype Unsigned: RawUnsignedInteger
    init(bitPattern: Unsigned)
}

extension UInt32: RawUnsignedInteger {
    public typealias Signed = Int32
}

extension UInt64: RawUnsignedInteger {
    public typealias Signed = Int64
}

extension Int32: RawSignedInteger {}
extension Int64: RawSignedInteger {}

extension RawUnsignedInteger {
    var signed: Signed {
        return self > Signed.max ? -Signed(Self.max - self) - 1 : Signed(self)
    }
}

extension RawSignedInteger {
    var unsigned: Unsigned {
        return self < 0 ? Unsigned.max - Unsigned(-(self + 1)) : Unsigned(self)
    }
}

extension RawRepresentableValue where Self: Value, RawValue: RawUnsignedInteger {
    var signed: RawValue.Signed {
        return rawValue.signed
    }

    public init(_ value: RawValue.Signed) {
        let rawValue: RawValue
        if value < 0 {
            rawValue = RawValue(~value)
        } else {
            rawValue = RawValue(value)
        }
        self.init(rawValue)
    }

    public static func == (lhs: Self, rhs: RawValue) -> Bool {
        return lhs.rawValue == rhs
    }

    public static func != (lhs: Self, rhs: RawValue) -> Bool {
        return lhs.rawValue != rhs
    }
}

// Floating-Point
/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/values.html#floating-point>

public typealias FloatValueType = FloatValue.Type
public class FloatValue: Value {
    required init() {
        super.init()
        precondition(type(of: self) != IntValue.self, "Subclasses of FloatValue have to be used")
    }

    public override func hash(into _: inout Hasher) {
        preconditionFailure("Subclasses of FloatValue must override `hash(into:)`")
    }
}

public typealias RawFloatingPoint = BinaryFloatingPoint

public final class F32: FloatValue, RawRepresentableValue, CustomStringConvertible {
    public let rawValue: Float32

    required init() {
        rawValue = 0
    }

    public init(_ rawValue: Float32) {
        self.rawValue = rawValue
    }

    public var description: String {
        return "\(type(of: self))(\(rawValue))"
    }

    public override func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

public final class F64: FloatValue, RawRepresentableValue, CustomStringConvertible {
    public let rawValue: Float64

    required init() {
        rawValue = 0
    }

    public init(_ rawValue: Float64) {
        self.rawValue = rawValue
    }

    public var description: String {
        return "\(type(of: self))(\(rawValue))"
    }

    public override func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}

extension RawRepresentableValue where Self: Value, RawValue: RawFloatingPoint {
    public static func == (lhs: Self, rhs: RawValue) -> Bool {
        return lhs.rawValue == rhs
    }

    public static func != (lhs: Self, rhs: RawValue) -> Bool {
        return lhs.rawValue != rhs
    }
}

protocol ByteConvertible {
    static var bitWidth: Int { get }

    init<T: Sequence>(_ bytes: T) where T.Element == UInt8

    func bytes() -> [UInt8]
}

extension ByteConvertible where Self: RawRepresentableValue, Self.RawValue: FixedWidthInteger {
    static var bitWidth: Int {
        return RawValue.bitWidth
    }
}

extension FixedWidthInteger {
    init<T: Sequence>(littleEndian bytes: T) where T.Element == UInt8 {
        self.init(bigEndian: bytes.reversed())
    }

    var littleEndianBytes: [UInt8] {
        return (0 ..< Self.bitWidth / 8).map { UInt8(truncatingIfNeeded: self >> $0) }
    }

    init<T: Sequence>(bigEndian bytes: T) where T.Element == UInt8 {
        self = bytes.reduce(into: Self()) { acc, next in
            acc <<= 8
            acc |= Self(next)
        }
    }

    var bigEndianBytes: [UInt8] {
        return littleEndianBytes.reversed()
    }
}

extension I32: ByteConvertible {
    convenience init<T: Sequence>(_ bytes: T) where T.Element == UInt8 {
        self.init(RawValue(littleEndian: bytes))
    }

    func bytes() -> [UInt8] {
        return rawValue.littleEndianBytes
    }
}

extension I64: ByteConvertible {
    convenience init<T: Sequence>(_ bytes: T) where T.Element == UInt8 {
        self.init(RawValue(littleEndian: bytes))
    }

    func bytes() -> [UInt8] {
        return rawValue.littleEndianBytes
    }
}

extension F32: ByteConvertible {
    static var bitWidth: Int { return 32 }

    convenience init<T: Sequence>(_ bytes: T) where T.Element == UInt8 {
        self.init(RawValue(bitPattern: UInt32(bigEndian: bytes)))
    }

    func bytes() -> [UInt8] {
        return rawValue.bitPattern.bigEndianBytes
    }
}

extension F64: ByteConvertible {
    static var bitWidth: Int { return 64 }

    convenience init<T: Sequence>(_ bytes: T) where T.Element == UInt8 {
        self.init(RawValue(bitPattern: UInt64(bigEndian: bytes)))
    }

    func bytes() -> [UInt8] {
        return rawValue.bitPattern.bigEndianBytes
    }
}

extension Array where Element == ValueType {
    static func == (lhs: [ValueType], rhs: [ValueType]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(true) { result, zipped in
            result && zipped.0 == zipped.1
        }
    }

    static func != (lhs: [ValueType], rhs: [ValueType]) -> Bool {
        return !(lhs == rhs)
    }
}

extension FixedWidthInteger {
    func rotl(_ l: Self) -> Self {
        return self << l | self >> (Self(Self.bitWidth) - l)
    }

    func rotr(_ r: Self) -> Self {
        return self >> r | self << (Self(Self.bitWidth) - r)
    }
}
