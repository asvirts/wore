import Foundation

public struct StoredPhoto: Equatable, Sendable {
    public var filename: String
    public var thumbnailFilename: String

    public init(filename: String, thumbnailFilename: String) {
        self.filename = filename
        self.thumbnailFilename = thumbnailFilename
    }
}

public struct TodayOutfitSnapshot: Codable, Equatable, Sendable {
    public var dayKey: String
    public var pieces: [Piece]

    public struct Piece: Codable, Equatable, Sendable, Identifiable {
        public var id: UUID
        public var name: String
        public var thumbnailFilename: String?

        public init(id: UUID, name: String, thumbnailFilename: String?) {
            self.id = id
            self.name = name
            self.thumbnailFilename = thumbnailFilename
        }
    }

    public init(dayKey: String, pieces: [Piece]) {
        self.dayKey = dayKey
        self.pieces = pieces
    }
}

public enum WorePaths {
    /// Tests point this at a temporary directory so package tests never write into a real closet.
    nonisolated(unsafe) public static var containerOverride: URL?

    public static func containerURL() -> URL {
        if let containerOverride { return containerOverride }
        if let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WoreConfig.appGroupID) {
            return group
        }
        let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("com.asvirts.wore", isDirectory: true)
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }

    public static func photosDirectory() -> URL {
        containerURL().appendingPathComponent("photos", isDirectory: true)
    }

    public static var snapshotURL: URL {
        containerURL().appendingPathComponent("today-outfit.json")
    }
}

public enum PhotoStore {
    public static func save(_ png: Data) throws -> StoredPhoto {
        let id = UUID().uuidString
        let filename = "\(id).png"
        let thumbName = "\(id)-thumb.png"
        let directory = WorePaths.photosDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try png.write(to: directory.appendingPathComponent(filename), options: .atomic)
        let thumb = ImageFiles.thumbnailPNG(from: png, maxPixel: 320) ?? png
        try thumb.write(to: directory.appendingPathComponent(thumbName), options: .atomic)
        return StoredPhoto(filename: filename, thumbnailFilename: thumbName)
    }

    public static func load(_ filename: String?) -> Data? {
        guard let filename, !filename.isEmpty else { return nil }
        let url = WorePaths.photosDirectory().appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    public static func delete(_ filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        let url = WorePaths.photosDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}

public enum WidgetSnapshotStore {
    public static func write(_ snapshot: TodayOutfitSnapshot) {
        let directory = WorePaths.containerURL()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: WorePaths.snapshotURL, options: .atomic)
    }

    public static func read() -> TodayOutfitSnapshot? {
        guard let data = try? Data(contentsOf: WorePaths.snapshotURL) else { return nil }
        return try? JSONDecoder().decode(TodayOutfitSnapshot.self, from: data)
    }
}
