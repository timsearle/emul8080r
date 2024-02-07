import Foundation

final class Assembler {
    enum Error: Swift.Error {
        case unhandledCode
        case invalidArgumentSize(line: Int, code: Code)
    }

    func assemble(program: String) throws -> Data {
        let instructions = program
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty && !$0.starts(with: ";") }

        return Data.init (
            try instructions
                .enumerated()
                .map { try processLine($0.element, lineNumber: $0.offset) }
                .flatMap { $0 }
        )
    }

    private func processLine(_ string: String, lineNumber: Int) throws -> [UInt8] {
        guard let instruction = try Instruction(string, line: lineNumber) else {
            return []
        }

        // TODO: Store LABEL in look-up table for addresses

        guard let code = instruction.code else {
            return []
        }

        switch code {
        case .MOV:
            guard let operands = instruction.operands, operands.count == 2 else {
                throw Error.invalidArgumentSize(line: lineNumber, code: code)
            }

            guard case let .register(dst) = operands[0], case let .register(src) = operands[1] else {
                throw Error.invalidArgumentSize(line: lineNumber, code: code)
            }

            return [64 | (dst.code << 3) | src.code]
        default:
            throw Error.unhandledCode
        }
    }
}

struct Instruction {
    enum Error: Swift.Error {
        case unknownCode(String, Int)
    }

    let label: (String, Int)?
    let code: Code?
    let operands: [Operand]?

    init?(_ statement: String, line: Int) throws {
        let tokens = statement
            .removingComment()
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)

        guard !tokens.isEmpty else {
            return nil
        }

        let first = tokens[0]

        if Instruction.isValidLabel(first) {
            label = (first, line)
            (code, operands) = try Instruction.extractCodeAndOperands(Array(tokens.dropFirst()), line: line)
        } else {
            label = nil
            (code, operands) = try Instruction.extractCodeAndOperands(tokens, line: line)
        }
    }

    private static func extractCodeAndOperands(_ string: [String], line: Int) throws -> (Code?, [Operand]?) {
        var resultCode: Code? = nil

        if string.count > 0 {
            let second = string[0]

            guard let code = Code(rawValue: second) else {
                throw Error.unknownCode(second, line)
            }

            resultCode = code
        }

        var resultOperands: [Operand]? = nil

        if string.count > 1 {
            resultOperands = try string[1].components(separatedBy: ",").map { try Operand($0.lowercased(), line: line) }
        }

        return (resultCode, resultOperands)
    }

    private static func isValidLabel(_ string: String) -> Bool {
        return false
    }
}

extension String {
    func removingComment() -> String {
        var trimmed = ""

        // Strip comments
        for character in self {
            guard character != ";" else {
                break
            }

            trimmed.append(character)
        }

        return trimmed
    }
}

enum Operand {
    enum Register: String, CaseIterable {
        case b
        case c
        case d
        case e
        case h
        case l
        case m
        case a

        var code: UInt8 {
            switch self {
            case .b:
                return 0
            case .c:
                return 1
            case .d:
                return 2
            case .e:
                return 3
            case .h:
                return 4
            case .l:
                return 5
            case .m:
                return 6
            case .a:
                return 7
            }
        }
    }

    enum RegisterPair: String, CaseIterable {
        case bc
        case de
        case hl

        // TODO
        var code: UInt8 {
            switch self {
            case .bc:
                return 0
            case .de:
                return 1
            case .hl:
                return 2
            }
        }
    }

    enum Error: Swift.Error {
        case unknownOperand(String, Int)
    }

    case register(Register)
    case registerPair(RegisterPair)
    case immediate(UInt8)
    case address(UInt16)

    init(_ value: String, line: Int) throws {
        if let register = Register(rawValue: value) {
            self = .register(register)
        } else if let registerPair = RegisterPair(rawValue: value) {
            self = .registerPair(registerPair)
        } else {
            throw Error.unknownOperand(value, line)
        }
    }
}

enum Code: String {
    case MOV
    case MVI
    case LXI
    case LDA
    case STA
    case LHLD
    case SHLD
    case LDAX
    case STAX
    case XCHG
    case ADD
    case ADI
    case ADC
    case ACI
    case SUB
    case SUI
    case SBB
    case SBI
    case INR
    case DCR
    case INX
    case DCX
    case DAD
    case DAA
    case ANA
    case ANI
    case ORA
    case ORI
    case XRA
    case XRI
    case CMP
    case CPI
    case RLC
    case RRC
    case RAL
    case RAR
    case CMA
    case CMC
    case STC
    case JMP
    case RET
    case RST
    case PCHL
    case PUSH
    case POP
    case XTHL
    case SPHL
    case IN
    case OUT
    case EI
    case DI
    case HLT
    case NOP
}
