import SwiftUI

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {

    @AppStorage("appearanceMode")
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    @AppStorage("lastSeenDataUpdatedAtISO")
    private var lastSeenISO: String = ""

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            Form {

                Section("Appearance") {
                    Picker("Theme", selection: $appearanceModeRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Data") {
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(lastUpdatedLabel)
                            .foregroundStyle(.secondary)
                    }

                    Text("Updates after completed competitive play. The app refreshes once per day (like GHIN).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    Text("Index simulates how elite golfers’ handicaps could look based on completed competitive rounds.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private var lastUpdatedLabel: String {
        guard
            let date = ISO8601DateFormatter().date(from: lastSeenISO)
        else {
            return "—"
        }

        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

#Preview {
    SettingsView()
}

