import Foundation

struct ConditionBits {
    var zero: UInt8 = 0
    var sign: UInt8 = 0
    var parity: UInt8 = 0
    var carry: UInt8 = 0
    var aux_carry: UInt8 = 0
}

struct Registers {
    var a: UInt8 = 0
    var b: UInt8 = 0
    var c: UInt8 = 0
    var d: UInt8 = 0
    var e: UInt8 = 0
    var h: UInt8 = 0
    var l: UInt8 = 0
}

struct State8080 {
    var registers = Registers()

    var sp: UInt16 = 0
    var pc: UInt16 = 0
    var condition_bits = ConditionBits()
    var memory = [UInt8](repeating: 0, count: 65536)
}
