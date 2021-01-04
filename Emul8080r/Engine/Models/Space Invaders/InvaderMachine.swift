import Foundation

public final class InvaderMachine {
    public enum ButtonState {
        case down
        case up
    }

    private let cpu: CPU
    private let shiftRegister = ShiftRegister()
    private let videoController = ShiftRegister()

    private var inputPorts: [UInt8] = [0b00001110, 0b00001000, 0, 0]

    public var videoMemory: [UInt8] {
        Array(cpu.memory[0x2400...0x3FFF])
    }

    public init(rom: Data) {
        cpu = CPU(memory: [UInt8](repeating: 0, count: 65536))
        cpu.load(rom)
        cpu.machineIn = machineIn
        cpu.machineOut = machineOut
    }

    public func play() throws {
        try cpu.start()
    }

    public func fire(state: ButtonState) {
        switch state {
        case .down:
            inputPorts[0] |= 0x10
        case .up:
            inputPorts[0] &= 0xef
        }
    }

    public func left(state: ButtonState) {
        switch state {
        case .down:
            inputPorts[0] |= 0x20
        case .up:
            inputPorts[0] &= 0xdf
        }
    }

    public func right(state: ButtonState) {
        switch state {
        case .down:
            inputPorts[0] |= 0x40
        case .up:
            inputPorts[0] &= 0xbf
        }
    }

    private func machineIn(_ port: UInt8) -> UInt8 {
        switch port {
        case 3:
            return shiftRegister.in(port: port)
        default:
            print("Unimplemented port \(port)")
            return 0
        }
    }

    private func machineOut(_ port: UInt8, _ value: UInt8) {
        switch port {
        case 2, 4:
            return shiftRegister.out(port: port, value: value)
        default:
            print("Unimplemented port \(port)")
        }
    }
}
