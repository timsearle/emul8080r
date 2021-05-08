import XCTest
@testable import Emul8080r

final class Emul8080rTests: XCTestCase {
    func testBasicInstructionSequence() throws {
        // Increment BC, Increment BC, Add immediate value 0x01 to accumulator, Add C to accumulator
        let program: [UInt8] = [OpCode.inx_b_c.rawValue,
                                OpCode.inx_b_c.rawValue,
                                OpCode.adi.rawValue, 0x01,
                                OpCode.add_c.rawValue]

        let cpu = CPU(memory: program, systemClock: FakeClock())

        for _ in 0..<4 {
            _ = try cpu.execute()
        }

        XCTAssertEqual(cpu.state.registers.a, 3)
        XCTAssertEqual(cpu.state.registers.b, 0)
        XCTAssertEqual(cpu.state.registers.c, 2)
    }

    func test_STAX_bc() throws {
        let program: [UInt8] = [OpCode.adi.rawValue, 0x01,
                                OpCode.mvi_c.rawValue, 0x05,
                                OpCode.stax_b_c.rawValue, 0x00]
        
        let cpu = CPU(memory: program, systemClock: FakeClock())

        var one = State8080(memory: program)
        one.registers.a = 0x01
        one.pc = 2

        var two = one
        two.pc = 4
        two.registers.c = 0x05

        var three = two
        three.pc = 5
        three.memory[0x05] = 1

        let expected = [one, two, three]

        for i in 0..<3 {
            _ = try cpu.execute()
            XCTAssertEqual(cpu.state, expected[i])
        }
    }

    func test_DCX_bc() throws {
        let program: [UInt8] = populateRegisters(b: 0x05, c: 0x05) + [OpCode.dcx_b_c.rawValue]

        let cpu = CPU(memory: program, systemClock: FakeClock())

        var expected = State8080(memory: program)
        expected.pc = 5
        expected.registers.b = 0x05
        expected.registers.c = 0x04

        while true {
            do {
                _ = try cpu.execute()
            } catch CPU.Error.programTerminated {
                break
            } catch {
                throw error
            }
        }

        XCTAssertEqual(cpu.state, expected)
    }

    func test_XRA_a() throws {
        let program: [UInt8] = populateRegisters(a: 0x01) + [OpCode.xra_a.rawValue]

        let cpu = CPU(memory: program, systemClock: FakeClock())

        var expected = State8080(memory: program)
        expected.registers.a = 0x00
        expected.pc = 3
        expected.condition_bits.parity = 1
        expected.condition_bits.zero = 1

        while true {
            do {
                _ = try cpu.execute()
            } catch CPU.Error.programTerminated {
                break
            } catch {
                throw error
            }
        }

        XCTAssertEqual(cpu.state, expected)
    }

    func test_XRA_b() throws {
        let program: [UInt8] = populateRegisters(a: 0x01, b: 0x0a) + [OpCode.xra_b.rawValue]

        let cpu = CPU(memory: program, systemClock: FakeClock())

        var expected = State8080(memory: program)
        expected.registers.a = 0x0b
        expected.registers.b = 0x0a
        expected.pc = 5
        expected.condition_bits.parity = 0
        expected.condition_bits.zero = 0

        while true {
            do {
                _ = try cpu.execute()
            } catch CPU.Error.programTerminated {
                break
            } catch {
                throw error
            }
        }

        XCTAssertEqual(cpu.state, expected)
    }

    private func populateRegisters(a: UInt8? = nil, b: UInt8? = nil, c: UInt8? = nil, d: UInt8? = nil, e: UInt8? = nil, h: UInt8? = nil, l: UInt8? = nil) -> [UInt8] {
        [
            a.map { [OpCode.mvi_a.rawValue, $0] },
            b.map { [OpCode.mvi_b.rawValue, $0] },
            c.map { [OpCode.mvi_c.rawValue, $0] },
            d.map { [OpCode.mvi_d.rawValue, $0] },
            e.map { [OpCode.mvi_e.rawValue, $0] },
            h.map { [OpCode.mvi_h.rawValue, $0] },
            l.map { [OpCode.mvi_l.rawValue, $0] }
        ]
        .compactMap { $0 }
        .flatMap { $0 }
    }

    static var allTests = [
        ("testBasicInstructionSequence", testBasicInstructionSequence),
    ]
}
