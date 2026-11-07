import SwiftData
import SwiftUI
import WoreCore

struct TodayOutfitView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \Garment.name) private var garments: [Garment]
    @Query private var outfits: [OutfitDay]

    private var dayKey: String { DayKey.key(for: .now) }

    private var todayIDs: [UUID] {
        outfits.first { $0.dayKey == dayKey }?.garmentIDs ?? []
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: sizeClass == .regular ? 150 : 104), spacing: 12)]
    }

    var body: some View {
        NavigationStack {
            Group {
                if garments.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing to wear yet", systemImage: "tshirt")
                    } description: {
                        Text("Add a few pieces. Then tap them here to log today.")
                    } actions: {
                        Button("Go to closet") { router.tab = .closet }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    list
                }
            }
            .navigationTitle("Today")
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(todayIDs.isEmpty ? "Tap what you wore." : "\(todayIDs.count) today. Tap again to take a piece off.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(GarmentCategory.allCases) { category in
                    let items = garments.filter { $0.category == category }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.title)
                                .font(.headline)
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(items) { garment in
                                    Button {
                                        toggle(garment.id)
                                    } label: {
                                        todayCell(garment, selected: todayIDs.contains(garment.id))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .sensoryFeedback(.selection, trigger: todayIDs)
    }

    private func todayCell(_ garment: Garment, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GarmentImage(filename: garment.thumbnailFilename ?? garment.photoFilename, systemImage: garment.category.symbol)
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.accentColor)
                            .padding(6)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
                }
            Text(garment.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .accessibilityLabel(garment.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func toggle(_ id: UUID) {
        var ids = todayIDs
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.append(id)
        }
        ClosetActions(context: modelContext).setTodayOutfit(garmentIDs: ids, dayKey: dayKey)
    }
}
