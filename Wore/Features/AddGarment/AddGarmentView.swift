import PhotosUI
import SwiftUI
import UIKit
import WoreCore
import WoreStore
import WoreVision

struct AddGarmentView: View {
    var garment: Garment?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router

    @State private var name: String
    @State private var category: GarmentCategory
    @State private var colorName: String
    @State private var priceText: String
    @State private var incoming: IncomingPhoto?
    @State private var isCuttingOut = false
    @State private var status: String?
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var cutoutToken = 0

    init(garment: Garment? = nil) {
        self.garment = garment
        _name = State(initialValue: garment?.name ?? "")
        _category = State(initialValue: garment?.category ?? .top)
        _colorName = State(initialValue: garment?.colorName ?? "")
        if let cents = garment?.priceCents {
            _priceText = State(initialValue: PriceInput.decimalString(cents: cents))
        } else {
            _priceText = State(initialValue: "")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photoCard
                photoButtons
                if incoming != nil {
                    choicePicker
                }
                if let status {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                fields
                Button(saveTitle) { save() }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(isCuttingOut)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(garment == nil ? "Add garment" : "Edit garment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                beginCutout(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    beginCutout(image)
                } else {
                    status = "Couldn't read that photo."
                }
            }
        }
    }

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var saveTitle: String {
        guard let incoming else { return garment == nil ? "Save garment" : "Save changes" }
        switch incoming.choice {
        case .cutout: return "Save cutout"
        case .crop: return "Save crop"
        case .photo: return "Save photo"
        }
    }

    private var photoCard: some View {
        ZStack {
            if incoming?.choice == .crop, let image = previewImage {
                CropCanvas(image: image, crop: cropBinding)
            } else if let image = previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(CutoutBackdrop())
            } else {
                ContentUnavailableView {
                    Label("Photograph it", systemImage: "camera")
                } description: {
                    Text("Camera or photo library. You can name it and save even if the cutout needs a crop.")
                }
            }
            if isCuttingOut {
                ProgressView("Removing background")
                    .padding(12)
                    .background(.regularMaterial, in: .rect(cornerRadius: 12))
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var previewImage: UIImage? {
        if let incoming {
            let data: Data? = switch incoming.choice {
            case .cutout: incoming.cutoutPNG ?? incoming.originalPNG
            case .photo, .crop: incoming.originalPNG
            }
            return data.flatMap(UIImage.init(data:))
        }
        if let filename = garment?.photoFilename ?? garment?.thumbnailFilename, let data = PhotoStore.load(filename) {
            return UIImage(data: data)
        }
        return nil
    }

    private var cropBinding: Binding<CGRect> {
        Binding(
            get: { incoming?.crop ?? CGRect(x: 0, y: 0, width: 1, height: 1) },
            set: { incoming?.crop = $0 }
        )
    }

    private var photoButtons: some View {
        HStack(spacing: 10) {
            if cameraAvailable {
                Button {
                    showCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Library", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var choicePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Photo", selection: choiceBinding) {
                if incoming?.cutoutPNG != nil {
                    Text("Cutout").tag(PhotoChoice.cutout)
                }
                Text("Photo").tag(PhotoChoice.photo)
                Text("Crop").tag(PhotoChoice.crop)
            }
            .pickerStyle(.segmented)
            Text(incoming?.failedCutout == true
                 ? "Couldn't cut this one out. Crop the photo, or save it as-is."
                 : "Check the cutout, then save. The photo stays on this device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var choiceBinding: Binding<PhotoChoice> {
        Binding(
            get: { incoming?.choice ?? .photo },
            set: { incoming?.choice = $0 }
        )
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)
            Picker("Category", selection: $category) {
                ForEach(GarmentCategory.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            TextField("Color", text: $colorName)
                .textFieldStyle(.roundedBorder)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GarmentColor.allCases) { color in
                        Button(color.title) {
                            colorName = color.title
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            colorName.caseInsensitiveCompare(color.title) == .orderedSame
                                ? Color.accentColor.opacity(0.18)
                                : Color.primary.opacity(0.06),
                            in: .capsule
                        )
                        .buttonStyle(.plain)
                    }
                }
            }
            TextField("Price (optional)", text: $priceText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
        }
    }

    private func beginCutout(_ image: UIImage) {
        cutoutToken += 1
        let token = cutoutToken
        guard let png = PhotoPrep.flattenedPNG(from: image) else {
            status = "Couldn't read that photo."
            return
        }
        incoming = IncomingPhoto(
            originalPNG: png,
            cutoutPNG: nil,
            failedCutout: false,
            choice: .photo,
            crop: CGRect(x: 0, y: 0, width: 1, height: 1)
        )
        isCuttingOut = true
        status = nil
        Task {
            let cutout = await Task.detached(priority: .userInitiated) {
                GarmentCutout.removeBackground(from: png)
            }.value
            guard token == cutoutToken else { return }
            isCuttingOut = false
            if let cutout {
                incoming?.cutoutPNG = cutout
                incoming?.failedCutout = false
                incoming?.choice = .cutout
            } else {
                incoming?.failedCutout = true
                incoming?.choice = .photo
            }
        }
    }

    private func save() {
        let trimmedPrice = priceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cents: Int?
        if trimmedPrice.isEmpty {
            cents = nil
        } else if let parsed = PriceInput.cents(from: trimmedPrice) {
            cents = parsed
        } else {
            status = "Enter a price like 79.99, or leave it blank."
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedName.isEmpty ? category.title : trimmedName
        let color = colorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let actions = ClosetActions(context: modelContext)

        if let garment {
            garment.name = resolvedName
            garment.category = category
            garment.colorName = color
            garment.priceCents = cents
            if let incoming {
                do {
                    let stored = try storedPhoto(from: incoming)
                    PhotoStore.delete(garment.photoFilename)
                    PhotoStore.delete(garment.thumbnailFilename)
                    garment.photoFilename = stored.photo.filename
                    garment.thumbnailFilename = stored.photo.thumbnailFilename
                    garment.didUseCutout = stored.usedCutout
                } catch {
                    status = "Couldn't save that photo."
                    return
                }
            }
            actions.saveEdits()
            dismiss()
            return
        }

        guard actions.canAdd(isPro: entitlements.isPro) else {
            router.showPaywall = true
            return
        }

        var photo: StoredPhoto?
        var usedCutout = false
        if let incoming {
            do {
                let stored = try storedPhoto(from: incoming)
                photo = stored.photo
                usedCutout = stored.usedCutout
            } catch {
                status = "Couldn't save that photo."
                return
            }
        }

        do {
            try actions.addGarment(
                name: resolvedName,
                category: category,
                colorName: color,
                priceCents: cents,
                photoFilename: photo?.filename,
                thumbnailFilename: photo?.thumbnailFilename,
                didUseCutout: usedCutout,
                isPro: entitlements.isPro
            )
            dismiss()
        } catch ClosetError.freeLimitReached {
            if let photo {
                PhotoStore.delete(photo.filename)
                PhotoStore.delete(photo.thumbnailFilename)
            }
            router.showPaywall = true
        } catch {
            status = "Couldn't save this garment."
        }
    }

    private func storedPhoto(from incoming: IncomingPhoto) throws -> (photo: StoredPhoto, usedCutout: Bool) {
        let data: Data
        let usedCutout: Bool
        switch incoming.choice {
        case .cutout:
            guard let cutout = incoming.cutoutPNG else {
                data = incoming.originalPNG
                usedCutout = false
                break
            }
            data = cutout
            usedCutout = true
        case .photo:
            data = incoming.originalPNG
            usedCutout = false
        case .crop:
            data = ImageCropper.cropPNG(incoming.originalPNG, normalizedTopLeft: incoming.crop) ?? incoming.originalPNG
            usedCutout = false
        }
        return (try PhotoStore.save(data), usedCutout)
    }
}

private struct IncomingPhoto {
    var originalPNG: Data
    var cutoutPNG: Data?
    var failedCutout: Bool
    var choice: PhotoChoice
    var crop: CGRect
}

private enum PhotoChoice: Hashable {
    case cutout
    case photo
    case crop
}
