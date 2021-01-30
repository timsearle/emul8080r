import XCTest
@testable import Emul8080r

struct TestClock: SystemClock {
    func currentMicroseconds() -> Double {
        var time = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&time, nil)
        return Double(time.tv_sec * __darwin_time_t(1E6) + __darwin_time_t(time.tv_usec))
    }
}

final class Emul8080rTests: XCTestCase {
    func testBasicInstructionSequence() {
        // Increment BC, Increment BC, Add immediate value 0x01 to accumulator, Add C to accumulator
        let instructions: [UInt8] = [OpCode.inx_b_c.rawValue, OpCode.inx_b_c.rawValue, OpCode.adi.rawValue, 0x01, OpCode.add_c.rawValue]

        let cpu = CPU(memory: instructions, systemClock: TestClock())

        while true {
            do {
                try cpu.start(interrupter: { () in 0 })
            } catch {
                guard case CPU.Error.programTerminated = error else {
                    XCTFail("Unexpected error")
                    return
                }

                break
            }
        }

        XCTAssertEqual(cpu.state.registers.a, 3)
        XCTAssertEqual(cpu.state.registers.b, 0)
        XCTAssertEqual(cpu.state.registers.c, 2)
    }

    static var allTests = [
        ("testBasicInstructionSequence", testBasicInstructionSequence),
    ]
}
