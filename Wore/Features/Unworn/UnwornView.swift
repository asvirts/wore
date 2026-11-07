import SwiftUI
import WoreCore
import WoreStore

struct UnwornView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @State private var garments: [Garment] = []

    var body: some View {
        Group {
            if !entitlements.isPro {
                locked
            } else if garments.isEmpty {
                ContentUnavailableView {
                    Label("Nothing unworn", systemImage: "checkmark.circle")
                } description: {
                    Text("Every piece in the closet has been worn at least once.")
                }
            } else {
                List(garments) { garment in
                    NavigationLink {
                        GarmentDetailView(garment: garment)
                    } label: {
                        HStack(spacing: 12) {
                            GarmentImage(filename: garment.thumbnailFilename ?? garment.photoFilename, systemImage: garment.category.symbol)
                                .frame(width: 56, height: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(garment.name)
                                Text(garment.category.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Unworn")
        .onAppear(perform: reload)
    }

    private var locked: some View {
        ContentUnavailableView {
            Label("Unworn", systemImage: "lock")
        } description: {
            Text("The unworn list is part of Wore Pro. Pieces you haven't worn stay out of cost per wear until you do.")
        } actions: {
            Button("Unlock Wore Pro") { router.showPaywall = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func reload() {
        garments = ClosetActions(context: modelContext).unwornGarments()
    }
}
