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

    @State private var showingClearCacheAlert = false
    @State private var cacheInfo = CacheInfo()

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

                    Text("Updates after completed competitive play. Pull down to refresh data manually.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Players Cache")
                                .font(.subheadline)
                            Text("\(cacheInfo.playersCacheSizeMB) MB")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let date = cacheInfo.playersLastUpdated {
                            Text(relativeDateString(date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rounds Cache")
                                .font(.subheadline)
                            Text("\(cacheInfo.roundsCacheSizeMB) MB • \(cacheInfo.roundsCacheCount) files")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let date = cacheInfo.roundsLastUpdated {
                            Text(relativeDateString(date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        showingClearCacheAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Caches")
                        }
                    }
                } header: {
                    Text("Cache")
                } footer: {
                    Text("Clearing cache will force fresh downloads on next use.")
                        .font(.footnote)
                }

                Section("About") {
                    Text("Index simulates how elite golfers’ handicaps could look based on completed competitive rounds.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .task {
            loadCacheInfo()
        }
        .alert("Clear All Caches?", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllCaches()
            }
        } message: {
            Text("This will delete all cached player and round data. Fresh data will be downloaded when needed.")
        }
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

    private func loadCacheInfo() {
        let fileManager = FileManager.default
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }

        // Players cache
        let playersCache = cacheDir.appendingPathComponent("remote_players_cache.json")
        if let attrs = try? fileManager.attributesOfItem(atPath: playersCache.path) {
            let size = attrs[.size] as? Int64 ?? 0
            cacheInfo.playersCacheSizeMB = String(format: "%.1f", Double(size) / 1_000_000)
            cacheInfo.playersLastUpdated = attrs[.modificationDate] as? Date
        }

        // Rounds caches
        let roundsFiles = (try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]))?.filter { $0.lastPathComponent.hasPrefix("rounds_") && $0.pathExtension == "json" } ?? []

        cacheInfo.roundsCacheCount = roundsFiles.count
        let totalSize = roundsFiles.compactMap { url -> Int64? in
            guard let attrs = try? fileManager.attributesOfItem(atPath: url.path) else { return nil }
            return attrs[.size] as? Int64
        }.reduce(0, +)
        cacheInfo.roundsCacheSizeMB = String(format: "%.1f", Double(totalSize) / 1_000_000)

        if let mostRecent = roundsFiles.compactMap({ url -> Date? in
            guard let attrs = try? fileManager.attributesOfItem(atPath: url.path) else { return nil }
            return attrs[.modificationDate] as? Date
        }).max() {
            cacheInfo.roundsLastUpdated = mostRecent
        }
    }

    private func clearAllCaches() {
        let fileManager = FileManager.default
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }

        // Clear players cache
        let playersCache = cacheDir.appendingPathComponent("remote_players_cache.json")
        try? fileManager.removeItem(at: playersCache)

        // Clear all rounds caches
        let roundsFiles = (try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil))?.filter { $0.lastPathComponent.hasPrefix("rounds_") && $0.pathExtension == "json" } ?? []
        roundsFiles.forEach { try? fileManager.removeItem(at: $0) }

        // Clear UserDefaults refresh tracking
        let defaults = UserDefaults.standard
        defaults.dictionaryRepresentation().keys.forEach { key in
            if key.hasPrefix("lastRefreshDay_") {
                defaults.removeObject(forKey: key)
            }
        }

        // Reload cache info
        loadCacheInfo()
    }

    private func relativeDateString(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Cache Info

struct CacheInfo {
    var playersCacheSizeMB: String = "0.0"
    var playersLastUpdated: Date?
    var roundsCacheSizeMB: String = "0.0"
    var roundsCacheCount: Int = 0
    var roundsLastUpdated: Date?
}

#Preview {
    SettingsView()
}

