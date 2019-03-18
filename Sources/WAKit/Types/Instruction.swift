struct Expression: Equatable {
    let instructions: [Instruction]

    init(instructions: [Instruction] = []) {
        self.instructions = instructions
    }

    static func == (lhs: Expression, rhs: Expression) -> Bool {
        return lhs.instructions == rhs.instructions
    }
}

public protocol Instruction {
    func isEqual(to another: Instruction) -> Bool
}

extension Instruction where Self: Equatable {
    func isEqual(to another: Instruction) -> Bool {
        guard let another = another as? Self else { return false }
        return self == another
    }
}

extension Array where Element == Instruction {
    static func == (lhs: [Instruction], rhs: [Instruction]) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        for (l, r) in zip(lhs, rhs) {
            guard l.isEqual(to: r) else { return false }
        }
        return true
    }
}

/// Pseudo Instructions
enum PseudoInstruction: Instruction, Equatable {
    case `else`
    case end
}

/// Control Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#control-instructions>
// sourcery: AutoEquatable
enum ControlInstruction: Instruction {
    case unreachable
    case nop
    case block(ResultType, Expression)
    case loop(ResultType, Expression)
    case `if`(ResultType, Expression, Expression)
    case br(LabelIndex)
    case brIf(LabelIndex)
    case brTable([LabelIndex], LabelIndex)
    case `return`
    case call(FunctionIndex)
    case callIndirect(TypeIndex)
}

/// Parametric Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#parametric-instructions>
enum ParametricInstruction: Instruction, Equatable {
    case drop
    case select
}

/// Variable Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#variable-instructions>
enum VariableInstruction: Instruction, Equatable {
    case localGet(LabelIndex)
    case localSet(LabelIndex)
    case localTee(LabelIndex)
    case getGlobal(GlobalIndex)
    case setGlobal(GlobalIndex)
}

/// Memory Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#memory-instructions>
// sourcery: AutoEquatable
enum MemoryInstruction: Instruction {
    case currentMemory
    case growMemory

    case load(ValueType, offset: UInt32, alignment: UInt32)
    case load8s(ValueType, offset: UInt32, alignment: UInt32)
    case load8u(ValueType, offset: UInt32, alignment: UInt32)
    case load16s(ValueType, offset: UInt32, alignment: UInt32)
    case load16u(ValueType, offset: UInt32, alignment: UInt32)
    case load32s(ValueType, offset: UInt32, alignment: UInt32)
    case load32u(ValueType, offset: UInt32, alignment: UInt32)
    case store(ValueType, offset: UInt32, alignment: UInt32)
    case store8(ValueType, offset: UInt32, alignment: UInt32)
    case store16(ValueType, offset: UInt32, alignment: UInt32)
    case store32(ValueType, offset: UInt32, alignment: UInt32)
}

/// Numeric Instructions
/// - Note:
/// <https://webassembly.github.io/spec/core/binary/instructions.html#numeric-instructions>
enum NumericInstruction {
    // sourcery: AutoEquatable
    enum Constant: Instruction {
        case const(Value)
    }

    // sourcery: AutoEquatable
    enum Unary: Instruction {
        // iunop
        case clz(IntValueType)
        case ctz(IntValueType)
        case popcnt(IntValueType)

        /// itestop
        case eqz(IntValueType)

        // funop
        case abs(FloatValueType)
        case neg(FloatValueType)
        case ceil(FloatValueType)
        case floor(FloatValueType)
        case trunc(FloatValueType)
        case nearest(FloatValueType)
        case sqrt(FloatValueType)

        var type: ValueType {
            switch self {
            case let .clz(type),
                 let .ctz(type),
                 let .popcnt(type),
                 let .eqz(type):
                return type

            case let .abs(type),
                 let .neg(type),
                 let .ceil(type),
                 let .floor(type),
                 let .trunc(type),
                 let .nearest(type),
                 let .sqrt(type):
                return type
            }
        }
    }

    // sourcery: AutoEquatable
    enum Binary: Instruction {
        // binop
        case add(ValueType)
        case sub(ValueType)
        case mul(ValueType)

        // relop
        case eq(ValueType)
        case ne(ValueType)

        // ibinop
        case divS(IntValueType)
        case divU(IntValueType)
        case remS(IntValueType)
        case remU(IntValueType)
        case and(IntValueType)
        case or(IntValueType)
        case xor(IntValueType)
        case shl(IntValueType)
        case shrS(IntValueType)
        case shrU(IntValueType)
        case rotl(IntValueType)
        case rotr(IntValueType)

        // irelop
        case ltS(IntValueType)
        case ltU(IntValueType)
        case gtS(IntValueType)
        case gtU(IntValueType)
        case leS(IntValueType)
        case leU(IntValueType)
        case geS(IntValueType)
        case geU(IntValueType)

        // fbinop
        case div(FloatValueType)
        case min(FloatValueType)
        case max(FloatValueType)
        case copysign(FloatValueType)

        // frelop
        case lt(FloatValueType)
        case gt(FloatValueType)
        case le(FloatValueType)
        case ge(FloatValueType)

        var type: ValueType {
            switch self {
            case let .add(type),
                 let .sub(type),
                 let .mul(type),
                 let .eq(type),
                 let .ne(type):
                return type
            case let .divS(type),
                 let .divU(type),
                 let .remS(type),
                 let .remU(type),
                 let .and(type),
                 let .or(type),
                 let .xor(type),
                 let .shl(type),
                 let .shrS(type),
                 let .shrU(type),
                 let .rotl(type),
                 let .rotr(type),
                 let .ltS(type),
                 let .ltU(type),
                 let .gtS(type),
                 let .gtU(type),
                 let .leS(type),
                 let .leU(type),
                 let .geS(type),
                 let .geU(type):
                return type
            case let .div(type),
                 let .min(type),
                 let .max(type),
                 let .copysign(type),
                 let .lt(type),
                 let .gt(type),
                 let .le(type),
                 let .ge(type):
                return type
            }
        }
    }

    // sourcery: AutoEquatable
    enum Conversion: Instruction {
        case wrap(I32.Type, I64.Type)
        case extendS(I64.Type, I32.Type)
        case extendU(I64.Type, I32.Type)
        case truncS(IntValueType, FloatValueType)
        case truncU(IntValueType, FloatValueType)
        case convertS(FloatValueType, IntValueType)
        case convertU(FloatValueType, IntValueType)
        case demote(F32.Type, F64.Type)
        case promote(F64.Type, F32.Type)
        case reinterpret(ValueType, ValueType)

        var types: (ValueType, ValueType) {
            switch self {
            case let .wrap(type1, type2):
                return (type1, type2)
            case let .extendS(type1, type2):
                return (type1, type2)
            case let .extendU(type1, type2):
                return (type1, type2)
            case let .truncS(type1, type2):
                return (type1, type2)
            case let .truncU(type1, type2):
                return (type1, type2)
            case let .convertS(type1, type2):
                return (type1, type2)
            case let .convertU(type1, type2):
                return (type1, type2)
            case let .demote(type1, type2):
                return (type1, type2)
            case let .promote(type1, type2):
                return (type1, type2)
            case let .reinterpret(type1, type2):
                return (type1, type2)
            }
        }
    }
}
