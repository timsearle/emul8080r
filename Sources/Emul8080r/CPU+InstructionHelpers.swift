extension CPU {
    // MARK: Control Flow
    func jump()  {
        state.pc = Int(addressRegisterPair(memory[state.pc + 2], memory[state.pc + 1]))
    }

    func ret() throws {
        let (high, low) = try pop()
        state.pc = Int(addressRegisterPair(high, low))
    }

    func call() throws {
        let returnAddress = state.pc + 3
        try push(high: UInt8((returnAddress >> 8) & 0xff), low: UInt8(returnAddress & 0xff))
        jump()
    }

    // MARK: Arithmetic
    func increment(_ register: Register) throws {
        let result: UInt8

        switch register {
        case .b:
            (result, _) = state.registers.b.addingReportingOverflow(1)
            state.registers.b = result
        case .c:
            (result, _) = state.registers.c.addingReportingOverflow(1)
            state.registers.c = result
        case .d:
            (result, _) = state.registers.d.addingReportingOverflow(1)
            state.registers.d = result
        case .e:
            (result, _) = state.registers.e.addingReportingOverflow(1)
            state.registers.e = result
        case .h:
            (result, _) = state.registers.h.addingReportingOverflow(1)
            state.registers.h = result
        case .l:
            (result, _) = state.registers.l.addingReportingOverflow(1)
            state.registers.l = result
        case .m:
            let address = m_address()
            let value = memory[address]
            (result, _) = value.addingReportingOverflow(1)
            try write(result, at: address)
        case .a:
            (result, _) = state.registers.a.addingReportingOverflow(1)
            state.registers.a = result
        }

        updateZSP(Int(result))
    }

    func decrement(_ register: Register) throws {
        let result: UInt8

        switch register {
        case .b:
            (result, _) = state.registers.b.subtractingReportingOverflow(1)
            state.registers.b = result
        case .c:
            (result, _) = state.registers.c.subtractingReportingOverflow(1)
            state.registers.c = result
        case .d:
            (result, _) = state.registers.d.subtractingReportingOverflow(1)
            state.registers.d = result
        case .e:
            (result, _) = state.registers.e.subtractingReportingOverflow(1)
            state.registers.e = result
        case .h:
            (result, _) = state.registers.h.subtractingReportingOverflow(1)
            state.registers.h = result
        case .l:
            (result, _) = state.registers.l.subtractingReportingOverflow(1)
            state.registers.l = result
        case .m:
            let address = m_address()
            let value = memory[address]
            (result, _) = value.subtractingReportingOverflow(1)
            try write(result, at: address)
        case .a:
            (result, _) = state.registers.a.subtractingReportingOverflow(1)
            state.registers.a = result
        }

        updateZSP(Int(result))
    }

    func compare(_ value: Int) {
        let accumulator = Int(state.registers.a)
        state.condition_bits.carry = UInt8(value > accumulator)
        updateZSP(accumulator - value)
    }

    // MARK: Stack
    func push(high: UInt8, low: UInt8) throws {
        try write(high, at: state.sp - 1)
        try write(low, at: state.sp - 2)
        state.sp -= 2
    }

    func pop() throws -> (UInt8, UInt8) {
        let high = memory[state.sp + 1]
        let low = memory[state.sp]
        state.sp += 2

        return (high, low)
    }

    // MARK: Mutating Memory
    func write(_ value: UInt16, pair: RegisterPair) {
        let highValue = UInt8(value >> 8)
        let lowValue = UInt8(value & 0xff)

        switch pair {
        case .bc:
            state.registers.b = highValue
            state.registers.c = lowValue
        case .de:
            state.registers.d = highValue
            state.registers.e = lowValue
        case .hl:
            state.registers.h = highValue
            state.registers.l = lowValue
        }
    }

    func writeImmediate(to pair: RegisterPair) {
        write(addressRegisterPair(memory[state.pc + 2], memory[state.pc + 1]), pair: pair)
    }

    func write(_ value: UInt8, at address: Int) throws {
        guard address >= 0x2000 else {
            throw Error.cannotWriteToROM(address)
        }

        memory[address] = value
    }

    // MARK: Addressing
    func addressRegisterPair(_ high: UInt8, _ low: UInt8) -> UInt16 {
        return UInt16(high) << 8 | UInt16(low)
    }

    func m_address() -> Int {
        return Int(addressRegisterPair(state.registers.h, state.registers.l))
    }

    // MARK: Condition Bits
    func updateZSP(_ value: Int) {
        state.condition_bits.zero = UInt8((value & 0xff) == 0)
        state.condition_bits.sign = UInt8(0x80 == (value & 0x80))
        state.condition_bits.parity = parity(value & 0xff)
    }

    func updateArithmeticZSPC(_ value: Int, overflow: Bool) {
        state.condition_bits.zero = UInt8((value & 0xff) == 0)
        state.condition_bits.sign = UInt8(0x80 == (value & 0x80))
        state.condition_bits.parity = parity(value & 0xff)
        state.condition_bits.carry = UInt8(overflow)
    }

    func updateLogicZSPC(_ value: Int) {
        state.condition_bits.zero = UInt8((value & 0xff) == 0)
        state.condition_bits.sign = UInt8(0x80 == (value & 0x80))
        state.condition_bits.parity = parity(value & 0xff)
        state.condition_bits.carry = 0
    }

    func parity(_ value: Int) -> UInt8 {
        let binary = String(value, radix: 2)
        return UInt8(binary.filter { $0 == "1" }.count % 2 == 0)
    }
}
