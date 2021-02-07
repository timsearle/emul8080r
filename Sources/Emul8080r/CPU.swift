public protocol IOBus: AnyObject {
    func machineIN(port: UInt8) -> UInt8
    func machineOUT(port: UInt8, accumulator: UInt8)
}

public protocol SystemClock {
    func currentMicroseconds() -> Double
}

public final class CPU {
    public enum Error: Swift.Error {
        case missingIOHandler
        case unhandledOperation(OpCode)
        case cannotWriteToROM(Int)
        case unknownCode(String)
        case programTerminated
    }

    enum RegisterPair {
        case bc, de, hl
    }

    enum Register {
        case b, c, d, e, h, l, m, a
    }

    private let systemClock: SystemClock

    private var lastExecutionTime: Double = 0
    private var disassembler: Disassembler!

    public weak var bus: IOBus?

    public internal(set) var state = State8080()
    public internal(set) var memory: [UInt8]

    public init(memory: [UInt8], systemClock: SystemClock) {
        self.memory = memory
        self.systemClock = systemClock
    }

    public func load(_ data: [UInt8]) {
        for (offset, byte) in data.enumerated() {
            memory[offset] = byte
        }

        disassembler = Disassembler(data: data)
    }

    public func interrupt(_ value: UInt8) throws {
        guard state.inte == 0x01 else {
            return
        }

        state.inte = 0x00 // Reset the interrupt to disabled
        try push(high: UInt8((state.pc >> 8) & 0xff), low: UInt8(state.pc & 0xff))
        state.pc = Int(8 * value)
    }

    public func start(interrupter: () -> UInt8) throws {
        let now = systemClock.currentMicroseconds()

        if lastExecutionTime == 0.0 {
            lastExecutionTime = now
        }

        let sinceLast = (now - lastExecutionTime)
        let cycles_to_catch_up = min(Int(sinceLast),10000)
        var cycles = 0

        let code = interrupter()

        if code != 0 {
            try interrupt(code)
        } else {
            while cycles_to_catch_up > cycles {
                cycles += try execute()
            }
        }
        lastExecutionTime = now
    }

    private func execute() throws -> Int {
        guard state.pc < memory.count else {
            // End of program
            throw Error.programTerminated
        }

        guard let code = OpCode(rawValue: memory[Int(state.pc)]) else {
            throw Error.unknownCode(String(memory[Int(state.pc)], radix: 16))
        }

        switch code {
        case .nop:
            break
        case .lxi_b_c:
            writeImmediate(to: .bc)
        case .inx_b_c:
            let value = addressRegisterPair(state.registers.b, state.registers.c)
            let (result, _) = value.addingReportingOverflow(1)
            write(result, pair: .bc)
        case .inr_b:
            try increment(.b)
        case .dcr_b:
            try decrement(.b)
        case .mvi_b:
            state.registers.b = memory[state.pc + 1]
        case .rlc:
            let value = state.registers.a
            state.registers.a = ((value & 0x80) >> 7) | value << 1
            state.condition_bits.carry = UInt8((value & 0x80) == 0x80)
        case .dad_b_c:
            let bc = addressRegisterPair(state.registers.b, state.registers.c)
            let hl = addressRegisterPair(state.registers.h, state.registers.l)

            let (result, overflow) = bc.addingReportingOverflow(hl)

            write(result, pair: .hl)
            state.condition_bits.carry = UInt8(overflow)
        case .ldax_b_c:
            let address = Int(addressRegisterPair(state.registers.b, state.registers.c))
            state.registers.a = memory[address]
        case .inr_c:
            try increment(.c)
        case .dcr_c:
            try decrement(.c)
        case .mvi_c:
            state.registers.c = memory[state.pc + 1]
        case .rrc:
            let accumulator = state.registers.a
            state.registers.a = ((accumulator & 1) << 7) | accumulator >> 1
            state.condition_bits.carry = UInt8((accumulator & 0x01) == 0x01)
        case .lxi_d_e:
            writeImmediate(to: .de)
        case .stax_d_e:
            let address = addressRegisterPair(state.registers.d, state.registers.e)
            try write(state.registers.a, at: Int(address))
        case .inx_d_e:
            let value = addressRegisterPair(state.registers.d, state.registers.e)
            let (result, _) = value.addingReportingOverflow(1)
            write(result, pair: .de)
        case .inr_d:
            try increment(.d)
        case .dcr_d:
            try decrement(.d)
        case .mvi_d:
            state.registers.d = memory[state.pc + 1]
        case .dad_d_e:
            let de = addressRegisterPair(state.registers.d, state.registers.e)
            let hl = addressRegisterPair(state.registers.h, state.registers.l)

            let (result, overflow) = de.addingReportingOverflow(hl)

            write(result, pair: .hl)
            state.condition_bits.carry = UInt8(overflow)
        case .inr_h:
            try increment(.h)
        case .ldax_d_e:
            let address = Int(addressRegisterPair(state.registers.d, state.registers.e))
            state.registers.a = memory[address]
        case .dcx_d_e:
            let value = addressRegisterPair(state.registers.d, state.registers.e)
            let (result, _) = value.subtractingReportingOverflow(1)
            write(result, pair: .de)
        case .mvi_e:
            state.registers.e = memory[state.pc + 1]
        case .cma:
            state.registers.a = ~state.registers.a
        case .rar:
            let accumulator = state.registers.a >> 1
            let value = accumulator | (state.condition_bits.carry << 7)
            state.condition_bits.carry = UInt8((state.registers.a & 0x01) == 0x01)
            state.registers.a = value
        case .lxi_h_l:
            writeImmediate(to: .hl)
        case .shld:
            let address = Int(addressRegisterPair(memory[state.pc + 2], memory[state.pc + 1]))
            try write(state.registers.l, at: address)
            try write(state.registers.h, at: address + 1)
        case .inx_h_l:
            let value = addressRegisterPair(state.registers.h, state.registers.l)
            let (result, _) = value.addingReportingOverflow(1)
            write(result, pair: .hl)
        case .daa:
            let lsb4 = state.registers.a & 0xf

            if  lsb4 > 9 || state.condition_bits.aux_carry == 0x01 {
                let (result, overflow) = state.registers.a.addingReportingOverflow(6)
                state.registers.a = result
                updateArithmeticZSPC(Int(result), overflow: overflow)
                if overflow {
                    state.condition_bits.aux_carry = 0x01
                } else {
                    state.condition_bits.aux_carry = 0x00
                }
            }

            let msb4 = state.registers.a & 0xf0

            if msb4 > 0x90 || state.condition_bits.carry == 0x01 {
                let (result, overflow) = state.registers.a.addingReportingOverflow(0x60)
                state.registers.a = result
                updateArithmeticZSPC(Int(result), overflow: overflow)
            }
        case .mvi_h:
            state.registers.h = memory[state.pc + 1]
        case .dad_h_l:
            let hl = addressRegisterPair(state.registers.h, state.registers.l)
            let (result, overflow) = hl.addingReportingOverflow(hl)

            write(result, pair: .hl)
            state.condition_bits.carry = UInt8(overflow)
        case .lhld:
            let address = Int(addressRegisterPair(memory[state.pc + 2], memory[state.pc + 1]))
            state.registers.l = memory[address]
            state.registers.h = memory[address + 1]
        case .dcx_h_l:
            let value = addressRegisterPair(state.registers.h, state.registers.l)
            let (result, _) = value.subtractingReportingOverflow(1)
            write(result, pair: .hl)
        case .inr_l:
            try increment(.l)
        case .mvi_l:
            state.registers.l = memory[state.pc + 1]
        case .lxi_sp:
            state.sp = Int(addressRegisterPair(memory[state.pc + 2], memory[state.pc + 1]))
        case .sta:
            let address =  Int(addressRegisterPair(memory[state.pc + 2], memory[state.pc + 1]))
            try write(state.registers.a, at: address)
        case .inr_m:
            try increment(.m)
        case .dcr_m:
            try decrement(.m)
        case .mvi_m:
            try write(memory[state.pc + 1], at: m_address())
        case .stc:
            state.condition_bits.carry = 1
        case .lda:
            let address = Int(addressRegisterPair(memory[state.pc + 2], memory[state.pc + 1]))
            state.registers.a = memory[address]
        case .inr_a:
            try increment(.a)
        case .dcr_a:
            try decrement(.a)
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
            state.registers.b = memory[m_address()]
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
            state.registers.c = memory[m_address()]
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
            state.registers.d = memory[m_address()]
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
            state.registers.e = memory[m_address()]
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
            state.registers.h = memory[m_address()]
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
            state.registers.l = memory[m_address()]
        case .mov_l_a:
            state.registers.l = state.registers.a
        case .mov_m_b:
            try write(state.registers.b, at: m_address())
        case .mov_m_c:
            try write(state.registers.c, at: m_address())
        case .mov_m_d:
            try write(state.registers.d, at: m_address())
        case .mov_m_e:
            try write(state.registers.e, at: m_address())
        case .mov_m_h:
            try write(state.registers.h, at: m_address())
        case .mov_m_l:
            try write(state.registers.l, at: m_address())
        case .mov_m_a:
            try write(state.registers.a, at: m_address())
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
            state.registers.a = memory[m_address()]
        case .mov_a_a:
            break
        case .add_b:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.b)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .add_c:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.c)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .add_d:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.d)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .add_e:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.e)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .add_h:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.h)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .add_l:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.l)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .add_m:
            let value = memory[m_address()]
            let (result, overflow) = state.registers.a.addingReportingOverflow(value)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .add_a:
            throw Error.unhandledOperation(code)
        case .adc_b:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.b + state.condition_bits.carry)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .adc_c:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.c + state.condition_bits.carry)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .adc_d:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.d + state.condition_bits.carry)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .adc_e:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.e + state.condition_bits.carry)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .adc_h:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.h + state.condition_bits.carry)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .adc_l:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.l + state.condition_bits.carry)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .adc_m:
            throw Error.unhandledOperation(code)
        case .adc_a:
            let (result, overflow) = state.registers.a.addingReportingOverflow(state.registers.a + state.condition_bits.carry)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .sub_b:
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(state.registers.b)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .sub_c:
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(state.registers.c)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .sub_d:
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(state.registers.d)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .sub_e:
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(state.registers.e)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .sub_h:
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(state.registers.h)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .sub_l:
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(state.registers.l)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .sub_m:
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(memory[m_address()])
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .sub_a:
            state.registers.a = 0
            updateArithmeticZSPC(0, overflow: false)
        case .ana_b:
            state.registers.a &= state.registers.b
            updateLogicZSPC(Int(state.registers.a))
        case .ana_c:
            state.registers.a &= state.registers.c
            updateLogicZSPC(Int(state.registers.a))
        case .ana_d:
            state.registers.a &= state.registers.d
            updateLogicZSPC(Int(state.registers.a))
        case .ana_e:
            state.registers.a &= state.registers.e
            updateLogicZSPC(Int(state.registers.a))
        case .ana_h:
            state.registers.a &= state.registers.h
            updateLogicZSPC(Int(state.registers.a))
        case .ana_l:
            state.registers.a &= state.registers.l
            updateLogicZSPC(Int(state.registers.a))
        case .ana_m:
            state.registers.a &= memory[m_address()]
            updateLogicZSPC(Int(state.registers.a))
        case .ana_a:
            state.registers.a &= state.registers.a
            updateLogicZSPC(Int(state.registers.a))
        case .xra_b:
            state.registers.a ^= state.registers.b
            updateLogicZSPC(Int(state.registers.a))
        case .xra_a:
            state.registers.a ^= state.registers.a
            updateLogicZSPC(Int(state.registers.a))
        case .ora_b:
            state.registers.a |= state.registers.b
            updateLogicZSPC(Int(state.registers.a))
        case .ora_c:
            state.registers.a |= state.registers.c
            updateLogicZSPC(Int(state.registers.a))
        case .ora_d:
            state.registers.a |= state.registers.d
            updateLogicZSPC(Int(state.registers.a))
        case .ora_e:
            state.registers.a |= state.registers.e
            updateLogicZSPC(Int(state.registers.a))
        case .ora_h:
            state.registers.a |= state.registers.h
            updateLogicZSPC(Int(state.registers.a))
        case .ora_l:
            state.registers.a |= state.registers.l
            updateLogicZSPC(Int(state.registers.a))
        case .ora_m:
            state.registers.a |= memory[m_address()]
            updateLogicZSPC(Int(state.registers.a))
        case .ora_a:
            state.registers.a |= state.registers.a
            updateLogicZSPC(Int(state.registers.a))
        case .cmp_b:
            compare(Int(state.registers.b))
        case .cmp_c:
            compare(Int(state.registers.c))
        case .cmp_d:
            compare(Int(state.registers.d))
        case .cmp_e:
            compare(Int(state.registers.e))
        case .cmp_h:
            compare(Int(state.registers.h))
        case .cmp_l:
            compare(Int(state.registers.l))
        case .cmp_m:
            compare(Int(memory[m_address()]))
        case .cmp_a:
            compare(Int(state.registers.a))
        case .rnz:
            if state.condition_bits.zero == 0 {
                try ret()
                return code.cycleCount
            }
        case .pop_b:
            let (high, low) = try pop()
            state.registers.b = high
            state.registers.c = low
        case .jnz:
            if state.condition_bits.zero == 0 {
                jump()
                return code.cycleCount
            }
        case .jmp:
            jump()
            return code.cycleCount
        case .cnz:
            if state.condition_bits.zero == 0 {
                try call()
                return code.cycleCount
            }
        case .push_b:
            try push(high: state.registers.b, low: state.registers.c)
        case .adi:
            let (result, overflow) = state.registers.a.addingReportingOverflow(memory[state.pc + 1])
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .rz:
            if state.condition_bits.zero == 1 {
                try ret()
                return code.cycleCount
            }
        case .ret:
            try ret()
            return code.cycleCount
        case .jz:
            if state.condition_bits.zero == 1 {
                jump()
                return code.cycleCount
            }
        case .cz:
            if state.condition_bits.zero == 1 {
                try call()
                return code.cycleCount
            }
        case .call:
            try call()
            return code.cycleCount
        case .pop_d:
            let (high, low) = try pop()
            state.registers.d = high
            state.registers.e = low
        case .jnc:
            if state.condition_bits.carry == 0 {
                jump()
                return code.cycleCount
            }
        case .out:
            guard let bus = bus else {
                throw Error.missingIOHandler
            }

            let port = memory[state.pc + 1]
            bus.machineOUT(port: port, accumulator: state.registers.a)
        case .cnc:
            if state.condition_bits.carry == 0 {
                try call()
                return code.cycleCount
            }
        case .push_d:
            try push(high: state.registers.d, low: state.registers.e)
        case .sui:
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(memory[state.pc + 1])
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .rc:
            if state.condition_bits.carry == 1 {
                try ret()
                return code.cycleCount
            }
        case .rp:
            throw Error.unhandledOperation(code)
        case .rpe:
            throw Error.unhandledOperation(code)
        case .pchl:
            state.pc = m_address()
            return code.cycleCount
        case .rnc:
            if state.condition_bits.carry == 0 {
                try ret()
                return code.cycleCount
            }
        case .rpo:
            throw Error.unhandledOperation(code)
        case .jc:
            if state.condition_bits.carry == 1 {
                jump()
                return code.cycleCount
            }
        case .in:
            guard let bus = bus else {
                throw Error.missingIOHandler
            }

            let device = memory[state.pc + 1]
            state.registers.a = bus.machineIN(port: device)
        case .sbi:
            let data = memory[state.pc + 1] + state.condition_bits.carry
            let (result, overflow) = state.registers.a.subtractingReportingOverflow(data)
            state.registers.a = result
            updateArithmeticZSPC(Int(state.registers.a), overflow: overflow)
        case .pop_h:
            let (high, low) = try pop()
            state.registers.h = high
            state.registers.l = low
        case .xthl:
            let l = state.registers.l
            let h = state.registers.h
            let sp_0 = memory[state.sp]
            let sp_1 = memory[state.sp + 1]

            state.registers.l = sp_0
            state.registers.h = sp_1

            try write(l, at: state.sp)
            try write(h, at: state.sp + 1)
        case .push_h:
            try push(high: state.registers.h, low: state.registers.l)
        case .ani:
            state.registers.a &= memory[state.pc + 1]
            updateLogicZSPC(Int(state.registers.a))
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
        case .ori:
            state.registers.a |= memory[state.pc + 1]
        case .rm:
            if state.condition_bits.sign == 1 {
                try ret()
                return code.cycleCount
            }
        case .jm:
            if state.condition_bits.sign == 1 {
                jump()
                return code.cycleCount
            }
        case .ei:
            state.inte = 0x01
        case .cpi:
            let value = Int(memory[state.pc + 1])
            compare(value)
        }

        state.pc += code.size

        return code.cycleCount
    }
}
