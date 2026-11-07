import SwiftUI
import UIKit
import WidgetKit
import WoreCore

@main
struct WoreWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayOutfitWidget()
    }
}

struct TodayOutfitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayOutfit", provider: OutfitProvider()) { entry in
            TodayOutfitWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's outfit")
        .description("The pieces you logged today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WidgetPiece: Identifiable, Sendable {
    let id: UUID
    let name: String
    let thumbnailPNG: Data?
}

struct OutfitEntry: TimelineEntry, Sendable {
    let date: Date
    let isPro: Bool
    let pieces: [WidgetPiece]
}

struct OutfitProvider: TimelineProvider {
    func placeholder(in context: Context) -> OutfitEntry {
        OutfitEntry(
            date: .now,
            isPro: true,
            pieces: [
                WidgetPiece(id: UUID(), name: "Camel coat", thumbnailPNG: nil),
                WidgetPiece(id: UUID(), name: "White tee", thumbnailPNG: nil),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (OutfitEntry) -> Void) {
        if context.isPreview, !UserDefaults.wore.bool(forKey: SettingsKey.isProCached) {
            completion(placeholder(in: context))
        } else {
            completion(load())
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<OutfitEntry>) -> Void) {
        let entry = load()
        let nextMidnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(3_600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func load() -> OutfitEntry {
        let isPro = UserDefaults.wore.bool(forKey: SettingsKey.isProCached)
        guard isPro, let snapshot = WidgetSnapshotStore.read(), snapshot.dayKey == DayKey.key(for: .now) else {
            return OutfitEntry(date: .now, isPro: isPro, pieces: [])
        }
        let pieces = snapshot.pieces.map { piece in
            WidgetPiece(
                id: piece.id,
                name: piece.name,
                thumbnailPNG: PhotoStore.load(piece.thumbnailFilename)
            )
        }
        return OutfitEntry(date: .now, isPro: true, pieces: pieces)
    }
}

struct TodayOutfitWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: OutfitEntry

    var body: some View {
        if !entry.isPro {
            locked
                .widgetURL(WoreConfig.paywallURL)
        } else if entry.pieces.isEmpty {
            empty
                .widgetURL(WoreConfig.todayURL)
        } else {
            outfit
                .widgetURL(WoreConfig.todayURL)
        }
    }

    private var locked: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "tshirt")
                .font(.title2)
            Text("Today's outfit")
                .font(.headline)
            Text("Wore Pro")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.headline)
            Text("Nothing logged yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var outfit: some View {
        Group {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 4) {
                    thumbnail(entry.pieces.first)
                    Text(entry.pieces.first?.name ?? "Today")
                        .font(.headline)
                        .lineLimit(2)
                    if entry.pieces.count > 1 {
                        Text("+\(entry.pieces.count - 1) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .top, spacing: 10) {
                    thumbnail(entry.pieces.first)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(entry.pieces.prefix(family == .systemLarge ? 8 : 4)) { piece in
                            Text(piece.name)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ piece: WidgetPiece?) -> some View {
        if let data = piece?.thumbnailPNG, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: family == .systemSmall ? 44 : 72, height: family == .systemSmall ? 44 : 72)
        } else {
            Image(systemName: "tshirt")
                .frame(width: 44, height: 44)
                .foregroundStyle(.secondary)
        }
    }
}
