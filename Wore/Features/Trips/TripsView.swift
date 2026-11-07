import SwiftData
import SwiftUI
import WoreCore
import WoreStore

struct TripsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @Query(sort: \TripList.createdAt, order: .reverse) private var trips: [TripList]
    @State private var showNew = false
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            Group {
                if !entitlements.isPro {
                    locked
                } else if trips.isEmpty {
                    ContentUnavailableView {
                        Label("No trips", systemImage: "suitcase")
                    } description: {
                        Text("A trip is a checklist of pieces you already own, with a packed mark.")
                    } actions: {
                        Button("New trip") { showNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(trips) { trip in
                            NavigationLink {
                                TripDetailView(trip: trip)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trip.name)
                                    Text(packedSummary(trip))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                if entitlements.isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            draftName = ""
                            showNew = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("New trip")
                    }
                }
            }
            .alert("New trip", isPresented: $showNew) {
                TextField("Name", text: $draftName)
                Button("Add") { createTrip() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var locked: some View {
        ContentUnavailableView {
            Label("Trip lists", systemImage: "lock")
        } description: {
            Text("Pack a checklist of clothes you already own. Trip lists are part of Wore Pro.")
        } actions: {
            Button("Unlock Wore Pro") { router.showPaywall = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func packedSummary(_ trip: TripList) -> String {
        let packed = trip.packedIDs.count
        let total = trip.garmentIDs.count
        if total == 0 { return "No pieces yet" }
        return "\(packed) of \(total) packed"
    }

    private func createTrip() {
        guard entitlements.isPro else {
            router.showPaywall = true
            return
        }
        do {
            _ = try ClosetActions(context: modelContext).addTrip(name: draftName, isPro: true)
        } catch ClosetError.proRequired {
            router.showPaywall = true
        } catch {}
    }

    private func delete(at offsets: IndexSet) {
        let actions = ClosetActions(context: modelContext)
        for index in offsets {
            actions.deleteTrip(trips[index])
        }
    }
}

struct TripDetailView: View {
    @Bindable var trip: TripList

    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @Query(sort: \Garment.name) private var garments: [Garment]
    @State private var name: String = ""
    @State private var showPicker = false

    var body: some View {
        List {
            Section {
                TextField("Trip name", text: $name)
                    .onSubmit(saveName)
            }
            if listed.isEmpty {
                ContentUnavailableView("No pieces", systemImage: "tshirt", description: Text("Add clothes from your closet."))
            } else {
                Section {
                    ForEach(listed) { garment in
                        Button {
                            toggle(garment.id)
                        } label: {
                            HStack(spacing: 12) {
                                GarmentImage(filename: garment.thumbnailFilename ?? garment.photoFilename, systemImage: garment.category.symbol)
                                    .frame(width: 48, height: 48)
                                Text(garment.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: trip.packedIDs.contains(garment.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(trip.packedIDs.contains(garment.id) ? Color.accentColor : .secondary)
                            }
                        }
                        .accessibilityLabel(garment.name)
                        .accessibilityValue(trip.packedIDs.contains(garment.id) ? "Packed" : "Not packed")
                    }
                } header: {
                    Text("\(trip.packedIDs.count) of \(listed.count) packed")
                }
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add pieces") { showPicker = true }
            }
        }
        .onAppear { name = trip.name }
        .onDisappear(perform: saveName)
        .sheet(isPresented: $showPicker) {
            TripPiecePicker(trip: trip, garments: garments)
        }
    }

    private var listed: [Garment] {
        let ids = trip.garmentIDs
        return garments.filter { ids.contains($0.id) }
    }

    private func toggle(_ id: UUID) {
        guard entitlements.isPro else {
            router.showPaywall = true
            return
        }
        try? ClosetActions(context: modelContext).togglePacked(trip, garmentID: id, isPro: true)
    }

    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.name = trimmed.isEmpty ? "Trip" : trimmed
        ClosetActions(context: modelContext).saveEdits()
    }
}

private struct TripPiecePicker: View {
    @Bindable var trip: TripList
    let garments: [Garment]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selected: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List(garments) { garment in
                Button {
                    if selected.contains(garment.id) {
                        selected.remove(garment.id)
                    } else {
                        selected.insert(garment.id)
                    }
                } label: {
                    HStack {
                        Text(garment.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selected.contains(garment.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Add pieces")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { selected = Set(trip.garmentIDs) }
        }
    }

    private func save() {
        let ordered = garments.map(\.id).filter { selected.contains($0) }
        try? ClosetActions(context: modelContext).setTripGarments(trip, garmentIDs: ordered, isPro: true)
        dismiss()
    }
}
