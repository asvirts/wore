import Foundation
import Observation
import WoreCore

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
    var showAdd = false
    var triggerSeed = false

    func handle(_ url: URL) {
        guard url.scheme == WoreConfig.urlScheme else { return }
        switch url.host {
        case "today":
            tab = .today
            showPaywall = false
            showAdd = false
        case "trips":
            tab = .trips
            showPaywall = false
            showAdd = false
        case "paywall":
            showPaywall = true
            showAdd = false
        case "add":
            tab = .closet
            showAdd = true
            showPaywall = false
        case "seed":
            triggerSeed = true
        default:
            tab = .closet
            showPaywall = false
            showAdd = false
        }
    }
}
