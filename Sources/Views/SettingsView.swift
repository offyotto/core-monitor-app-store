import SwiftUI

enum AppLinks {
    static let privacyPolicy = URL(string: "https://offyotto.github.io/Core-Monitor/Mac-App-Store/privacy/")!
    static let support = URL(string: "https://offyotto.github.io/Core-Monitor/Mac-App-Store/support/")!
}

struct SettingsView: View {
    @AppStorage(SettingsKey.sampleInterval) private var sampleInterval = 2.0
    @AppStorage(SettingsKey.weatherEnabled) private var weatherEnabled = false
    @AppStorage(SettingsKey.menuBarShowsCPU) private var showsCPU = true
    @AppStorage(SettingsKey.menuBarShowsMemory) private var showsMemory = true
    @AppStorage(SettingsKey.menuBarShowsNetwork) private var showsNetwork = false

    var body: some View {
        Form {
            Section {
                Picker("Update every", selection: $sampleInterval) {
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                    Text("5 seconds").tag(5.0)
                }
            } footer: {
                Text("Longer intervals use less energy.")
            }

            Section("Menu Bar") {
                Toggle("CPU usage", isOn: $showsCPU)
                Toggle("Memory usage", isOn: $showsMemory)
                Toggle("Network speed", isOn: $showsNetwork)
            }

            Section {
                Toggle("Show local weather", isOn: $weatherEnabled)
            } header: {
                Text("Weather")
            } footer: {
                Text("Uses your location to request a forecast from Apple Weather. Core-Monitor does not store your location or send it anywhere else.")
            }

            Section {
                LabeledContent("Version", value: Self.versionString)
                Link("Privacy Policy", destination: AppLinks.privacyPolicy)
                Link("Support", destination: AppLinks.support)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
