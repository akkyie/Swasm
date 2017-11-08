public enum WASTLexicalToken {
    case keyword(String)
    case unsigned(UInt)
    case signed(Int)
    case floating(Double)
    case string(String)
    case identifier(String)
    case openingBrace
    case closingBrace
    case unknown(UnicodeScalar)
}

extension WASTLexicalToken: Equatable {
    public static func == (lhs: WASTLexicalToken, rhs: WASTLexicalToken) -> Bool {
        switch (lhs, rhs) {
        case let (.keyword(l), .keyword(r)):
            return l == r
        case let (.unsigned(l), .unsigned(r)):
            return l == r
        case let (.signed(l), .signed(r)):
            return l == r
        case let (.floating(l), .floating(r)):
            return l == r
        case let (.string(l), .string(r)):
            return l == r
        case let (.identifier(l), .identifier(r)):
            return l == r
        case (.openingBrace, .openingBrace):
            return true
        case (.closingBrace, .closingBrace):
            return true
        case let (.unknown(l), .unknown(r)):
            return l == r
        default:
            return false
        }
    }
}

public struct WASTLexer<InputStream: LA2Stream> where InputStream.Element == UnicodeScalar {
    var stream: InputStream

    init(stream: InputStream) {
        self.stream = stream
    }
}

extension WASTLexer: Stream {
    public var position: InputStream.Index {
        return stream.position
    }

    public mutating func next() -> WASTLexicalToken? {
        while let c0 = stream.next() {
            let (c1, c2) = stream.look()

            switch (c0, c1, c2) {
            case (" ", _, _), ("\t", _, _), ("\n", _, _), ("\r", _, _): // Whitespace and format effectors
                continue

            case (";", ";"?, _): // Line comment
                var c = c2
                while c != nil, c != "\n" {
                    c = stream.next()
                }
                continue

            case ("(", ";"?, _): // Block comment
                while case let (end1?, end2?) = stream.look(), (end1, end2) != (";", ")") {
                    _ = stream.next()
                }
                _ = stream.next(); _ = stream.next() // skip ";)"

            case ("(", _, _): // Opening brace
                return .openingBrace

            case (")", _, _): // Closing brace
                return .closingBrace

            case ("$", _?, _): // Identifier
                var result = String.UnicodeScalarView()
                while let c = stream.next(), CharacterSet.IDCharacters.contains(c) {
                    result.append(c)
                }
                return .identifier(String(result))

            case (CharacterSet.decimalDigits, _, _),
                 (CharacterSet.signs, _?, _),
                 ("i", "n"?, "f"?): // Number
                return consumeNumber(from: c0)

            case ("\"", _, _): // String
                guard c1 != "\"" else {
                    _ = stream.next()
                    return .string("")
                }

                var result = String.UnicodeScalarView()
                while let c = consumeCharacter() {
                    result.append(c)
                }
                return .string(String(result))

            case (CharacterSet.keywordPrefixes, _, _): // Keyword
                var result = String.UnicodeScalarView()
                result.append(c0)
                while let c: UnicodeScalar = stream.next(), CharacterSet.IDCharacters.contains(c) {
                    result.append(c)
                }
                return .keyword(String(result))

            default: // Unexpected
                return .unknown(c0)
            }
        }

        return nil
    }
}

internal extension WASTLexer {
    mutating func consumeNumber(from c0: UnicodeScalar) -> WASTLexicalToken? {
        var c0 = c0
        var (isPositive, isHex): (Bool?, Bool)
        (isPositive, c0) = consumeSign(from: c0)
        (isHex, c0) = consumeHexPrefix(from: c0)
        return consumeNumber(from: c0, positive: isPositive, hex: isHex)
    }

    mutating func consumeSign(from c0: UnicodeScalar) -> (Bool?, UnicodeScalar) {
        let (c1, _) = stream.look()
        switch (c0, c1) {
        case ("+", let c1?):
            _ = stream.next()
            return (true, c1)
        case ("-", let c1?):
            _ = stream.next()
            return (false, c1)
        default:
            return (nil, c0)
        }
    }

    mutating func consumeHexPrefix(from c0: UnicodeScalar) -> (Bool, UnicodeScalar) {
        let (c1, c2) = stream.look()
        switch (c0, c1, c2) {
        case ("0", "x"?, let c2?) where CharacterSet.hexDigits.contains(c2):
            _ = stream.next(); _ = stream.next()
            return (true, c2)
        default:
            return (false, c0)
        }
    }

    mutating func consumeNumber(from c0: UnicodeScalar, positive: Bool?, hex: Bool) -> WASTLexicalToken? {
        var result: WASTLexicalToken = positive == nil ? .unsigned(0) : .signed(0)

        var c0 = c0
        var (c1, c2): (UnicodeScalar?, UnicodeScalar?)
        while true {
            (c1, c2) = stream.look()

            switch (result, c0, c1, c2) {
            case let (.unsigned(n), CharacterSet.decimalDigits, _, _) where !hex,
                 let (.unsigned(n), CharacterSet.hexDigits, _, _) where hex:
                result = .unsigned(n * (!hex ? 10 : 16) + UInt(c0, hex: hex)!)

            case let (.signed(n), CharacterSet.decimalDigits, _, _) where !hex,
                 let (.signed(n), CharacterSet.hexDigits, _, _) where hex:
                result = positive == false
                    ? .signed(-(abs(n) * (!hex ? 10 : 16) + Int(c0, hex: hex)!))
                    : .signed(n * (!hex ? 10 : 16) + Int(c0, hex: hex)!)

            case let (.floating(n), CharacterSet.decimalDigits, _, _) where !hex,
                 let (.floating(n), CharacterSet.hexDigits, _, _) where hex:
                var p: Double = 1
                while abs((n * p).remainder(dividingBy: 1)) >= Double.ulpOfOne * p {
                    p *= !hex ? 10 : 16
                }
                p *= !hex ? 10 : 16

                let frac = Double(c0, hex: hex)! / p
                result = positive == false
                    ? .floating(-(abs(Double(n)) + frac))
                    : .floating(Double(n) + frac)

            case (_, "i", "n"?, "f"?):
                _ = stream.next(); _ = stream.next()
                return .floating(positive == false ? -Double.infinity : Double.infinity)

            default:
                return .unknown(c0)
            }

            func skip(_ c: UnicodeScalar) {
                c0 = c
                _ = stream.next()
            }

            guard let c1 = c1 else { return result }

            switch (result, c1, c2, hex) {
            case (_, "_", let c2?, false) where CharacterSet.decimalDigits.contains(c2),
                 (_, "_", let c2?, true) where CharacterSet.hexDigits.contains(c2):
                _ = stream.next()
                skip(c2)

            case (let .unsigned(n), ".", let c2?, false) where CharacterSet.decimalDigits.contains(c2),
                 (let .unsigned(n), ".", let c2?, true) where CharacterSet.hexDigits.contains(c2):
                result = .floating(Double(n))
                _ = stream.next()
                skip(c2)

            case (let .signed(n), ".", let c2?, false) where CharacterSet.decimalDigits.contains(c2),
                 (let .signed(n), ".", let c2?, true) where CharacterSet.hexDigits.contains(c2):
                result = .floating(Double(n))
                _ = stream.next()
                skip(c2)

            case (_, CharacterSet.decimalDigits, _, false),
                 (_, CharacterSet.hexDigits, _, true),
                 (_, "i", _, _):
                skip(c1)

            default:
                return result
            }
        }
    }
}

internal extension WASTLexer {
    mutating func consumeCharacter() -> UnicodeScalar? {
        guard let c0 = stream.next() else { return nil }
        let (c1, c2) = stream.look()

        switch (c0, c1, c2) {
        case ("\\", "t"?, _):
            _ = stream.next()
            return "\t"
        case ("\\", "n"?, _):
            _ = stream.next()
            return "\n"
        case ("\\", "r"?, _):
            _ = stream.next()
            return "\r"

        case ("\\", "\""?, _),
             ("\\", "'"?, _),
             ("\\", "\\"?, _):
            _ = stream.next()
            return c1!

        case ("\"", _, _):
            return nil

        case let ("\\", c1?, c2?) where CharacterSet.hexDigits.contains(c1) && CharacterSet.hexDigits.contains(c2):
            var codes: [UTF8.CodeUnit] = [UTF8.CodeUnit(c1, hex: true)! << 4 + UTF8.CodeUnit(c2, hex: true)!]
            _ = stream.next(); _ = stream.next() // skip c1 and c2
            while stream.next() == "\\", case let (c1?, c2?) = stream.look() {
                codes.append(UTF8.CodeUnit(c1, hex: true)! << 4 + UTF8.CodeUnit(c2, hex: true)!)
                _ = stream.next(); _ = stream.next()
            }
            var codeIterator = codes.makeIterator()
            var decoder = UTF8()
            guard case let .scalarValue(v) = decoder.decode(&codeIterator) else {
                return nil
            }
            return v

        case ("\\", "u"?, "{"?):
            _ = stream.next(); _ = stream.next() // skip "u" and "{"
            guard let c = stream.next() else { return nil }
            guard case let .unsigned(hexNumber)? = consumeNumber(from: c, positive: nil, hex: true) else { return nil }
            guard let scalar = UnicodeScalar(UInt32(hexNumber)) else { return nil }
            _ = stream.next() // skip "}"
            return scalar
        default:
            return c0
        }
    }
}

internal extension CharacterSet {
    static var keywordPrefixes: CharacterSet {
        return CharacterSet().with("a" ... "z")
    }

    static var IDCharacters: CharacterSet {
        return CharacterSet()
            .with("0" ... "9", "a" ... "z", "A" ... "Z")
            .with("!", "#", "$", "%", "&", "`", "*", "+", "-", ".", "/",
                  ":", "<", "=", ">", "?", "@", "\\", "^", "_", "`", ",", "~")
    }

    static var signs: CharacterSet {
        return CharacterSet().with("+", "-")
    }

    static var decimalDigits: CharacterSet {
        return CharacterSet().with("0" ... "9")
    }

    static var hexDigits: CharacterSet {
        return CharacterSet().with("0" ... "9", "a" ... "f", "A" ... "F")
    }
}