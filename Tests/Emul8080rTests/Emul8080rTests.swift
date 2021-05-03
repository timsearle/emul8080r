import XCTest
@testable import Emul8080r

struct FakeClock: SystemClock {
    func currentMicroseconds() -> Double {
        0
    }
}

final class Emul8080rTests: XCTestCase {
    func testBasicInstructionSequence() throws {
        // Increment BC, Increment BC, Add immediate value 0x01 to accumulator, Add C to accumulator
        let instructions: [UInt8] = [OpCode.inx_b_c.rawValue,
                                     OpCode.inx_b_c.rawValue,
                                     OpCode.adi.rawValue, 0x01,
                                     OpCode.add_c.rawValue]

        let cpu = CPU(memory: instructions, systemClock: FakeClock())

        for _ in 0..<4 {
            _ = try cpu.execute()
        }

        XCTAssertEqual(cpu.state.registers.a, 3)
        XCTAssertEqual(cpu.state.registers.b, 0)
        XCTAssertEqual(cpu.state.registers.c, 2)
    }

    func test_STAX_bc() throws {
        let instructions: [UInt8] = [OpCode.adi.rawValue, 0x01,
                                     OpCode.mvi_c.rawValue, 0x05,
                                     OpCode.stax_b_c.rawValue, 0x00]
        
        let cpu = CPU(memory: instructions, systemClock: FakeClock())

        var one = State8080(memory: instructions)
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

    static var allTests = [
        ("testBasicInstructionSequence", testBasicInstructionSequence),
    ]
}
