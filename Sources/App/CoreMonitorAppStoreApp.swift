import SwiftUI

@main
struct CoreMonitorAppStoreApp: App {
    static let dashboardWindowID = "dashboard"

    @StateObject private var store = SystemSnapshotStore()
    @StateObject private var weatherStore = WeatherStore()

    var body: some Scene {
        Window("Core-Monitor", id: Self.dashboardWindowID) {
            DashboardView(store: store, weatherStore: weatherStore)
                .frame(minWidth: 760, minHeight: 520)
        }
        .defaultSize(width: 1040, height: 720)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarContentView(store: store, weatherStore: weatherStore)
        } label: {
            MenuBarLabelView(snapshot: store.snapshot)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
