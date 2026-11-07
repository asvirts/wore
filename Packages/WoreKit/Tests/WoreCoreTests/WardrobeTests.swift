import Foundation
import SwiftData
import Testing
@testable import WoreCore

@Suite struct CostPerWearTests {
    @Test func dividesPriceByWearsAfterTheFirstWear() {
        #expect(WardrobeMath.costPerWear(price: Decimal(80), wearCount: 4) == Decimal(20))
        #expect(WardrobeMath.costPerWear(price: Decimal(30), wearCount: 4) == Decimal(string: "7.5"))
        #expect(WardrobeMath.costPerWear(price: Decimal(10), wearCount: 1) == Decimal(10))
        #expect(WardrobeMath.costPerWear(price: Decimal(0), wearCount: 2) == Decimal(0))
    }

    @Test func unwornAndMissingPriceAreNotAFakeCost() {
        #expect(WardrobeMath.costPerWear(price: Decimal(200), wearCount: 0) == nil)
        #expect(WardrobeMath.costPerWear(price: nil, wearCount: 5) == nil)
        #expect(WardrobeMath.costPerWear(price: Decimal(-1), wearCount: 3) == nil)
    }
}

@Suite struct UnwornListTests {
    @Test func unwornPiecesStayOnTheirOwnListWithoutAFakeCost() {
        let coat = ClosetPiece(id: UUID(), name: "Coat", wearCount: 0, price: 200)
        let tee = ClosetPiece(id: UUID(), name: "Tee", wearCount: 2, price: 40)
        let hat = ClosetPiece(id: UUID(), name: "Hat", wearCount: 0, price: nil)
        let socks = ClosetPiece(id: UUID(), name: "Socks", wearCount: 1, price: nil)

        let unworn = WardrobeMath.unworn([tee, hat, coat, socks])
        #expect(unworn.map(\.name) == ["Coat", "Hat"])
        for piece in unworn {
            #expect(WardrobeMath.costPerWear(price: piece.price, wearCount: piece.wearCount) == nil)
        }
        #expect(WardrobeMath.costPerWear(price: tee.price, wearCount: tee.wearCount) == 20)
    }

    @Test func sameDayWearDoesNotDoubleCountAndRemovalReturnsThePiece() {
        let shirt = UUID()
        let pants = UUID()
        var counts = [shirt: 0, pants: 0]

        counts = WardrobeMath.wearCounts(afterReplacing: [], with: [shirt, pants], current: counts)
        #expect(counts[shirt] == 1)
        #expect(counts[pants] == 1)

        counts = WardrobeMath.wearCounts(afterReplacing: [shirt, pants], with: [shirt, pants], current: counts)
        #expect(counts[shirt] == 1)

        counts = WardrobeMath.wearCounts(afterReplacing: [shirt, pants], with: [shirt], current: counts)
        #expect(counts[pants] == 0)
        #expect(counts[shirt] == 1)

        let pieces = [
            ClosetPiece(id: shirt, name: "Shirt", wearCount: counts[shirt] ?? 0, price: 40),
            ClosetPiece(id: pants, name: "Pants", wearCount: counts[pants] ?? 0, price: 60),
        ]
        #expect(WardrobeMath.unworn(pieces).map(\.name) == ["Pants"])
    }
}

@Suite struct FreeCapTests {
    @Test func freeClosetCapsAtFortyGarments() {
        #expect(ClosetCap.freeLimit == 40)
        #expect(ClosetCap.canAddGarment(existingCount: 0, isPro: false))
        #expect(ClosetCap.canAddGarment(existingCount: 39, isPro: false))
        #expect(!ClosetCap.canAddGarment(existingCount: 40, isPro: false))
        #expect(!ClosetCap.canAddGarment(existingCount: 41, isPro: false))
        #expect(ClosetCap.canAddGarment(existingCount: 40, isPro: true))
        #expect(ClosetCap.canAddGarment(existingCount: 500, isPro: true))
        #expect(ClosetCap.remainingFreeSlots(existingCount: 37) == 3)
        #expect(ClosetCap.remainingFreeSlots(existingCount: 40) == 0)
    }

    @Test func tripChecklistTogglesPackedState() {
        let coat = UUID()
        let tee = UUID()
        var list = TripChecklist(garmentIDs: [coat, tee])
        #expect(!list.isPacked(coat))
        #expect(list.packedCount == 0)

        list = list.togglingPacked(coat)
        #expect(list.isPacked(coat))
        #expect(!list.isPacked(tee))
        #expect(list.packedCount == 1)

        list = list.togglingPacked(coat)
        #expect(!list.isPacked(coat))

        let stranger = UUID()
        let unchanged = list.togglingPacked(stranger)
        #expect(unchanged == list)
    }

    @Test func priceFieldTreatsBlankAsNoPrice() {
        let locale = Locale(identifier: "en_US")
        #expect(PriceInput.cents(from: "", locale: locale) == nil)
        #expect(PriceInput.cents(from: "   ", locale: locale) == nil)
        #expect(PriceInput.cents(from: "79.99", locale: locale) == 7999)
        #expect(PriceInput.cents(from: "0", locale: locale) == 0)
        #expect(PriceInput.cents(from: "nope", locale: locale) == nil)
    }

    @Test func dayKeyUsesTheCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 23))!
        #expect(DayKey.key(for: date, calendar: calendar) == "2026-11-07")
    }
}

@MainActor
@Suite struct ClosetStoreTests {
    let container: ModelContainer
    let actions: ClosetActions

    init() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("wore-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        WorePaths.containerOverride = directory
        container = try PersistenceController.makeContainer(inMemory: true)
        actions = ClosetActions(context: container.mainContext)
    }

    private func wearCount(_ id: UUID) throws -> Int {
        let garments = try container.mainContext.fetch(FetchDescriptor<Garment>())
        return try #require(garments.first { $0.id == id }).wearCount
    }

    @Test func storeRefusesTheFortyFirstFreeGarmentAndProCanPassIt() throws {
        var first: Garment?
        for index in 0..<40 {
            let garment = try actions.addGarment(name: "Piece \(index)", isPro: false)
            if index == 0 { first = garment }
        }
        #expect(throws: ClosetError.freeLimitReached) {
            try actions.addGarment(name: "Extra", isPro: false)
        }
        _ = try actions.addGarment(name: "Pro piece", isPro: true)
        #expect(actions.garmentCount() == 41)

        actions.delete(try #require(first))
        #expect(actions.garmentCount() == 40)
        #expect(throws: ClosetError.freeLimitReached) {
            try actions.addGarment(name: "Still at the cap", isPro: false)
        }
    }

    @Test func deletingAGarmentFreesAFreeSlot() throws {
        var created: [Garment] = []
        for index in 0..<40 {
            created.append(try actions.addGarment(name: "Piece \(index)", isPro: false))
        }
        actions.delete(created[0])
        _ = try actions.addGarment(name: "Replacement", isPro: false)
        #expect(actions.garmentCount() == 40)
        #expect(throws: ClosetError.freeLimitReached) {
            try actions.addGarment(name: "One past the cap", isPro: false)
        }
    }

    @Test func loggingAnOutfitUpdatesCostAndTheUnwornList() throws {
        let coat = try actions.addGarment(name: "Coat", category: .outerwear, priceCents: 8_000, isPro: false)
        let tee = try actions.addGarment(name: "Tee", category: .top, priceCents: 2_000, isPro: false)
        #expect(actions.unwornGarments().map(\.name).sorted() == ["Coat", "Tee"])
        #expect(coat.costPerWear == nil)

        actions.setTodayOutfit(garmentIDs: [coat.id], dayKey: "2026-11-07")
        #expect(try wearCount(coat.id) == 1)
        #expect(try wearCount(tee.id) == 0)
        #expect(coat.costPerWear == 80)
        #expect(tee.costPerWear == nil)
        #expect(actions.unwornGarments().map(\.id) == [tee.id])

        actions.setTodayOutfit(garmentIDs: [coat.id], dayKey: "2026-11-07")
        #expect(try wearCount(coat.id) == 1)

        actions.setTodayOutfit(garmentIDs: [coat.id, tee.id], dayKey: "2026-11-08")
        #expect(try wearCount(coat.id) == 2)
        #expect(try wearCount(tee.id) == 1)
        #expect(coat.costPerWear == 40)
        #expect(actions.unwornGarments().isEmpty)

        actions.setTodayOutfit(garmentIDs: [coat.id], dayKey: "2026-11-08")
        #expect(try wearCount(tee.id) == 0)
        #expect(actions.unwornGarments().map(\.id) == [tee.id])
        #expect(tee.costPerWear == nil)
    }

    @Test func tripsStayBehindProAndRememberWhatIsPacked() throws {
        let tee = try actions.addGarment(name: "Tee", isPro: false)
        #expect(throws: ClosetError.proRequired) {
            try actions.addTrip(name: "Weekend", isPro: false)
        }
        let trip = try actions.addTrip(name: "Weekend", isPro: true)
        try actions.setTripGarments(trip, garmentIDs: [tee.id], isPro: true)
        #expect(trip.packedIDs.isEmpty)
        try actions.togglePacked(trip, garmentID: tee.id, isPro: true)
        #expect(trip.packedIDs == [tee.id])
        try actions.togglePacked(trip, garmentID: tee.id, isPro: true)
        #expect(trip.packedIDs.isEmpty)
    }
}

@Suite struct WoreConfigTests {
    @Test func configHasValidIdentifiersAndURLs() {
        #expect(WoreConfig.displayName == "Wore")
        #expect(WoreConfig.bundleID == "com.asvirts.wore")
        #expect(WoreConfig.appGroupID == "group.com.asvirts.wore")
        #expect(WoreConfig.proProductID == "com.asvirts.wore.pro")
        #expect(WoreConfig.privacyPolicyURL.absoluteString == "https://asvirts.github.io/wore/privacy.html")
        #expect(WoreConfig.supportURL.absoluteString == "https://asvirts.github.io/wore/support.html")
        #expect(WoreConfig.termsURL.absoluteString == "https://asvirts.github.io/wore/terms.html")
        #expect(WoreConfig.marketingURL.absoluteString == "https://asvirts.github.io/wore/")
    }
}
