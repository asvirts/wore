import UIKit

enum PhotoPrep {
    /// Draws the image upright and caps the long edge so the cutout and the saved file stay small.
    static func flattenedPNG(from image: UIImage, maxPixel: CGFloat = 1600) -> Data? {
        let pixelWidth = max(image.size.width * image.scale, 1)
        let pixelHeight = max(image.size.height * image.scale, 1)
        let ratio = min(1, maxPixel / max(pixelWidth, pixelHeight))
        let target = CGSize(width: pixelWidth * ratio, height: pixelHeight * ratio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.pngData()
    }
}
