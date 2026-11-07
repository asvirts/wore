import CoreImage
import Foundation
import Vision
import WoreCore

public enum GarmentCutout: Sendable {
    /// Removes the background on device with `VNGenerateForegroundInstanceMaskRequest`.
    /// Returns a PNG of the subject, or nil when Vision cannot separate one. The caller then keeps the original photo and can crop it.
    public static func removeBackground(from imageData: Data) -> Data? {
        guard let cgImage = ImageFiles.cgImage(from: imageData, maxPixel: 1600) else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
                return nil
            }
            let buffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            return pngData(from: buffer)
        } catch {
            return nil
        }
    }

    private static func pngData(from pixelBuffer: CVPixelBuffer) -> Data? {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        guard image.extent.width > 1, image.extent.height > 1, !image.extent.isInfinite else { return nil }
        let context = CIContext(options: [.cacheIntermediates: false])
        guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
        return ImageFiles.pngData(from: cgImage)
    }
}

public enum ImageCropper: Sendable {
    /// Crops a PNG. `normalizedTopLeft` is a unit rectangle with a top-left origin.
    public static func cropPNG(_ data: Data, normalizedTopLeft: CGRect) -> Data? {
        guard let image = ImageFiles.cgImage(from: data) else { return nil }
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        guard width > 1, height > 1 else { return nil }

        var rect = CGRect(
            x: normalizedTopLeft.origin.x * width,
            y: normalizedTopLeft.origin.y * height,
            width: normalizedTopLeft.width * width,
            height: normalizedTopLeft.height * height
        ).integral
        rect.origin.x = min(max(0, rect.origin.x), width - 1)
        rect.origin.y = min(max(0, rect.origin.y), height - 1)
        rect.size.width = min(max(1, rect.width), width - rect.origin.x)
        rect.size.height = min(max(1, rect.height), height - rect.origin.y)
        guard let cropped = image.cropping(to: rect) else { return nil }
        return ImageFiles.pngData(from: cropped)
    }
}
