import Foundation

let romPath = CommandLine.arguments[1]

let data = try! Data(contentsOf: URL(fileURLWithPath: romPath))

// try Disassembler(data: data).run()

enum EmulationError: Error {
    case unhandledOperation(OpCode)
}

func load(_ data: Data, into state: inout State8080) {
    for (offset, byte) in data.enumerated() {
        state.memory[offset] = byte
    }
}

func emulate(rom: Data) throws {
    var state = State8080()
    load(rom, into: &state)

    while state.pc < state.memory.count {
        guard let code = OpCode(rawValue: state.memory[Int(state.pc)]) else {
            throw DisassemblerError.unknownCode(String(format: "%02x", state.memory[Int(state.pc)]))
        }

        print(code)

        switch code {
        case .nop:
            break
        default:
            throw EmulationError.unhandledOperation(code)
        }

        state.pc += 1
    }
}

try emulate(rom: data)
