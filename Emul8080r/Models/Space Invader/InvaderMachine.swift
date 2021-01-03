import Foundation

public final class InvaderMachine {
    private let cpu: CPU
    private let shiftRegister = ShiftRegister()

    public init(rom: Data) {
        cpu = CPU(memory: [UInt8](repeating: 0, count: 65536))
        cpu.machineIn = machineIn
        cpu.machineOut = machineOut
    }

    private func machineIn(_ port: UInt8) -> UInt8 {
        switch port {
        case 3:
            return shiftRegister.in(port: port)
        default:
            fatalError("Unimplemented port")
        }
    }

    private func machineOut(_ port: UInt8, _ value: UInt8) {
        switch port {
        case 2, 4:
            return shiftRegister.out(port: port, value: value)
        default:
            fatalError("Unimplemented port")
        }
    }
}
