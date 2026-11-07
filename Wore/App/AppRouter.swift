import Foundation
import Observation

enum AppTab: Hashable {
    case closet
    case today
    case trips
}

@MainActor
@Observable
final class AppRouter {
    var tab: AppTab = .closet
    var showPaywall = false

    func handle(_ url: URL) {
        switch url.host {
        case "today":
            tab = .today
        case "trips":
            tab = .trips
        case "paywall":
            showPaywall = true
        default:
            tab = .closet
        }
    }
}
