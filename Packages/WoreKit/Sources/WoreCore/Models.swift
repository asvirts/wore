import Foundation
import SwiftData

public enum GarmentCategory: String, Codable, CaseIterable, Sendable, Identifiable {
    case top
    case bottom
    case dress
    case outerwear
    case shoes
    case bag
    case accessory

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .top: "Top"
        case .bottom: "Bottom"
        case .dress: "Dress"
        case .outerwear: "Outerwear"
        case .shoes: "Shoes"
        case .bag: "Bag"
        case .accessory: "Accessory"
        }
    }

    public var symbol: String {
        switch self {
        case .top: "tshirt"
        case .bottom: "pants"
        case .dress: "tshirt.fill"
        case .outerwear: "cloud.snow"
        case .shoes: "shoe.fill"
        case .bag: "bag.fill"
        case .accessory: "eyeglasses"
        }
    }
}

public enum GarmentColor: String, CaseIterable, Sendable, Identifiable {
    case black, white, gray, navy, blue, green, olive, brown, beige, cream, red, pink, yellow, purple

    public var id: String { rawValue }

    public var title: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

@Model
public final class Garment {
    public var id: UUID = UUID()
    public var name: String = ""
    public var categoryRaw: String = GarmentCategory.top.rawValue
    public var colorName: String = ""
    public var priceCents: Int?
    public var wearCount: Int = 0
    public var createdAt: Date = Date.now
    public var photoFilename: String?
    public var thumbnailFilename: String?
    public var didUseCutout: Bool = false

    public init(
        name: String,
        category: GarmentCategory,
        colorName: String,
        priceCents: Int?,
        photoFilename: String?,
        thumbnailFilename: String?,
        didUseCutout: Bool,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.colorName = colorName
        self.priceCents = priceCents
        self.wearCount = 0
        self.createdAt = createdAt
        self.photoFilename = photoFilename
        self.thumbnailFilename = thumbnailFilename
        self.didUseCutout = didUseCutout
    }

    public var category: GarmentCategory {
        get { GarmentCategory(rawValue: categoryRaw) ?? .top }
        set { categoryRaw = newValue.rawValue }
    }

    public var price: Decimal? {
        guard let priceCents else { return nil }
        return Decimal(priceCents) / 100
    }

    /// Nil until the first wear, and nil when no price was entered.
    public var costPerWear: Decimal? {
        WardrobeMath.costPerWear(price: price, wearCount: wearCount)
    }
}

@Model
public final class OutfitDay {
    public var id: UUID = UUID()
    public var dayKey: String = ""
    public var garmentIDs: [UUID] = []

    public init(dayKey: String, garmentIDs: [UUID] = []) {
        self.id = UUID()
        self.dayKey = dayKey
        self.garmentIDs = garmentIDs
    }
}

@Model
public final class TripList {
    public var id: UUID = UUID()
    public var name: String = ""
    public var createdAt: Date = Date.now
    public var garmentIDs: [UUID] = []
    public var packedIDs: [UUID] = []

    public init(name: String, createdAt: Date = .now) {
        self.id = UUID()
        self.name = name
        self.createdAt = createdAt
    }
}
