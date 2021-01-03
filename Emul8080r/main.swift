import Foundation

let romPath = CommandLine.arguments[1]

let data = try! Data(contentsOf: URL(fileURLWithPath: romPath))

let disassembler = Disassembler(data: data)

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

    var instructionCount = 0

    while state.pc < state.memory.count {
        instructionCount += 1

        guard let code = OpCode(rawValue: state.memory[Int(state.pc)]) else {
            throw DisassemblerError.unknownCode(String(format: "%02x", state.memory[Int(state.pc)]))
        }

        try _ = disassembler.disassembleOpCode(from: data, offset: Int(state.pc))

        switch code {
        case .nop:
            break
        case .dcr_b:
            let (overflow, _) = state.registers.b.subtractingReportingOverflow(1)
            updateConditionBits(Int(overflow), state: &state)
            state.registers.b = overflow
        case .dcr_d:
            let (overflow, _) = state.registers.d.subtractingReportingOverflow(1)
            updateConditionBits(Int(overflow), state: &state)
            state.registers.d = overflow
        case .mvi_b:
            state.registers.b = UInt8("\(state.memory[state.pc + 1].hex)", radix: 16)!
        case .dad_b_c:
            let bc = UInt32(state.registers.b << 8 | state.registers.c)
            let hl = UInt32(state.registers.h << 8 | state.registers.l)

            let result = bc + hl

            state.registers.h = UInt8((result >> 8) & 0xff)
            state.registers.l = UInt8(result & 0xff)
            state.condition_bits.carry = UInt8((result & 0xffff0000) > 0)
        case .rrc:
            throw EmulationError.unhandledOperation(code)
        case .lxi_d_e:
            state.registers.e = state.memory[state.pc + 1]
            state.registers.d = state.memory[state.pc + 2]
        case .inx_d_e:
            var value = Int("\(state.registers.d.hex)\(state.registers.e.hex)", radix: 16)!
            value += 1
            state.registers.d = UInt8((value >> 8) & 0xff)
            state.registers.e = UInt8(value & 0xff)
        case .dad_d_e:
            let bc = UInt32(state.registers.d << 8 | state.registers.e)
            let hl = UInt32(state.registers.h << 8 | state.registers.l)

            let result = bc + hl

            state.registers.h = UInt8((result >> 8) & 0xff)
            state.registers.l = UInt8(result & 0xff)
            state.condition_bits.carry = UInt8((result & 0xffff0000) > 0)
        case .ldax_d_e:
            let address = "\(state.registers.d.hex)\(state.registers.e.hex)"
            state.registers.a = state.memory[Int(address, radix: 16)!]
        case .lxi_h_l:
            state.registers.l = state.memory[state.pc + 1]
            state.registers.h = state.memory[state.pc + 2]
        case .shld:
            throw EmulationError.unhandledOperation(code)
        case .inx_h_l:
            var value = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            value += 1
            state.registers.h = UInt8((value >> 8) & 0xff)
            state.registers.l = UInt8(value & 0xff)
        case .daa:
            throw EmulationError.unhandledOperation(code)
        case .dad_h_l:
            // double HL (multiply by 2, left shift one position)
            throw EmulationError.unhandledOperation(code)
        case .dcx_h_l:
            throw EmulationError.unhandledOperation(code)
        case .lxi_sp:
            state.sp = Int("\(state.memory[state.pc + 2].hex)\(state.memory[state.pc + 1].hex)", radix: 16)!
        case .sta:
            let address = Int("\(state.memory[state.pc + 2].hex)\(state.memory[state.pc + 1].hex)", radix: 16)!
            state.memory[address] = state.registers.a
        case .dcr_m:
            throw EmulationError.unhandledOperation(code)
        case .lda:
            let address = Int("\(state.memory[state.pc + 2].hex)\(state.memory[state.pc + 1].hex)", radix: 16)!
            state.registers.a = state.memory[address]
        case .mvi_a:
            state.registers.a = UInt8("\(state.memory[state.pc + 1].hex)", radix: 16)!
        case .mov_d_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.d = state.memory[Int(offset, radix: 16)!]
        case .mov_e_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.e = state.memory[Int(offset, radix: 16)!]
        case .mov_h_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.h = state.memory[Int(offset, radix: 16)!]
        case .mov_l_a:
            state.registers.l = state.registers.a
        case .mov_m_a:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            state.memory[offset] = state.registers.a
        case .mov_a_d:
            state.registers.a = state.registers.d
        case .mov_a_e:
            state.registers.a = state.registers.e
        case .mov_a_h:
            state.registers.a = state.registers.h
        case .mov_a_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.a = state.memory[Int(offset, radix: 16)!]
        case .ana_b:
            throw EmulationError.unhandledOperation(code)
        case .ana_c:
            throw EmulationError.unhandledOperation(code)
        case .ana_d:
            throw EmulationError.unhandledOperation(code)
        case .ana_e:
            throw EmulationError.unhandledOperation(code)
        case .ana_h:
            throw EmulationError.unhandledOperation(code)
        case .ana_l:
            throw EmulationError.unhandledOperation(code)
        case .ana_m:
            throw EmulationError.unhandledOperation(code)
        case .ana_a:
            state.registers.a &= state.registers.a
            state.condition_bits.carry = 0
            updateConditionBits(Int(state.registers.a), state: &state)
        case .xra_a:
            state.registers.a ^= state.registers.a
            state.condition_bits.carry = 0
            updateConditionBits(Int(state.registers.a), state: &state)
        case .pop_b:
            throw EmulationError.unhandledOperation(code)
        case .jnz:
            if state.condition_bits.zero == 0 {
                state.pc = Int("\(state.memory[state.pc + 2].hex)\(state.memory[state.pc + 1].hex)", radix: 16)!
                continue
            }
        case .jmp:
            state.pc = Int("\(state.memory[state.pc + 2].hex)\(state.memory[state.pc + 1].hex)", radix: 16)!
            continue
        case .push_b:
            throw EmulationError.unhandledOperation(code)
        case .adi:
            throw EmulationError.unhandledOperation(code)
        case .ret:
            let low = state.memory[state.sp]
            let high = state.memory[state.sp + 1]
            state.sp = state.sp - 2
            state.pc = Int("\(high.hex)\(low.hex)", radix: 16)!
        case .jz:
            if state.condition_bits.zero == 1 {
                state.pc = Int("\(state.memory[state.pc + 2].hex)\(state.memory[state.pc + 1].hex)", radix: 16)!
                continue
            }
        case .call:
            let returnAddress = state.pc + code.size
            state.memory[state.sp - 1] = UInt8((returnAddress >> 8) & 0xff)
            state.memory[state.sp - 2] = UInt8(returnAddress & 0xff)
            state.sp = state.sp - 2
            state.pc = Int("\(state.memory[state.pc + 2].hex)\(state.memory[state.pc + 1].hex)", radix: 16)!
            continue
        case .pop_d:
            throw EmulationError.unhandledOperation(code)
        case .jnc:
            throw EmulationError.unhandledOperation(code)
        case .out:
            // TODO: Review the output hardware codes for sound etc
            break
        case .push_d:
            throw EmulationError.unhandledOperation(code)
        case .jc:
            throw EmulationError.unhandledOperation(code)
        case .in:
            throw EmulationError.unhandledOperation(code)
        case .pop_h:
            throw EmulationError.unhandledOperation(code)
        case .push_h:
            throw EmulationError.unhandledOperation(code)
        case .xchg:
            throw EmulationError.unhandledOperation(code)
        case .pop_psw:
            throw EmulationError.unhandledOperation(code)
        case .push_psw:
            throw EmulationError.unhandledOperation(code)
        case .ei:
            throw EmulationError.unhandledOperation(code)
        case .cpi:
            throw EmulationError.unhandledOperation(code)
        }

        state.pc += code.size
    }
}

func updateConditionBits(_ value: Int, state: inout State8080) {
    state.condition_bits.zero = UInt8(value == 0)
    state.condition_bits.sign = UInt8(0x80 == (value & 0x80))
    state.condition_bits.parity = parity(Int(value))
}

// todo: optimise
func parity(_ value: Int) -> UInt8 {
    let binary = String(value, radix: 2)
    return UInt8(binary.filter { $0 == "1" }.count % 2 == 0)
}

try emulate(rom: data)

extension UInt8 {
    var hex: String {
        String(format: "%02x", self)
    }

    init(_ value: Bool) {
        self = value ? 1 : 0
    }
}
