import SwiftUI
import UIKit

struct CropCanvas: View {
    let image: UIImage
    @Binding var crop: CGRect

    var body: some View {
        GeometryReader { proxy in
            let fitted = aspectFit(imageSize: image.size, in: proxy.size)
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                CropOverlay(fitted: fitted, crop: $crop)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct CropOverlay: View {
    let fitted: CGRect
    @Binding var crop: CGRect
    @State private var moveStart: CGRect?
    @State private var resizeStart: CGRect?

    private var box: CGRect {
        CGRect(
            x: fitted.minX + crop.minX * fitted.width,
            y: fitted.minY + crop.minY * fitted.height,
            width: max(crop.width * fitted.width, 1),
            height: max(crop.height * fitted.height, 1)
        )
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                var path = Path(CGRect(origin: .zero, size: size))
                path.addRect(box)
                context.fill(path, with: .color(.black.opacity(0.45)), style: FillStyle(eoFill: true))
            }
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(.white, lineWidth: 2)
                .frame(width: box.width, height: box.height)
                .position(x: box.midX, y: box.midY)
                .gesture(moveGesture)
                .accessibilityLabel("Crop area")
                .accessibilityHint("Drag to move the crop.")

            Circle()
                .fill(.white)
                .frame(width: 26, height: 26)
                .position(x: box.maxX, y: box.maxY)
                .gesture(resizeGesture)
                .accessibilityLabel("Resize crop")
        }
    }

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard fitted.width > 1, fitted.height > 1 else { return }
                if moveStart == nil { moveStart = crop }
                guard let start = moveStart else { return }
                var next = start
                next.origin.x += value.translation.width / fitted.width
                next.origin.y += value.translation.height / fitted.height
                crop = clamp(next)
            }
            .onEnded { _ in
                moveStart = nil
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard fitted.width > 1, fitted.height > 1 else { return }
                if resizeStart == nil { resizeStart = crop }
                guard let start = resizeStart else { return }
                var next = start
                next.size.width += value.translation.width / fitted.width
                next.size.height += value.translation.height / fitted.height
                crop = clamp(next)
            }
            .onEnded { _ in
                resizeStart = nil
            }
    }

    private func clamp(_ rect: CGRect) -> CGRect {
        var next = rect
        next.size.width = min(max(next.size.width, 0.12), 1)
        next.size.height = min(max(next.size.height, 0.12), 1)
        next.origin.x = min(max(0, next.origin.x), 1 - next.size.width)
        next.origin.y = min(max(0, next.origin.y), 1 - next.size.height)
        return next
    }
}

private func aspectFit(imageSize: CGSize, in bounds: CGSize) -> CGRect {
    guard imageSize.width > 0, imageSize.height > 0, bounds.width > 0, bounds.height > 0 else {
        return CGRect(origin: .zero, size: bounds)
    }
    let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
    let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    let origin = CGPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2)
    return CGRect(origin: origin, size: size)
}
