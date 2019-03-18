/// - Note:
/// <https://webassembly.github.io/spec/core/syntax/instructions.html#numeric-instructions>

extension Runtime {
    func execute(numeric instruction: NumericInstruction.Constant) throws {
        switch instruction {
        case let .const(value as I32):
            stack.push(value)
        case let .const(value as I64):
            stack.push(value)
        case let .const(value as F32):
            stack.push(value)
        case let .const(value as F64):
            stack.push(value)
        case let .const(value):
            throw Trap.invalidTypeForInstruction(type(of: value), instruction)
        }
    }

    func execute(numeric instruction: NumericInstruction.Unary) throws {
        let value = try stack.pop(instruction.type)

        let result: Value
        switch value {
        case let value as I32:
            result = try operate(I32.self, instruction, value)
        case let value as I64:
            result = try operate(I64.self, instruction, value)
        case let value as F32:
            result = try operate(F32.self, instruction, value)
        case let value as F64:
            result = try operate(F64.self, instruction, value)
        default:
            throw Trap.invalidTypeForInstruction(instruction.type, instruction)
        }

        stack.push(result)
    }

    func execute(numeric instruction: NumericInstruction.Binary) throws {
        let value2 = try stack.pop(instruction.type)
        let value1 = try stack.pop(instruction.type)

        let result: Value
        switch (value1, value2) {
        case let (value1, value2) as (I32, I32):
            result = try operate(I32.self, instruction, value1, value2)
        case let (value1, value2) as (I64, I64):
            result = try operate(I64.self, instruction, value1, value2)
        case let (value1, value2) as (F32, F32):
            result = try operate(F32.self, instruction, value1, value2)
        case let (value1, value2) as (F64, F64):
            result = try operate(F64.self, instruction, value1, value2)
        default:
            throw Trap.invalidTypeForInstruction(instruction.type, instruction)
        }

        stack.push(result)
    }

    func execute(numeric instruction: NumericInstruction.Conversion) throws {
        let (type1, type2) = instruction.types
        let value = try stack.pop(type1)

        let result: Value
        switch value {
        case let value as I32:
            result = try operate(I32.self, type2, instruction, value)
        case let value as I64:
            result = try operate(I64.self, type2, instruction, value)
        case let value as F32:
            result = try operate(F32.self, type2, instruction, value)
        case let value as F64:
            result = try operate(F64.self, type2, instruction, value)
        default:
            throw Trap.invalidTypeForInstruction(instruction.types.0, instruction)
        }

        stack.push(result)
    }
}

extension Runtime {
    fileprivate func operate<V: RawRepresentableValue>(
        _ type: V.Type,
        _ instruction: NumericInstruction.Unary,
        _ value: V
    ) throws -> Value where V.RawValue: RawUnsignedInteger {
        switch instruction {
        case .clz:
            return V(V.RawValue(value.rawValue.leadingZeroBitCount))
        case .ctz:
            return V(V.RawValue(value.rawValue.trailingZeroBitCount))
        case .popcnt:
            return V(V.RawValue(value.rawValue.nonzeroBitCount))

        case .eqz:
            return value.rawValue == 0 ? I32(1) : I32(0)
        default: throw Trap.invalidTypeForInstruction(type, instruction)
        }
    }

    fileprivate func operate<V: RawRepresentableValue>(
        _ type: V.Type,
        _ instruction: NumericInstruction.Unary,
        _ value: V
    ) throws -> Value where V.RawValue: RawFloatingPoint {
        let result: V.RawValue
        switch instruction {
        case .abs:
            result = abs(value.rawValue)
        case .neg:
            result = -value.rawValue
        case .ceil:
            result = abs(value.rawValue.nextUp)
        case .floor:
            result = abs(value.rawValue.nextDown)
        case .trunc:
            result = abs(value.rawValue.rounded(.towardZero))
        case .nearest:
            result = abs(value.rawValue.rounded(.toNearestOrEven))
        case .sqrt:
            result = value.rawValue.squareRoot()

        default: throw Trap.invalidTypeForInstruction(type, instruction)
        }
        return V(result)
    }
}

extension Runtime {
    fileprivate func operate<V: RawRepresentableValue>(
        _ type: V.Type,
        _ instruction: NumericInstruction.Binary,
        _ value1: V, _ value2: V
    ) throws -> Value where V.RawValue: RawUnsignedInteger {
        switch instruction {
        case .add:
            return V(value1.rawValue &+ value2.rawValue)
        case .sub:
            return V(value1.rawValue &- value2.rawValue)
        case .mul:
            return V(value1.rawValue &* value2.rawValue)

        case .eq:
            return value1.rawValue == value2.rawValue ? I32(1) : I32(0)
        case .ne:
            return value1.rawValue != value2.rawValue ? I32(1) : I32(0)

        case .divS:
            guard value2 != 0 else { throw Trap.integerDividedByZero }
            let (signed, overflow) = value1.signed.dividedReportingOverflow(by: value2.signed)
            guard !overflow else { throw Trap.integerOverflowed }
            return V(signed.unsigned)
        case .divU:
            guard value2 != 0 else { throw Trap.integerDividedByZero }
            let (result, overflow) = value1.rawValue.dividedReportingOverflow(by: value2.rawValue)
            guard !overflow else { throw Trap.integerOverflowed }
            return V(result)
        case .remS:
            guard value2 != 0 else { throw Trap.integerDividedByZero }
            let (signed, overflow) = value1.signed.remainderReportingOverflow(dividingBy: value2.signed)
            guard !overflow else { throw Trap.integerOverflowed }
            return V(signed.unsigned)
        case .remU:
            guard value2 != 0 else { throw Trap.integerDividedByZero }
            let (result, overflow) = value1.rawValue.remainderReportingOverflow(dividingBy: value2.rawValue)
            guard !overflow else { throw Trap.integerOverflowed }
            return V(result)
        case .and:
            return V(value1.rawValue & value2.rawValue)
        case .or:
            return V(value1.rawValue | value2.rawValue)
        case .xor:
            return V(value1.rawValue ^ value2.rawValue)
        case .shl:
            let shift = value2.rawValue % V.RawValue(V.RawValue.bitWidth)
            return V(value1.rawValue << shift)
        case .shrS:
            let shift = value2.signed % V.RawValue.Signed(V.RawValue.Signed.bitWidth)
            return V((value1.signed >> shift).unsigned)
        case .shrU:
            let shift = value2.rawValue % V.RawValue(V.RawValue.bitWidth)
            return V(value1.rawValue >> shift)
        case .rotl:
            let shift = value2.rawValue % V.RawValue(V.RawValue.bitWidth)
            return V(value1.rawValue.rotl(shift))
        case .rotr:
            let shift = value2.rawValue % V.RawValue(V.RawValue.bitWidth)
            return V(value1.rawValue.rotr(shift))

        case .ltS:
            return value1.signed < value2.signed ? I32(1) : I32(0)
        case .ltU:
            return value1.rawValue < value2.rawValue ? I32(1) : I32(0)
        case .gtS:
            return value1.signed > value2.signed ? I32(1) : I32(0)
        case .gtU:
            return value1.rawValue > value2.rawValue ? I32(1) : I32(0)
        case .leS:
            return value1.signed <= value2.signed ? I32(1) : I32(0)
        case .leU:
            return value1.rawValue <= value2.rawValue ? I32(1) : I32(0)
        case .geS:
            return value1.signed >= value2.signed ? I32(1) : I32(0)
        case .geU:
            return value1.rawValue >= value2.rawValue ? I32(1) : I32(0)

        default: throw Trap.invalidTypeForInstruction(type, instruction)
        }
    }

    fileprivate func operate<V: RawRepresentableValue>(
        _ type: V.Type,
        _ instruction: NumericInstruction.Binary,
        _ value1: V, _ value2: V
    ) throws -> Value where V.RawValue: RawFloatingPoint {
        switch instruction {
        case .add:
            return V(value1.rawValue + value2.rawValue)
        case .sub:
            return V(value1.rawValue - value2.rawValue)
        case .mul:
            return V(value1.rawValue * value2.rawValue)

        case .eq:
            return value1.rawValue == value2.rawValue ? I32(1) : I32(0)
        case .ne:
            return value1.rawValue == value2.rawValue ? I32(0) : I32(1)

        case .div:
            guard value2 != 0 else { throw Trap.integerDividedByZero }
            return V(value1.rawValue / value2.rawValue)
        case .min:
            return V(min(value1.rawValue, value2.rawValue))
        case .max:
            return V(max(value1.rawValue, value2.rawValue))
        case .copysign:
            return V(value1.rawValue.sign == value2.rawValue.sign ? value1.rawValue : -value1.rawValue)
        case .lt:
            return value1.rawValue < value2.rawValue ? I32(1) : I32(0)
        case .gt:
            return value1.rawValue > value2.rawValue ? I32(1) : I32(0)
        case .le:
            return value1.rawValue <= value2.rawValue ? I32(1) : I32(0)
        case .ge:
            return value1.rawValue >= value2.rawValue ? I32(1) : I32(0)

        default: throw Trap.invalidTypeForInstruction(type, instruction)
        }
    }
}

extension Runtime {
    fileprivate func operate<V1: RawRepresentableValue, V2: Value>(
        _: V1.Type,
        _: V2.Type,
        _ instruction: NumericInstruction.Conversion,
        _: V1
    ) throws -> V2 {
        throw Trap.unimplemented("\(instruction)")
    }
}
