import Foundation

extension UInt8 {
    var hex: String {
        String(format: "%02x", self)
    }

    init(_ value: Bool) {
        self = value ? 1 : 0
    }
}
