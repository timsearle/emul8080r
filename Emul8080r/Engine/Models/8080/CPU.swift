import Foundation

public class CPU {
    enum Error: Swift.Error {
        case unhandledOperation(OpCode)
    }

    var machineIn: ((_ port: UInt8) -> UInt8)?
    var machineOut: ((_ port: UInt8, _ accumulator: UInt8) -> Void)?

    private var state = State8080()
    private var disassembler: Disassembler!
    private let loggingEnabled: Bool

    var memory: [UInt8]

    public init(memory: [UInt8], loggingEnabled: Bool = false) {
        self.memory = memory
        self.loggingEnabled = loggingEnabled
    }

    public func load(_ data: Data) {
        for (offset, byte) in data.enumerated() {
            memory[offset] = byte
        }

        disassembler = Disassembler(data: data)
    }

    public func interrupt(_ value: Int) {
        if state.inte == 0x01 {
            state.inte = 0x00 // Reset the interrupt to disabled
            memory[state.sp - 1] = UInt8((state.pc >> 8) & 0xff)
            memory[state.sp - 2] = UInt8(state.pc & 0xff)
            state.sp = state.sp - 2
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
        if state.pc == 0x076D {
            print("")
        }
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
            throw Error.unhandledOperation(code)
        case .dcr_b:
            let (overflow, _) = state.registers.b.subtractingReportingOverflow(1)
            updateConditionBits(Int(overflow), state: &state)
            state.registers.b = overflow
        case .mvi_b:
            state.registers.b = memory[state.pc + 1]
        case .dad_b_c:
            let bc = UInt32(state.registers.b << 8 | state.registers.c)
            let hl = UInt32(state.registers.h << 8 | state.registers.l)

            let result = bc + hl

            state.registers.h = UInt8((result & 0xff00) >> 8)
            state.registers.l = UInt8(result & 0xff)
            state.condition_bits.carry = UInt8((result & 0xffff0000) > 0)
        case .dcr_c:
            let (overflow, _) = state.registers.c.subtractingReportingOverflow(1)
            updateConditionBits(Int(overflow), state: &state)
            state.registers.c = overflow
        case .mvi_c:
            state.registers.c = memory[state.pc + 1]
        case .rrc:
            throw Error.unhandledOperation(code)
        case .lxi_d_e:
            state.registers.e = memory[state.pc + 1]
            state.registers.d = memory[state.pc + 2]
        case .inx_d_e:
            var value = Int("\(state.registers.d.hex)\(state.registers.e.hex)", radix: 16)!
            value += 1
            state.registers.d = UInt8((value >> 8) & 0xff)
            state.registers.e = UInt8(value & 0xff)
        case .dad_d_e:
            let de = UInt32(state.registers.d << 8 | state.registers.e)
            let hl = UInt32(state.registers.h << 8 | state.registers.l)

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
            let result = UInt32(state.registers.h << 8 | state.registers.l) * 2
            state.registers.h = UInt8((result & 0xff00) >> 8)
            state.registers.l = UInt8(result & 0xff)
            state.condition_bits.carry = UInt8((result & 0xffff0000) > 0)
        case .dcx_h_l:
            throw Error.unhandledOperation(code)
        case .lxi_sp:
            state.sp = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
        case .sta:
            let address = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
            memory[address] = state.registers.a
        case .dcr_m:
            throw Error.unhandledOperation(code)
        case .mvi_m:
            throw Error.unhandledOperation(code)
        case .lda:
            let address = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
            state.registers.a = memory[address]
        case .mvi_a:
            state.registers.a = memory[state.pc + 1]
        case .mov_d_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.d = memory[Int(offset, radix: 16)!]
        case .mov_e_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.e = memory[Int(offset, radix: 16)!]
        case .mov_h_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.h = memory[Int(offset, radix: 16)!]
        case .mov_l_a:
            state.registers.l = state.registers.a
        case .mov_m_a:
            let offset = Int("\(state.registers.h.hex)\(state.registers.l.hex)", radix: 16)!
            memory[offset] = state.registers.a
        case .mov_a_d:
            state.registers.a = state.registers.d
        case .mov_a_e:
            state.registers.a = state.registers.e
        case .mov_a_h:
            state.registers.a = state.registers.h
        case .mov_a_m:
            let offset = "\(state.registers.h.hex)\(state.registers.l.hex)"
            state.registers.a = memory[Int(offset, radix: 16)!]
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
            state.registers.b = memory[state.sp + 1]
            state.registers.c = memory[state.sp]
            state.sp = state.sp + 2
        case .jnz:
            if state.condition_bits.zero == 0 {
                state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
                return code.cycleCount
            }
        case .jmp:
            state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
            return code.cycleCount
        case .push_b:
            let b = state.registers.b
            let c = state.registers.c
            memory[state.sp - 1] = b
            memory[state.sp - 2] = c
            state.sp = state.sp - 2
        case .adi:
            // impacts condition bits
            throw Error.unhandledOperation(code)
        case .ret:
            let low = memory[state.sp]
            let high = memory[state.sp + 1]
            state.sp = state.sp + 2
            state.pc = Int("\(high.hex)\(low.hex)", radix: 16)!
        case .jz:
            if state.condition_bits.zero == 1 {
                state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
                return code.cycleCount
            }
        case .call:
            let returnAddress = state.pc + code.size
            memory[state.sp - 1] = UInt8((returnAddress >> 8) & 0xff)
            memory[state.sp - 2] = UInt8(returnAddress & 0xff)
            state.sp = state.sp - 2
            state.pc = Int("\(memory[state.pc + 2].hex)\(memory[state.pc + 1].hex)", radix: 16)!
            return code.cycleCount
        case .pop_d:
            state.registers.d = memory[state.sp + 1]
            state.registers.e = memory[state.sp]
            state.sp = state.sp + 2
        case .jnc:
            throw Error.unhandledOperation(code)
        case .out:
            let accumulator = state.registers.a
            let port = memory[state.pc + 1]
            machineOut?(port, accumulator)
        case .push_d:
            let d = state.registers.d
            let e = state.registers.e
            memory[state.sp - 1] = d
            memory[state.sp - 2] = e
            state.sp = state.sp - 2
        case .jc:
            throw Error.unhandledOperation(code)
        case .in:
            let device = memory[state.pc + 1]
            state.registers.a = machineIn?(device) ?? state.registers.a
        case .pop_h:
            state.registers.h = memory[state.sp + 1]
            state.registers.l = memory[state.sp]
            state.sp = state.sp + 2
        case .push_h:
            let h = state.registers.h
            let l = state.registers.l
            memory[state.sp - 1] = h
            memory[state.sp - 2] = l
            state.sp = state.sp - 2
        case .ani:
            state.registers.a = state.registers.a & memory[state.pc + 1]
            state.condition_bits.carry = 0
            updateConditionBits(Int(state.registers.a), state: &state)
        case .xchg:
            throw Error.unhandledOperation(code)
        case .pop_psw:
            state.registers.a = memory[state.sp + 1]
            state.updateConditionBits(memory[state.sp])
            state.sp = state.sp + 2
        case .di:
            state.inte = 0x00
        case .push_psw:
            let accumulator = state.registers.a
            let condition_byte = state.condition_bits.byte
            memory[state.sp - 1] = accumulator
            memory[state.sp - 2] = condition_byte
            state.sp = state.sp - 2
        case .ei:
            state.inte = 0x01
        case .cpi:
            // modifies z,s,p,cy,ac
            throw Error.unhandledOperation(code)
        }

        state.pc += code.size

        return code.cycleCount
    }

    private var lastInterruptTime = Date().timeIntervalSince1970
    private var nextInterrupt = 1
    private func simulateInterruptIfNeeded() {
        // Naive interrupt simulation
        let time = Date().timeIntervalSince1970

        if  time - lastInterruptTime > (1/60) && state.inte == 0x01 {
            interrupt(nextInterrupt)
            nextInterrupt = nextInterrupt == 1 ? 2 : 1
            lastInterruptTime = time
        }
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

}
