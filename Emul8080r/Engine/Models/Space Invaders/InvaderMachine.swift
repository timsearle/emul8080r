import Foundation

public struct SaveState: Codable {
    let memory: [UInt8]
    let inputPorts: [UInt8]
    let state: State8080
    let register: ShiftRegister
}

public final class InvaderMachine {
    public enum ButtonState {
        case down
        case up
    }

    private let cpu: CPU
    private let shiftRegister = ShiftRegister()

    private var lastExecutionTime: TimeInterval = 0
    private var nextInterrupt: TimeInterval = 0
    private var whichInterrupt: Int = 0

    private var inputPorts: [UInt8] = [0b00001110, 0b00001000, 0, 0]

    private func captureState() -> SaveState {
        return SaveState(memory: cpu.memory, inputPorts: inputPorts, state: cpu.state, register: shiftRegister)
    }
    
    public var videoMemory: [UInt8] {
        Array(cpu.memory[0x2400...0x3FFF])
    }

    public init(rom: Data, loggingEnabled: Bool = false) {
        cpu = CPU(memory: [UInt8](repeating: 0, count: 65536), loggingEnabled: loggingEnabled)
        cpu.load(rom)
        cpu.machineIn = machineIn
        cpu.machineOut = machineOut
    }

    public init(saveState: SaveState, loggingEnabled: Bool = false) {
        cpu = CPU(memory: saveState.memory, state: saveState.state, loggingEnabled: loggingEnabled)
        inputPorts = saveState.inputPorts
        cpu.machineIn = machineIn
        cpu.machineOut = machineOut
    }

    public func play() {
        if lastExecutionTime == 0.0 {
            lastExecutionTime = Date().timeIntervalSince1970
            nextInterrupt = lastExecutionTime + 0.016
            whichInterrupt = 1
        }

        Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
            do {
                self.lastExecutionTime = try self.cpu.start(previousExecutionTime: self.lastExecutionTime, interruptProvider: {
                    let now = Date().timeIntervalSince1970
                    if now > self.nextInterrupt {
                        try! self.cpu.interrupt(self.whichInterrupt)
                        self.whichInterrupt = self.whichInterrupt == 1 ? 2 : 1
                        self.nextInterrupt = now + 0.008
                    }
                })
            } catch {
                UserDefaults.standard.setValue(try! JSONEncoder().encode(self.captureState()), forKey: "PreviousState")
                print(error)
                timer.invalidate()
            }
        }
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

    public func coin(state: ButtonState) {
        switch state {
        case .down:
            inputPorts[1] |= 0x01
        case .up:
            inputPorts[1] &= ~0x01
        }
    }

    public func start1P(state: ButtonState) {
        switch state {
        case .down: 
            inputPorts[1] |= 0x04
        case .up:
            inputPorts[1] &= ~0x04
        }
    }

    private func machineIn(_ port: UInt8) -> UInt8 {
        switch port {
        case 3:
            return shiftRegister.in(port: port)
        default:
            return inputPorts[Int(port)]
        }
    }

    private func machineOut(_ port: UInt8, _ value: UInt8) {
        switch port {
        case 2, 4:
            return shiftRegister.out(port: port, value: value)
        default:
            break //print("Unimplemented OUT port \(port)")
        }
    }
}
