import SwiftUI
import UIKit
import WoreCore

struct CutoutBackdrop: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 10
            let columns = Int(size.width / cell) + 1
            let rows = Int(size.height / cell) + 1
            for row in 0..<rows {
                for column in 0..<columns where (row + column).isMultiple(of: 2) {
                    let rect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                    context.fill(Path(rect), with: .color(Color.primary.opacity(0.06)))
                }
            }
        }
        .background(Color.primary.opacity(0.03))
    }
}

struct GarmentImage: View {
    var filename: String?
    var systemImage: String = "tshirt"

    var body: some View {
        ZStack {
            CutoutBackdrop()
            if let filename, let data = PhotoStore.load(filename), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

func garmentSubtitle(_ garment: Garment, isPro: Bool) -> String {
    if isPro, let cost = garment.costPerWear {
        return "\(Money.string(amount: cost)) / wear"
    }
    if garment.wearCount <= 0 {
        return "Not worn yet"
    }
    if garment.wearCount == 1 {
        return "Worn once"
    }
    return "Worn \(garment.wearCount) times"
}
