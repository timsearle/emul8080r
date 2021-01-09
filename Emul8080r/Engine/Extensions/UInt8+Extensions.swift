import Foundation

extension UInt8 {
    var hex: String {
        String(format: "%02x", self)
    }

    var bits: [Bit] {
        var byte = self
        var bits = [Bit](repeating: .zero, count: 8)
        for i in 0..<8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }

            byte >>= 1
        }

        return bits
    }

    init(_ value: Bool) {
        self = value ? 1 : 0
    }
}

enum Bit {
    case one
    case zero
}
