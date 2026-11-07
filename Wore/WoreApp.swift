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
        }
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
