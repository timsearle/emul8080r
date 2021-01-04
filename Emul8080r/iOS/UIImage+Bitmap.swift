import UIKit

extension UIImage {
    convenience init?(bitmap: Bitmap) {
        let alphaInfo = CGImageAlphaInfo.none
        let bytesPerPixel = MemoryLayout<UInt8>.size
        let bytesPerRow = bitmap.width * bytesPerPixel

        guard let providerRef = CGDataProvider(data:
            Data(bytes: bitmap.pixels,
                 count: bitmap.height * bytesPerRow) as CFData) else {
                return nil
        }

        guard let cgImage = CGImage(
            width: bitmap.width,
            height: bitmap.height,
            bitsPerComponent: 8,
            bitsPerPixel: bytesPerPixel * 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
            ) else {
                return nil
        }

        self.init(cgImage: cgImage)
    }
}

extension Bitmap {
    init?(image: UIImage) {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bytesPerPixel = MemoryLayout<UInt8>.size
        let bytesPerRow = cgImage.width * bytesPerPixel

        var pixels = [UInt8](repeating: 0, count: cgImage.width * cgImage.height)
        guard let context = CGContext(
            data: &pixels,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: alphaInfo.rawValue
            ) else {
                return nil
        }

        context.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
        self.init(width: cgImage.width, pixels: pixels)
    }
}
