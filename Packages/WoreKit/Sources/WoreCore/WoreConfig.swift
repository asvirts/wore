import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

public enum WoreConfig {
    public static let displayName = "Wore"
    public static let appStoreTitle = "Wore: Closet & Cost per Wear"
    public static let subtitle = "Your clothes. Pay once."
    public static let bundleID = "com.asvirts.wore"
    public static let appGroupID = "group.com.asvirts.wore"
    public static let proProductID = "com.asvirts.wore.pro"
    public static let proPriceFallback = "$7.99"
    public static let urlScheme = "wore"
    public static let todayURL = URL(string: "wore://today")!
    public static let paywallURL = URL(string: "wore://paywall")!
    public static let closetURL = URL(string: "wore://closet")!
    public static let tripsURL = URL(string: "wore://trips")!
    public static let privacyPolicyURL = URL(string: "https://asvirts.github.io/wore/privacy.html")!
    public static let supportURL = URL(string: "https://asvirts.github.io/wore/support.html")!
    public static let termsURL = URL(string: "https://asvirts.github.io/wore/terms.html")!
    public static let marketingURL = URL(string: "https://asvirts.github.io/wore/")!
    public static let supportMailtoURL = URL(string: "mailto:asvirts@outlook.com?subject=Wore%20Support")!
}

public enum SettingsKey {
    public static let isProCached = "isProCached"
}

public extension UserDefaults {
    /// App Group defaults so the widget can read the Pro flag. Falls back to `.standard` when the group isn't provisioned.
    /// UserDefaults is documented as thread-safe.
    nonisolated(unsafe) static let wore: UserDefaults = UserDefaults(suiteName: WoreConfig.appGroupID) ?? .standard
}

public enum WidgetSync {
    public static func reloadAll() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

public enum DayKey {
    /// Calendar day as `yyyy-MM-dd`. Outfit logs and the widget both use this so a wear counts once per day.
    public static func key(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
