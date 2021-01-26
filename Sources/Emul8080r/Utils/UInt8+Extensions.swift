public extension FixedWidthInteger {
    var hex: String {
        String(self, radix: 16)
    }

    var bits: [UInt8] {
        var byte = self
        var bits = [UInt8](repeating: 0x00, count: 8)
        for i in 0..<8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = 0xff
            }

            byte >>= 1
        }

        return bits
    }

    init(_ value: Bool) {
        self = value ? 1 : 0
    }
}
