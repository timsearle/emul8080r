import Foundation

/*
 https://www.computerarcheology.com/Arcade/SpaceInvaders/Hardware.html
 16 bit shift register:

     f              0    bit
     xxxxxxxxyyyyyyyy

     Writing to port 4 shifts x into y, and the new value into x, eg.
     $0000,
     write $aa -> $aa00,
     write $ff -> $ffaa,
     write $12 -> $12ff, ..

     Writing to port 2 (bits 0,1,2) sets the offset for the 8 bit result, eg.
     offset 0:
     rrrrrrrr        result=xxxxxxxx
     xxxxxxxxyyyyyyyy

     offset 2:
       rrrrrrrr    result=xxxxxxyy
     xxxxxxxxyyyyyyyy

     offset 7:
            rrrrrrrr    result=xyyyyyyy
     xxxxxxxxyyyyyyyy

     Reading from port 3 returns said result.
 */

public final class ShiftRegister: Codable {
    var shiftX = UInt8(0)
    var shiftY = UInt8(0)
    var shift_offset = UInt8(0)

    func `in`(port: UInt8) -> UInt8 {
        var a = UInt8(0)

        switch(port) {
        case 3:
            let v = UInt16(shiftX) << 8 | UInt16(shiftY)
            let shift = 8 - shift_offset
            a = UInt8(truncatingIfNeeded: (v >> shift) & 0xff)
        default:
            fatalError("Unsupported port call to ShiftRegister")
        }

        return a
    }

    func out(port: UInt8, value: UInt8) {
        switch(port) {
        case 2:
            shift_offset = value & 0x7
        case 4:
            shiftY = shiftX
            shiftX = value
        default:
            fatalError("Unsupported port call to ShiftRegister")
        }
    }

}
