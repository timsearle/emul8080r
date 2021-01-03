import Foundation

public struct ConditionBits {
    var zero: UInt8 = 0
    var sign: UInt8 = 0
    var parity: UInt8 = 0
    var carry: UInt8 = 0
    var aux_carry: UInt8 = 0

    var byte: UInt8 {
        UInt8("\(sign)\(zero)0\(aux_carry)0\(parity)1\(carry)", radix: 2)!
    }
}

public struct Registers: CustomStringConvertible {
    var a: UInt8 = 0
    var b: UInt8 = 0
    var c: UInt8 = 0
    var d: UInt8 = 0
    var e: UInt8 = 0
    var h: UInt8 = 0
    var l: UInt8 = 0

    public var description: String {
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

public struct State8080: CustomStringConvertible {
    var registers = Registers()

    var sp: Int = 0
    var pc: Int = 0
    var condition_bits = ConditionBits()
    var memory = [UInt8](repeating: 0, count: 65536)

    public var description: String {
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
