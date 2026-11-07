import Foundation

public enum ClosetError: Error, Equatable, Sendable {
    case freeLimitReached
    case proRequired
}

public enum ClosetCap {
    public static let freeLimit = 40

    public static func canAddGarment(existingCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return existingCount >= 0 && existingCount < freeLimit
    }

    public static func remainingFreeSlots(existingCount: Int) -> Int {
        max(0, freeLimit - max(0, existingCount))
    }
}

public struct ClosetPiece: Equatable, Sendable, Identifiable {
    public var id: UUID
    public var name: String
    public var wearCount: Int
    public var price: Decimal?

    public init(id: UUID, name: String, wearCount: Int, price: Decimal?) {
        self.id = id
        self.name = name
        self.wearCount = wearCount
        self.price = price
    }
}

public enum WardrobeMath {
    /// Price divided by wears. Unworn pieces return nil so the closet never shows a fake cost.
    public static func costPerWear(price: Decimal?, wearCount: Int) -> Decimal? {
        guard wearCount > 0, let price, price >= 0 else { return nil }
        return price / Decimal(wearCount)
    }

    /// Pieces with no wears, sorted by name. This is the unworn list, not a cost of the purchase price.
    public static func unworn(_ pieces: [ClosetPiece]) -> [ClosetPiece] {
        pieces
            .filter { $0.wearCount <= 0 }
            .sorted { lhs, rhs in
                let order = lhs.name.localizedStandardCompare(rhs.name)
                if order == .orderedSame {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return order == .orderedAscending
            }
    }

    /// +1 for a piece added to the day, −1 for a piece removed. Wearing the same piece again the same day is not another wear.
    public static func wearDeltas(previous: Set<UUID>, next: Set<UUID>) -> [UUID: Int] {
        var deltas: [UUID: Int] = [:]
        for id in next.subtracting(previous) {
            deltas[id] = 1
        }
        for id in previous.subtracting(next) {
            deltas[id] = -1
        }
        return deltas
    }

    public static func wearCounts(
        afterReplacing previous: Set<UUID>,
        with next: Set<UUID>,
        current: [UUID: Int]
    ) -> [UUID: Int] {
        var counts = current
        for (id, delta) in wearDeltas(previous: previous, next: next) {
            counts[id] = max(0, (counts[id] ?? 0) + delta)
        }
        return counts
    }
}

public struct TripChecklist: Equatable, Sendable {
    public var garmentIDs: [UUID]
    public var packedIDs: Set<UUID>

    public init(garmentIDs: [UUID], packedIDs: Set<UUID> = []) {
        var seen = Set<UUID>()
        let unique = garmentIDs.filter { seen.insert($0).inserted }
        self.garmentIDs = unique
        self.packedIDs = packedIDs.intersection(seen)
    }

    public func isPacked(_ id: UUID) -> Bool {
        packedIDs.contains(id)
    }

    public func togglingPacked(_ id: UUID) -> TripChecklist {
        guard garmentIDs.contains(id) else { return self }
        var packed = packedIDs
        if packed.contains(id) {
            packed.remove(id)
        } else {
            packed.insert(id)
        }
        return TripChecklist(garmentIDs: garmentIDs, packedIDs: packed)
    }

    public var packedCount: Int { packedIDs.count }
}

public enum PriceInput {
    /// Empty text means no price. A parsed value is cents, rounded to the nearest cent.
    public static func cents(from text: String, locale: Locale = .current) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        let symbol = formatter.currencySymbol ?? ""
        let normalized = trimmed.replacingOccurrences(of: symbol, with: "").trimmingCharacters(in: .whitespaces)
        guard let number = formatter.number(from: normalized) else { return nil }

        let value = number.decimalValue
        guard value >= 0 else { return nil }
        var cents = value * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &cents, 0, .plain)
        guard rounded <= 1_000_000_000 else { return nil }
        return NSDecimalNumber(decimal: rounded).intValue
    }

    public static func decimalString(cents: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let amount = Decimal(cents) / 100
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}

public enum Money {
    public static func string(amount: Decimal, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
