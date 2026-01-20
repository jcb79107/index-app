import SwiftUI
import Foundation
import Combine
import Charts

// MARK: - Remote payload

struct RemoteRoundsPayloadV1: Codable {
    let version: Int
    let updatedAt: Date
    let slug: String
    let roundCount: Int
    let rounds: [Round]
}

// MARK: - ViewModel

@MainActor
final class PlayerRoundsViewModel: ObservableObject {
    @Published var rounds: [Round] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var payloadUpdatedAt: Date? = nil

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let lastRefreshPrefix = "lastRefreshDay_"
    private let lastSeenDataKey = "lastSeenDataUpdatedAtISO"

    func loadRounds(for slug: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // 1) Load cached immediately
        if let cached = loadCachedPayload(for: slug) {
            applyPayload(cached)
        }

        // 2) Only refresh once per day
        guard shouldRefreshToday(for: slug) else { return }

        let url = URL(string: "https://jcb79107.github.io/index-data/rounds/\(slug).json")!

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                if rounds.isEmpty { errorMessage = "Network error loading rounds." }
                return
            }

            let payload = try decoder.decode(RemoteRoundsPayloadV1.self, from: data)

            saveCachedPayload(payload, for: slug)
            markRefreshedToday(for: slug)
            applyPayload(payload)

        } catch {
            if rounds.isEmpty { errorMessage = "Failed to load rounds." }
        }
    }

    // MARK: - Apply payload (FIXED)

    private func applyPayload(_ payload: RemoteRoundsPayloadV1) {
        payloadUpdatedAt = payload.updatedAt
        rounds = payload.rounds.sorted(by: { $0.date > $1.date })

        let iso = ISO8601DateFormatter().string(from: payload.updatedAt)

        // Only update Settings if this payload is newer
        if let existing = UserDefaults.standard.string(forKey: lastSeenDataKey),
           let existingDate = ISO8601DateFormatter().date(from: existing),
           existingDate >= payload.updatedAt {
            return
        }

        UserDefaults.standard.set(iso, forKey: lastSeenDataKey)
    }

    // MARK: - Cache

    private func cacheURL(for slug: String) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("rounds_\(slug)_cache.json")
    }

    private func loadCachedPayload(for slug: String) -> RemoteRoundsPayloadV1? {
        do {
            let data = try Data(contentsOf: cacheURL(for: slug))
            return try decoder.decode(RemoteRoundsPayloadV1.self, from: data)
        } catch {
            return nil
        }
    }

    private func saveCachedPayload(_ payload: RemoteRoundsPayloadV1, for slug: String) {
        do {
            let data = try encoder.encode(payload)
            try data.write(to: cacheURL(for: slug), options: [.atomic])
        } catch {}
    }

    // MARK: - Daily refresh

    private func refreshKey(for slug: String) -> String {
        "\(lastRefreshPrefix)\(slug)"
    }

    private func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func shouldRefreshToday(for slug: String) -> Bool {
        UserDefaults.standard.string(forKey: refreshKey(for: slug)) != todayKey()
    }

    private func markRefreshedToday(for slug: String) {
        UserDefaults.standard.set(todayKey(), forKey: refreshKey(for: slug))
    }
}

// MARK: - View

struct PlayerDetailViewRemote: View {
    let player: RemotePlayer
    @StateObject private var vm = PlayerRoundsViewModel()

    enum RangeMode: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case career = "Career"
        var id: String { rawValue }
    }

    @State private var rangeMode: RangeMode = .recent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Premium Header with Photo
                HStack(spacing: 16) {
                    // Player Photo
                    if let photoURL = player.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        } placeholder: {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(player.name)
                            .font(.title2.weight(.bold))

                        if let tour = player.tour {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(tourColor(tour))
                                    .frame(width: 8, height: 8)
                                Text(tour.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let updated = vm.payloadUpdatedAt {
                            Text("Updated \(dateTime(updated))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()
                }

                indexCard
                chartCard
                roundsCard
            }
            .padding()
        }
        .navigationTitle("Player Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadRounds(for: player.slug)
        }
    }

    // MARK: - UI Sections

    private var indexCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Handicap Index")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let index = player.currentIndex {
                Text(formatIndex(index))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
            } else {
                Text("—")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if let count = player.roundCount {
                Text("\(count) competitive rounds")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Index Over Time").font(.headline)
                Spacer()
                Picker("Range", selection: $rangeMode) {
                    ForEach(RangeMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            if chartPoints.isEmpty {
                Text(vm.isLoading ? "Loading…" : "Not enough data yet.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(chartPoints) {
                    LineMark(
                        x: .value("Date", $0.date),
                        y: .value("Index", $0.index)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", $0.date),
                        y: .value("Index", $0.index)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbol(.circle)
                    .symbolSize(60)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let index = value.as(Double.self) {
                                Text(formatChartIndex(index))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: rangeMode == .recent ? 6 : 24)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.3))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(date, format: .dateTime.month(.narrow))
                                        .font(.system(size: 9, weight: .semibold))
                                    Text(date, format: .dateTime.year(.twoDigits))
                                        .font(.system(size: 8))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false, reversed: true))
                .frame(height: 240)
            }
        }
        .padding(16)
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var roundsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Rounds").font(.headline)
                Spacer()
                if !vm.rounds.isEmpty {
                    NavigationLink("See all") {
                        RoundsListView(title: player.name, rounds: vm.rounds)
                    }
                }
            }

            if let msg = vm.errorMessage {
                Text(msg).foregroundStyle(.secondary)
            } else {
                ForEach(vm.rounds.prefix(5)) { roundRow($0) }
            }
        }
        .padding(16)
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private var chartPoints: [IndexPointLite] {
        guard let history = player.indexHistory else { return [] }

        let sorted = history.sorted { $0.date < $1.date }
        let limit = rangeMode == .recent ? 30 : sorted.count
        let trimmed = Array(sorted.suffix(limit))

        return trimmed.map {
            IndexPointLite(date: $0.date, index: $0.index)
        }
    }

    private func roundRow(_ r: Round) -> some View {
        NavigationLink {
            RoundDetailView(round: r, playerName: player.name)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.tournament)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(r.course) • R\(r.roundNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(r.score)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    if let diff = r.differential {
                        Text(formatDifferential(diff))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
        }
    }

    private func formatIndex(_ v: Double) -> String {
        // In golf: negative index = better than scratch = display as +6.4
        // positive index = worse than scratch = display as 15.2 (no sign)
        let s = String(format: "%.1f", abs(v))
        return v < 0 ? "+\(s)" : v > 0 ? "\(s)" : "0.0"
    }

    private func formatDifferential(_ v: Double) -> String {
        // USGA format: -3.5 (good, better than CR), +5.0 (bad, worse than CR)
        let s = String(format: "%.1f", abs(v))
        return v > 0 ? "+\(s)" : v < 0 ? "-\(s)" : "0.0"
    }

    private func formatChartIndex(_ index: Double) -> String {
        // Format index for chart axis - golf scoring (negative is better)
        let formatted = String(format: "%.1f", abs(index))
        return index < 0 ? "+\(formatted)" : formatted
    }

    private func tourColor(_ tour: RemotePlayer.Tour) -> Color {
        switch tour {
        case .pga: return .blue
        case .dpWorld: return .orange
        case .liv: return .green
        }
    }

    private func dateTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}

// MARK: - Chart Model

private struct IndexPointLite: Identifiable {
    let id = UUID()
    let date: Date
    let index: Double
}
// MARK: - Rounds List View

struct RoundsListView: View {
    let title: String
    let rounds: [Round]
    
    private var grouped: [(key: String, value: [Round])] {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        
        let dict = Dictionary(grouping: rounds) { r in
            f.string(from: r.date)
        }
        
        // Sort years descending
        return dict
            .map { ($0.key, $0.value.sorted(by: { $0.date > $1.date })) }
            .sorted(by: { $0.key > $1.key })
    }
    
    var body: some View {
        List {
            ForEach(grouped, id: \.key) { year, items in
                Section(year) {
                    ForEach(items) { r in
                        RoundRowDetail(round: r)
                    }
                }
            }
        }
        .navigationTitle("Rounds")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RoundRowDetail: View {
    let round: Round

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(round.tournament)
                    .font(.subheadline.weight(.semibold))
                Text("\(round.course) • R\(round.roundNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dateString(round.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(round.score)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                HStack(spacing: 4) {
                    Text("Par \(round.par)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let diff = round.differential {
                        Text("• Diff " + formatDiff(diff))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDiff(_ v: Double) -> String {
        // USGA format: -3.5 (good, better than CR), +5.0 (bad, worse than CR)
        let s = String(format: "%.1f", abs(v))
        return v > 0 ? "+\(s)" : v < 0 ? "-\(s)" : "0.0"
    }
    
    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

