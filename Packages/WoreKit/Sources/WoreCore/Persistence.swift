import Foundation
import SwiftData

public enum PersistenceController {
    public static let schema = Schema([Garment.self, OutfitDay.self, TripList.self])

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
