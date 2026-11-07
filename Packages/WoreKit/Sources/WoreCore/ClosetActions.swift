import Foundation
import SwiftData

/// Closet mutations. Wear counts and the free cap go through `WardrobeMath` so the UI cannot invent a cost.
@MainActor
public struct ClosetActions {
    public let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func garmentCount() -> Int {
        allGarments().count
    }

    public func canAdd(isPro: Bool) -> Bool {
        ClosetCap.canAddGarment(existingCount: garmentCount(), isPro: isPro)
    }

    @discardableResult
    public func addGarment(
        name: String,
        category: GarmentCategory = .top,
        colorName: String = "",
        priceCents: Int? = nil,
        photoFilename: String? = nil,
        thumbnailFilename: String? = nil,
        didUseCutout: Bool = false,
        isPro: Bool
    ) throws -> Garment {
        guard canAdd(isPro: isPro) else { throw ClosetError.freeLimitReached }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = trimmed.isEmpty ? category.title : trimmed
        let garment = Garment(
            name: resolved,
            category: category,
            colorName: colorName.trimmingCharacters(in: .whitespacesAndNewlines),
            priceCents: priceCents,
            photoFilename: photoFilename,
            thumbnailFilename: thumbnailFilename,
            didUseCutout: didUseCutout
        )
        context.insert(garment)
        try context.save()
        return garment
    }

    public func saveEdits() {
        try? context.save()
        refreshTodaySnapshot(dayKey: DayKey.key(for: .now))
    }

    public func delete(_ garment: Garment) {
        let id = garment.id
        for outfit in allOutfits() where outfit.garmentIDs.contains(id) {
            outfit.garmentIDs = outfit.garmentIDs.filter { $0 != id }
        }
        for trip in allTrips() {
            trip.garmentIDs = trip.garmentIDs.filter { $0 != id }
            trip.packedIDs = trip.packedIDs.filter { $0 != id }
        }
        PhotoStore.delete(garment.photoFilename)
        PhotoStore.delete(garment.thumbnailFilename)
        context.delete(garment)
        try? context.save()
        refreshTodaySnapshot(dayKey: DayKey.key(for: .now))
    }

    /// Replaces today's outfit. Newly added pieces gain one wear. Removed pieces lose one. Repeating the same set does not count again.
    public func setTodayOutfit(garmentIDs: [UUID], dayKey: String) {
        let garments = allGarments()
        let known = Set(garments.map(\.id))
        let nextIDs = uniquePreservingOrder(garmentIDs).filter { known.contains($0) }
        let outfit = outfitDay(for: dayKey) ?? {
            let created = OutfitDay(dayKey: dayKey)
            context.insert(created)
            return created
        }()
        let current = Dictionary(uniqueKeysWithValues: garments.map { ($0.id, $0.wearCount) })
        let updated = WardrobeMath.wearCounts(
            afterReplacing: Set(outfit.garmentIDs),
            with: Set(nextIDs),
            current: current
        )
        for garment in garments {
            if let count = updated[garment.id], count != garment.wearCount {
                garment.wearCount = count
            }
        }
        outfit.garmentIDs = nextIDs
        try? context.save()
        writeSnapshot(dayKey: dayKey, garmentIDs: nextIDs, garments: garments)
    }

    public func outfitGarmentIDs(dayKey: String) -> [UUID] {
        outfitDay(for: dayKey)?.garmentIDs ?? []
    }

    public func unwornGarments() -> [Garment] {
        let garments = allGarments()
        let pieces = garments.map {
            ClosetPiece(id: $0.id, name: $0.name, wearCount: $0.wearCount, price: $0.price)
        }
        let byID = Dictionary(uniqueKeysWithValues: garments.map { ($0.id, $0) })
        return WardrobeMath.unworn(pieces).compactMap { byID[$0.id] }
    }

    @discardableResult
    public func addTrip(name: String, isPro: Bool) throws -> TripList {
        guard isPro else { throw ClosetError.proRequired }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trip = TripList(name: trimmed.isEmpty ? "Trip" : trimmed)
        context.insert(trip)
        try context.save()
        return trip
    }

    public func setTripGarments(_ trip: TripList, garmentIDs: [UUID], isPro: Bool) throws {
        guard isPro else { throw ClosetError.proRequired }
        let checklist = TripChecklist(garmentIDs: garmentIDs, packedIDs: Set(trip.packedIDs))
        trip.garmentIDs = checklist.garmentIDs
        trip.packedIDs = checklist.packedIDs.sorted { $0.uuidString < $1.uuidString }
        try context.save()
    }

    public func togglePacked(_ trip: TripList, garmentID: UUID, isPro: Bool) throws {
        guard isPro else { throw ClosetError.proRequired }
        let checklist = TripChecklist(garmentIDs: trip.garmentIDs, packedIDs: Set(trip.packedIDs))
            .togglingPacked(garmentID)
        trip.garmentIDs = checklist.garmentIDs
        trip.packedIDs = checklist.packedIDs.sorted { $0.uuidString < $1.uuidString }
        try context.save()
    }

    public func deleteTrip(_ trip: TripList) {
        context.delete(trip)
        try? context.save()
    }

    public func refreshTodaySnapshot(dayKey: String) {
        let garments = allGarments()
        let ids = outfitDay(for: dayKey)?.garmentIDs ?? []
        writeSnapshot(dayKey: dayKey, garmentIDs: ids, garments: garments)
    }

    private func allGarments() -> [Garment] {
        (try? context.fetch(FetchDescriptor<Garment>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
    }

    private func allOutfits() -> [OutfitDay] {
        (try? context.fetch(FetchDescriptor<OutfitDay>())) ?? []
    }

    private func allTrips() -> [TripList] {
        (try? context.fetch(FetchDescriptor<TripList>())) ?? []
    }

    private func outfitDay(for dayKey: String) -> OutfitDay? {
        let key = dayKey
        let descriptor = FetchDescriptor<OutfitDay>(predicate: #Predicate { $0.dayKey == key })
        return try? context.fetch(descriptor).first
    }

    private func uniquePreservingOrder(_ ids: [UUID]) -> [UUID] {
        var seen = Set<UUID>()
        return ids.filter { seen.insert($0).inserted }
    }

    private func writeSnapshot(dayKey: String, garmentIDs: [UUID], garments: [Garment]) {
        let byID = Dictionary(uniqueKeysWithValues: garments.map { ($0.id, $0) })
        let pieces = garmentIDs.compactMap { id -> TodayOutfitSnapshot.Piece? in
            guard let garment = byID[id] else { return nil }
            return TodayOutfitSnapshot.Piece(id: id, name: garment.name, thumbnailFilename: garment.thumbnailFilename)
        }
        WidgetSnapshotStore.write(TodayOutfitSnapshot(dayKey: dayKey, pieces: pieces))
        WidgetSync.reloadAll()
    }
}
