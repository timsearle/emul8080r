import Foundation

public struct ConditionBits: Codable {
    var zero: UInt8 = 0 {
        didSet {
            if zero != 0x00 && zero != 0x01 {
                fatalError("Invalid condition bit")
            }
        }
    }
    var sign: UInt8 = 0 {
        didSet {
            if sign != 0x00 && sign != 0x01 {
                fatalError("Invalid condition bit")
            }
        }
    }
    var parity: UInt8 = 0 {
        didSet {
            if parity != 0x00 && parity != 0x01 {
                fatalError("Invalid condition bit")
            }
        }
    }
    var carry: UInt8 = 0 {
        didSet {
            if carry != 0x00 && carry != 0x01 {
                fatalError("Invalid condition bit")
            }
        }
    }
    var aux_carry: UInt8 = 0 {
        didSet {
            if aux_carry != 0x00 && aux_carry != 0x01 {
                fatalError("Invalid condition bit")
            }
        }
    }

    var byte: UInt8 {
        UInt8("\(sign)\(zero)0\(aux_carry)0\(parity)1\(carry)", radix: 2)!
    }
}

public struct Registers: CustomStringConvertible, Codable {
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

public struct State8080: CustomStringConvertible, Codable {
    var registers = Registers()

    var sp: Int = 0
    var pc: Int = 0
    var condition_bits = ConditionBits()

    var inte = UInt8(0) // Interrupts Enabled

    public init() {}

    mutating func updateConditionBits(_ byte: UInt8) {
        var bits = String(byte, radix: 2).map { UInt8("\($0)")! }

        while bits.count < 8 {
            bits.insert(0, at: 0)
        }

        condition_bits.sign = bits[0]
        condition_bits.zero = bits[1]
        condition_bits.aux_carry = bits[3]
        condition_bits.parity = bits[5]
        condition_bits.carry = bits[7]
    }

    public var description: String {
        """
        \n
        -= 8080 Internal State =-
        Program Counter: \(pc)
        Stack Pointer: \(sp)
        \(condition_bits)
        \(registers)
        """
    }
}
