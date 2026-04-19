import SwiftUI

@main
struct CoreMonitorAppStoreApp: App {
    static let dashboardWindowID = "dashboard"

    @StateObject private var store = SystemSnapshotStore()
    @StateObject private var weatherStore = WeatherStore()

    var body: some Scene {
        WindowGroup(AppStrings.localized("app.name"), id: Self.dashboardWindowID) {
            DashboardView(store: store, weatherStore: weatherStore)
                .frame(minWidth: 940, minHeight: 720)
                .task {
                    weatherStore.start()
                }
        }
        .defaultSize(width: 1120, height: 820)

        MenuBarExtra {
            MenuBarContentView(store: store, weatherStore: weatherStore)
        } label: {
            MenuBarLabelView(snapshot: store.snapshot)
        }
        .menuBarExtraStyle(.window)
    }
}
