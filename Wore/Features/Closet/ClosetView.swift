import SwiftData
import SwiftUI
import WoreCore
import WoreStore

struct ClosetView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @Query(sort: \Garment.createdAt, order: .reverse) private var garments: [Garment]

    @State private var search = ""
    @State private var category: GarmentCategory?
    @State private var showSettings = false

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: sizeClass == .regular ? 160 : 108), spacing: 12)]
    }

    private var shown: [Garment] {
        garments.filter { garment in
            if let category, garment.category != category { return false }
            let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return true }
            let haystack = "\(garment.name) \(garment.colorName)".localizedLowercase
            return haystack.contains(query.localizedLowercase)
        }
    }

    var body: some View {
        @Bindable var router = router
        return NavigationStack {
            Group {
                if garments.isEmpty {
                    empty
                } else {
                    grid
                }
            }
            .navigationTitle("Closet")
            .searchable(text: $search, prompt: "Name or color")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addTapped()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a garment")
                }
            }
            .sheet(isPresented: $router.showAdd) {
                NavigationStack {
                    AddGarmentView()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showUnworn) {
                UnwornView()
            }
        }
    }

    private var empty: some View {
        ContentUnavailableView {
            Label("Your closet", systemImage: "hanger")
        } description: {
            Text("Photograph a piece you own. A few clothes are enough to start logging what you wear.")
        } actions: {
            Button("Add a garment") { addTapped() }
                .buttonStyle(.borderedProminent)
        }
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                categoryChips
                if !entitlements.isPro {
                    freeSlots
                }
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(shown) { garment in
                        NavigationLink {
                            GarmentDetailView(garment: garment)
                        } label: {
                            garmentCell(garment)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if shown.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .padding()
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", selected: category == nil) { category = nil }
                chip("Unworn", selected: false) { openUnworn() }
                ForEach(GarmentCategory.allCases) { item in
                    chip(item.title, selected: category == item) {
                        category = category == item ? nil : item
                    }
                }
            }
        }
    }

    private var freeSlots: some View {
        let remaining = ClosetCap.remainingFreeSlots(existingCount: garments.count)
        return Text(remaining == 0 ? "40 of 40 free garments. Pro removes the cap." : "\(garments.count) of \(ClosetCap.freeLimit) free garments")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func garmentCell(_ garment: Garment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GarmentImage(filename: garment.thumbnailFilename ?? garment.photoFilename, systemImage: garment.category.symbol)
            Text(garment.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)
            Text(garmentSubtitle(garment, isPro: entitlements.isPro))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(selected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func addTapped() {
        if ClosetCap.canAddGarment(existingCount: garments.count, isPro: entitlements.isPro) {
            router.showAdd = true
        } else {
            router.showPaywall = true
        }
    }

    private func openUnworn() {
        if entitlements.isPro {
            showUnworn = true
        } else {
            router.showPaywall = true
        }
    }

    @State private var showUnworn = false
}
