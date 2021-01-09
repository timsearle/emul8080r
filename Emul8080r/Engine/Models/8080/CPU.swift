import Foundation

public class CPU {
    enum Error: Swift.Error {
        case unhandledOperation(OpCode)
        case cannotWriteToROM(Int)
    }

    var machineIn: ((_ port: UInt8) -> UInt8)?
    var machineOut: ((_ port: UInt8, _ accumulator: UInt8) -> Void)?

    var state: State8080
    private var disassembler: Disassembler!
    private let loggingEnabled: Bool

    var memory: [UInt8]

    public init(memory: [UInt8], state: State8080 = State8080(), loggingEnabled: Bool = false) {
        self.memory = memory
        self.state = state
        self.loggingEnabled = loggingEnabled
    }

    public func load(_ data: Data) {
        for (offset, byte) in data.enumerated() {
            memory[offset] = byte
        }

        disassembler = Disassembler(data: data)
    }

    public func interrupt(_ value: Int) throws {
        if state.inte == 0x01 {
            state.inte = 0x00 // Reset the interrupt to disabled
            try push(high: UInt8((state.pc >> 8) & 0xff), low: UInt8(state.pc & 0xff))
            state.pc = 8 * value
        }
    }

    public func start(previousExecutionTime: TimeInterval, interruptProvider: () -> Void) throws -> TimeInterval {
        interruptProvider()

        let now = Date().timeIntervalSince1970
        let sinceLast = (now - previousExecutionTime)*1000
        let cycles_to_catch_up = Int(2 * sinceLast)
        var cycles = 0

        while cycles_to_catch_up > cycles {
            cycles += try execute()
        }

        return now
    }

    public func execute() throws -> Int {
        guard let code = OpCode(rawValue: memory[Int(state.pc)]) else {
            throw Disassembler.Error.unknownCode(String(format: "%02x", memory[Int(state.pc)]))
        }

        if loggingEnabled {
            try _ = disassembler.disassembleOpCode(offset: Int(state.pc))
        }

        switch code {
        case .nop:
            break
        case .lxi_b_c:
            state.registers.c = memory[state.pc + 1]
            state.registers.b = memory[state.pc + 2]
        case .inx_b_c:
            var value = Int("\(state.registers.b.hex)\(state.registers.c.hex)", radix: 16)!
            value += 1
            state.registers.b = UInt8((value >> 8) & 0xff)
            state.registers.c = UInt8(value & 0xff)
        case .dcr_b:
            let (overflow, _) = state.registers.b.subtractingReportingOverflow(1)
            updateConditionBits(Int(overflow), state: &state)
            state.registers.b = overflow
        case .mvi_b:
            state.registers.b = memory[state.pc + 1]
        case .dad_b_c:
            let bc = Int("\(state.registers.b.hex)\(state.registers.c.hex)", radix: 16)!
            let hl = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!

            let result = bc + hl

            state.registers.h = UInt8((result & 0xff00) >> 8)
            state.registers.l = UInt8(result & 0xff)
            state.condition_bits.carry = UInt8((result & 0xffff0000) > 0)
        case .ldax_b_c:
            let address = "\(state.registers.b.hex)\(state.registers.c.hex)"
            state.registers.a = memory[Int(address, radix: 16)!]
        case .dcr_c:
            let (overflow, _) = state.registers.c.subtractingReportingOverflow(1)
            updateConditionBits(Int(overflow), state: &state)
            state.registers.c = overflow
        case .mvi_c:
            state.registers.c = memory[state.pc + 1]
        case .rrc:
            let accumulator = state.registers.a
            state.registers.a = ((accumulator & 1) << 7) | accumulator >> 1
            state.condition_bits.carry = state.registers.a & 0x01
        case .lxi_d_e:
            state.registers.e = memory[state.pc + 1]
            state.registers.d = memory[state.pc + 2]
        case .inx_d_e:
            var value = Int("\(state.registers.d.hex)\(state.registers.e.hex)", radix: 16)!
            value += 1
            state.registers.d = UInt8((value >> 8) & 0xff)
            state.registers.e = UInt8(value & 0xff)
        case .dad_d_e:
            let de = Int("\(state.registers.d.hex)\(state.registers.e.hex)", radix: 16)!
            let hl = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!

            let result = de + hl

            state.registers.h = UInt8((result & 0xff00) >> 8)
            state.registers.l = UInt8(result & 0xff)
            state.condition_bits.carry = UInt8((result & 0xffff0000) > 0)
        case .ldax_d_e:
            let address = "\(state.registers.d.hex)\(state.registers.e.hex)"
            state.registers.a = memory[Int(address, radix: 16)!]
        case .lxi_h_l:
            state.registers.l = memory[state.pc + 1]
            state.registers.h = memory[state.pc + 2]
        case .shld:
            throw Error.unhandledOperation(code)
        case .inx_h_l:
            var value = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            value += 1
            state.registers.h = UInt8((value >> 8) & 0xff)
            state.registers.l = UInt8(value & 0xff)
        case .daa:
            throw Error.unhandledOperation(code)
        case .mvi_h:
            state.registers.h = memory[state.pc + 1]
        case .dad_h_l:
            let result = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)! * 2
            state.registers.h = UInt8((result & 0xff00) >> 8)
            state.registers.l = UInt8(result & 0xff)
            state.condition_bits.carry = UInt8((result & 0xffff0000) > 0)
        case .dcx_h_l:
            throw Error.unhandledOperation(code)
        case .lxi_sp:
            state.sp = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
        case .sta:
            let address = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
            try write(state.registers.a, at: address)
        case .dcr_m:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            let (overflow, _) = UInt8(memory[offset]).subtractingReportingOverflow(1)
            try write(overflow, at: offset)
            updateConditionBits(Int(overflow), state: &state)
        case .mvi_m:
            let address = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            try write(memory[state.pc + 1], at: address)
        case .stc:
            state.condition_bits.carry = 1
        case .lda:
            let address = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
            state.registers.a = memory[address]
        case .dcr_a:
            let (overflow, _) = state.registers.a.subtractingReportingOverflow(1)
            updateConditionBits(Int(overflow), state: &state)
            state.registers.a = overflow
        case .mvi_a:
            state.registers.a = memory[state.pc + 1]
        case .mov_b_b:
            break
        case .mov_b_c:
            state.registers.b = state.registers.c
        case .mov_b_d:
            state.registers.b = state.registers.d
        case .mov_b_e:
            state.registers.b = state.registers.e
        case .mov_b_h:
            state.registers.b = state.registers.h
        case .mov_b_l:
            state.registers.b = state.registers.l
        case .mov_b_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.b = memory[Int(offset, radix: 16)!]
        case .mov_b_a:
            state.registers.b = state.registers.a
        case .mov_c_b:
            state.registers.c = state.registers.b
        case .mov_c_c:
            break
        case .mov_c_d:
            state.registers.c = state.registers.d
        case .mov_c_e:
            state.registers.c = state.registers.e
        case .mov_c_h:
            state.registers.c = state.registers.h
        case .mov_c_l:
            state.registers.c = state.registers.l
        case .mov_c_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.c = memory[Int(offset, radix: 16)!]
        case .mov_c_a:
            state.registers.c = state.registers.a
        case .mov_d_b:
            state.registers.d = state.registers.b
        case .mov_d_c:
            state.registers.d = state.registers.c
        case .mov_d_d:
            break
        case .mov_d_e:
            state.registers.d = state.registers.e
        case .mov_d_h:
            state.registers.d = state.registers.h
        case .mov_d_l:
            state.registers.d = state.registers.l
        case .mov_d_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.d = memory[Int(offset, radix: 16)!]
        case .mov_d_a:
            state.registers.d = state.registers.a
        case .mov_e_b:
            state.registers.e = state.registers.b
        case .mov_e_c:
            state.registers.e = state.registers.c
        case .mov_e_d:
            state.registers.e = state.registers.d
        case .mov_e_e:
            break
        case .mov_e_h:
            state.registers.e = state.registers.h
        case .mov_e_l:
            state.registers.e = state.registers.l
        case .mov_e_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.e = memory[Int(offset, radix: 16)!]
        case .mov_e_a:
            state.registers.e = state.registers.a
        case .mov_h_b:
            state.registers.h = state.registers.b
        case .mov_h_c:
            state.registers.h = state.registers.c
        case .mov_h_d:
            state.registers.h = state.registers.d
        case .mov_h_e:
            state.registers.h = state.registers.e
        case .mov_h_h:
            break
        case .mov_h_l:
            state.registers.h = state.registers.l
        case .mov_h_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.h = memory[Int(offset, radix: 16)!]
        case .mov_h_a:
            state.registers.h = state.registers.a
        case .mov_l_b:
            state.registers.l = state.registers.b
        case .mov_l_c:
            state.registers.l = state.registers.c
        case .mov_l_d:
            state.registers.l = state.registers.d
        case .mov_l_e:
            state.registers.l = state.registers.e
        case .mov_l_h:
            state.registers.l = state.registers.h
        case .mov_l_l:
            break
        case .mov_l_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.l = memory[Int(offset, radix: 16)!]
        case .mov_l_a:
            state.registers.l = state.registers.a
        case .mov_m_b:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            try write(state.registers.b, at: offset)
        case .mov_m_c:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            try write(state.registers.c, at: offset)
        case .mov_m_d:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            try write(state.registers.d, at: offset)
        case .mov_m_e:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            try write(state.registers.e, at: offset)
        case .mov_m_h:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            try write(state.registers.h, at: offset)
        case .mov_m_l:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            try write(state.registers.l, at: offset)
        case .mov_m_a:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            try write(state.registers.a, at: offset)
        case .mov_a_b:
            state.registers.a = state.registers.b
        case .mov_a_c:
            state.registers.a = state.registers.c
        case .mov_a_d:
            state.registers.a = state.registers.d
        case .mov_a_e:
            state.registers.a = state.registers.e
        case .mov_a_h:
            state.registers.a = state.registers.h
        case .mov_a_l:
            state.registers.a = state.registers.l
        case .mov_a_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.a = memory[Int(offset, radix: 16)!]
        case .mov_a_a:
            break
        case .add_b:
            let result = UInt16(state.registers.a + state.registers.b)
            state.registers.a = UInt8(result & 0xff)
            updateConditionBits(Int(state.registers.a), state: &state)
            state.condition_bits.carry = UInt8(result > 0xff)
        case .add_c:
            let result = UInt16(state.registers.a + state.registers.c)
            state.registers.a = UInt8(result & 0xff)
            updateConditionBits(Int(state.registers.a), state: &state)
            state.condition_bits.carry = UInt8(result > 0xff)
        case .add_d:
            let result = UInt16(state.registers.a + state.registers.d)
            state.registers.a = UInt8(result & 0xff)
            updateConditionBits(Int(state.registers.a), state: &state)
            state.condition_bits.carry = UInt8(result > 0xff)
        case .add_e:
            let result = UInt16(state.registers.a + state.registers.e)
            state.registers.a = UInt8(result & 0xff)
            updateConditionBits(Int(state.registers.a), state: &state)
            state.condition_bits.carry = UInt8(result > 0xff)
        case .add_h:
            let result = UInt16(state.registers.a + state.registers.h)
            state.registers.a = UInt8(result & 0xff)
            updateConditionBits(Int(state.registers.a), state: &state)
            state.condition_bits.carry = UInt8(result > 0xff)
        case .add_l:
            let result = UInt16(state.registers.a + state.registers.l)
            state.registers.a = UInt8(result & 0xff)
            updateConditionBits(Int(state.registers.a), state: &state)
            state.condition_bits.carry = UInt8(result > 0xff)
        case .add_m:
            let offset = UInt16((state.registers.h << 8) | state.registers.l)
            let result = UInt16(state.registers.a + memory[Int(offset)])
            state.registers.a = UInt8(result & 0xff)
            updateConditionBits(Int(state.registers.a), state: &state)
            state.condition_bits.carry = UInt8(result > 0xff)
        case .add_a:
            throw Error.unhandledOperation(code)
        case .ana_b:
            throw Error.unhandledOperation(code)
        case .ana_c:
            throw Error.unhandledOperation(code)
        case .ana_d:
            throw Error.unhandledOperation(code)
        case .ana_e:
            throw Error.unhandledOperation(code)
        case .ana_h:
            throw Error.unhandledOperation(code)
        case .ana_l:
            throw Error.unhandledOperation(code)
        case .ana_m:
            throw Error.unhandledOperation(code)
        case .ana_a:
            state.registers.a &= state.registers.a
            state.condition_bits.carry = 0
            updateConditionBits(Int(state.registers.a), state: &state)
        case .xra_a:
            state.registers.a ^= state.registers.a
            state.condition_bits.carry = 0
            updateConditionBits(Int(state.registers.a), state: &state)
        case .pop_b:
            let (high, low) = try pop()
            state.registers.b = high
            state.registers.c = low
        case .jnz:
            if state.condition_bits.zero == 0 {
                state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
                return code.cycleCount
            }
        case .jmp:
            state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
            return code.cycleCount
        case .push_b:
            try push(high: state.registers.b, low: state.registers.c)
        case .adi:
            // impacts condition bits
            let value = memory[state.pc + 1]
            let result = (UInt16(state.registers.a) + UInt16(value)) & 0xff
            state.registers.a = UInt8(result)
            updateConditionBits(Int(state.registers.a), state: &state)
            state.condition_bits.carry = UInt8(result > 0xff)
        case .rz:
            if state.condition_bits.zero == 1 {
                let (high, low) = try pop()
                state.pc = Int("\(high.hex)\(low.hex)", radix: 16)!
                return code.cycleCount
            }
        case .ret:
            let (high, low) = try pop()
            state.pc = Int("\(high.hex)\(low.hex)", radix: 16)!
            return code.cycleCount
        case .jz:
            if state.condition_bits.zero == 1 {
                state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
                return code.cycleCount
            }
        case .call:
            let returnAddress = state.pc + code.size
            try push(high: UInt8((returnAddress >> 8) & 0xff), low: UInt8(returnAddress & 0xff))
            state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
            return code.cycleCount
        case .pop_d:
            let (high, low) = try pop()
            state.registers.d = high
            state.registers.e = low
        case .jnc:
            if state.condition_bits.carry == 0 {
                state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
                return code.cycleCount
            }
        case .out:
            let accumulator = state.registers.a
            let port = memory[state.pc + 1]
            machineOut?(port, accumulator)
        case .push_d:
            try push(high: state.registers.d, low: state.registers.e)
        case .ret_c:
            if state.condition_bits.carry == 1 {
                let (high, low) = try pop()
                state.pc = Int("\(high.hex)\(low.hex)", radix: 16)!
                return code.cycleCount
            }
        case .jc:
            if state.condition_bits.carry == 1 {
                state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
                return code.cycleCount
            }
        case .in:
            let device = memory[state.pc + 1]
            state.registers.a = machineIn?(device) ?? state.registers.a
        case .pop_h:
            let (high, low) = try pop()
            state.registers.h = high
            state.registers.l = low
        case .push_h:
            try push(high: state.registers.h, low: state.registers.l)
        case .ani:
            state.registers.a = state.registers.a & memory[state.pc + 1]
            state.condition_bits.carry = 0
            updateConditionBits(Int(state.registers.a), state: &state)
        case .xchg:
            let h = state.registers.h
            let l = state.registers.l
            let d = state.registers.d
            let e = state.registers.e

            state.registers.h = d
            state.registers.l = e
            state.registers.d = h
            state.registers.e = l
        case .pop_psw:
            let (high, low) = try pop()
            state.registers.a = high
            state.updateConditionBits(low)
        case .di:
            state.inte = 0x00
        case .push_psw:
            try push(high: state.registers.a, low: state.condition_bits.byte)
        case .ei:
            state.inte = 0x01
        case .cpi:
            let accumulator = Int(state.registers.a)
            let value = Int(memory[state.pc + 1])

            state.condition_bits.carry = UInt8(accumulator < value)
            updateConditionBits(accumulator - value, state: &state)
        }

        state.pc += code.size

        return code.cycleCount
    }

    private func updateConditionBits(_ value: Int, state: inout State8080) {
        state.condition_bits.zero = UInt8(value == 0)
        state.condition_bits.sign = UInt8(0x80 == (value & 0x80))
        state.condition_bits.parity = parity(Int(value))
    }

    private func parity(_ value: Int) -> UInt8 {
        let binary = String(value, radix: 2)
        return UInt8(binary.filter { $0 == "1" }.count % 2 == 0)
    }

    private func push(high: UInt8, low: UInt8) throws {
        try write(high, at: state.sp - 1)
        try write(low, at: state.sp - 2)
        state.sp -= 2
    }

    private func pop() throws -> (UInt8, UInt8) {
        let high = memory[state.sp + 1]
        let low = memory[state.sp]
        state.sp += 2

        return (high, low)
    }

    private func write(_ value: UInt8, at address: Int) throws {
        // validate not writing to ROM
        guard address >= 0x2000 else {
            throw Error.cannotWriteToROM(address)
        }

        memory[address] = value
    }

}
