import Foundation

struct ConditionBits {
    var zero: UInt8 = 0
    var sign: UInt8 = 0
    var parity: UInt8 = 0
    var carry: UInt8 = 0
    var aux_carry: UInt8 = 0
}

struct Registers: CustomStringConvertible {
    var a: UInt8 = 0
    var b: UInt8 = 0
    var c: UInt8 = 0
    var d: UInt8 = 0
    var e: UInt8 = 0
    var h: UInt8 = 0
    var l: UInt8 = 0

    var description: String {
        """
        a: \(a.hex)
        b: \(b.hex)
        c: \(c.hex)
        d: \(d.hex)
        e: \(e.hex)
        h: \(h.hex)
        l: \(l.hex)
        """
    }
}

struct State8080: CustomStringConvertible {
    var registers = Registers()

    var sp: Int = 0
    var pc: Int = 0
    var condition_bits = ConditionBits()
    var memory = [UInt8](repeating: 0, count: 65536)

    var description: String {
        """
        \n
        -= 8080 Internal State =-
        Memory Size: \(memory.count)
        Program Counter: \(pc)
        Stack Pointer: \(sp)
        \(condition_bits)
        \(registers)
        """
    }
}
