public struct Bitmap {
    public private(set) var pixels: [UInt8]
    public let width: Int

    public init(width: Int, pixels: [UInt8]) {
        self.width = width
        self.pixels = pixels
    }
}

public extension Bitmap {
    var height: Int {
        return pixels.count / width
    }

    subscript(x: Int, y: Int) -> UInt8 {
        get { return pixels[y * width + x] }
        set {
            guard x >= 0, y >= 0, x < width, y < height else { return }
            pixels[y * width + x] = newValue
        }
    }

    init(width: Int, height: Int, color: UInt8) {
        self.pixels = Array(repeating: color, count: width * height)
        self.width = width
    }
}
