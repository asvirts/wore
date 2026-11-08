import SwiftData
import SwiftUI
import WoreCore
import WoreStore

@main
struct WoreApp: App {
    private let container: ModelContainer
    @State private var router = AppRouter()
    @State private var entitlements = EntitlementManager()

    init() {
        do {
            container = try PersistenceController.makeContainer()
        } catch {
            assertionFailure("Failed to open closet: \(error)")
            container = try! PersistenceController.makeContainer(inMemory: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(entitlements)
                .modelContainer(container)
                .onOpenURL { router.handle($0) }
                .task {
                    await entitlements.start()
                }
                .task {
                    let actions = ClosetActions(context: container.mainContext)
                    actions.refreshTodaySnapshot(dayKey: DayKey.key(for: .now))
                }
                .onChange(of: router.triggerSeed) { _, shouldSeed in
                    guard shouldSeed else { return }
                    router.triggerSeed = false
                    seedDemoData()
                }
        }
    }

    @MainActor
    private func seedDemoData() {
        let ctx = container.mainContext
        try? ctx.delete(model: Garment.self)
        try? ctx.delete(model: OutfitDay.self)
        try? ctx.delete(model: TripList.self)

        let trench = Garment(name: "Classic Trench Coat", category: .outerwear, colorName: "Khaki", priceCents: 18_000, photoFilename: nil, thumbnailFilename: nil, didUseCutout: true)
        trench.wearCount = 6

        let cashmere = Garment(name: "Cashmere Crewneck", category: .top, colorName: "Oatmeal", priceCents: 12_000, photoFilename: nil, thumbnailFilename: nil, didUseCutout: true)
        cashmere.wearCount = 10

        let oxford = Garment(name: "Oxford Cotton Shirt", category: .top, colorName: "Light Blue", priceCents: 7_500, photoFilename: nil, thumbnailFilename: nil, didUseCutout: true)
        oxford.wearCount = 15

        let denim = Garment(name: "Selvedge Denim Jeans", category: .bottom, colorName: "Indigo", priceCents: 14_000, photoFilename: nil, thumbnailFilename: nil, didUseCutout: true)
        denim.wearCount = 28

        let sneakers = Garment(name: "Canvas Low Sneakers", category: .shoes, colorName: "White", priceCents: 6_500, photoFilename: nil, thumbnailFilename: nil, didUseCutout: true)
        sneakers.wearCount = 32

        let trousers = Garment(name: "Pleated Wool Trousers", category: .bottom, colorName: "Charcoal", priceCents: 11_000, photoFilename: nil, thumbnailFilename: nil, didUseCutout: false)
        trousers.wearCount = 0

        let loafers = Garment(name: "Leather Penny Loafers", category: .shoes, colorName: "Black", priceCents: 19_500, photoFilename: nil, thumbnailFilename: nil, didUseCutout: true)
        loafers.wearCount = 4

        let linen = Garment(name: "Linen Overshirt", category: .top, colorName: "Olive", priceCents: 8_500, photoFilename: nil, thumbnailFilename: nil, didUseCutout: false)
        linen.wearCount = 0

        let bag = Garment(name: "Leather Weekend Duffle", category: .bag, colorName: "Cognac", priceCents: 22_000, photoFilename: nil, thumbnailFilename: nil, didUseCutout: true)
        bag.wearCount = 8

        let watch = Garment(name: "Field Watch", category: .accessory, colorName: "Silver", priceCents: 15_000, photoFilename: nil, thumbnailFilename: nil, didUseCutout: true)
        watch.wearCount = 45

        for g in [trench, cashmere, oxford, denim, sneakers, trousers, loafers, linen, bag, watch] {
            ctx.insert(g)
        }

        let dayKey = DayKey.key(for: .now)
        let todayOutfit = OutfitDay(dayKey: dayKey, garmentIDs: [oxford.id, denim.id, sneakers.id, watch.id])
        ctx.insert(todayOutfit)

        let trip = TripList(name: "Weekend in Montreal")
        trip.garmentIDs = [trench.id, cashmere.id, oxford.id, denim.id, sneakers.id, loafers.id, bag.id]
        trip.packedIDs = [oxford.id, denim.id, sneakers.id]
        ctx.insert(trip)

        UserDefaults.wore.set(true, forKey: SettingsKey.isProCached)
        try? ctx.save()

        let actions = ClosetActions(context: ctx)
        actions.refreshTodaySnapshot(dayKey: dayKey)
    }
}

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            ClosetView()
                .tabItem { Label("Closet", systemImage: "tshirt") }
                .tag(AppTab.closet)
            TodayOutfitView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)
            TripsView()
                .tabItem { Label("Trips", systemImage: "suitcase") }
                .tag(AppTab.trips)
        }
        .sheet(isPresented: $router.showPaywall) {
            PaywallSheet()
        }
    }
}
