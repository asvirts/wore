import SwiftData
import SwiftUI
import WoreCore
import WoreStore

struct GarmentDetailView: View {
    @Bindable var garment: Garment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router

    @State private var showEditor = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                GarmentImage(filename: garment.photoFilename ?? garment.thumbnailFilename, systemImage: garment.category.symbol)
                    .frame(maxWidth: sizeClass == .regular ? 420 : .infinity)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    Text(garment.name)
                        .font(.title2.bold())
                    Text(detailLine)
                        .foregroundStyle(.secondary)
                }

                costBlock

                LabeledContent("Wears", value: garment.wearCount == 0 ? "None yet" : "\(garment.wearCount)")
            }
            .padding()
        }
        .navigationTitle(garment.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditor = true }
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Delete", role: .destructive) { showDeleteConfirm = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                AddGarmentView(garment: garment)
            }
        }
        .confirmationDialog("Delete \(garment.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete garment", role: .destructive) {
                ClosetActions(context: modelContext).delete(garment)
                dismiss()
            }
        } message: {
            Text("The photo stays deleted on this device. This does not change other pieces.")
        }
    }

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var detailLine: String {
        [garment.category.title, garment.colorName].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    @ViewBuilder
    private var costBlock: some View {
        if entitlements.isPro {
            if let cost = garment.costPerWear {
                LabeledContent("Cost per wear", value: Money.string(amount: cost))
            } else if garment.wearCount <= 0 {
                Text("Not worn yet. Cost per wear starts after the first wear.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if garment.priceCents == nil {
                Text("Add a price to see cost per wear.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if garment.priceCents != nil {
            Button {
                router.showPaywall = true
            } label: {
                Label("See cost per wear", systemImage: "lock")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
