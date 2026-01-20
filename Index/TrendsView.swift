import SwiftUI
import Charts
import Combine

struct TrendsView: View {
    enum RangeMode: String, CaseIterable, Identifiable {
        case lastYear = "Last Year"
        case last3Years = "Last 3 Years"
        case career = "Career"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .lastYear: return "calendar"
            case .last3Years: return "calendar.badge.clock"
            case .career: return "infinity"
            }
        }

        var label: String {
            switch self {
            case .lastYear: return "1 Year"
            case .last3Years: return "3 Years"
            case .career: return "Career"
            }
        }
    }

    @State private var rangeMode: RangeMode = .last3Years
    @State private var selectedSlugs: Set<String> = []
    @State private var searchText: String = ""
    @State private var debouncedSearchText: String = ""
    @State private var allPlayers: [RemotePlayer] = []

    private var maxSelectable: Int { 3 }

    private var playersWithHistory: [RemotePlayer] {
        allPlayers.filter { $0.indexHistory != nil && !($0.indexHistory?.isEmpty ?? true) }
    }

    private var filteredPlayers: [RemotePlayer] {
        if debouncedSearchText.isEmpty {
            return playersWithHistory
        }
        let lowercased = debouncedSearchText.lowercased()
        return playersWithHistory.filter { $0.name.lowercased().contains(lowercased) }
    }

    private var selectedPlayers: [RemotePlayer] {
        playersWithHistory.filter { selectedSlugs.contains($0.slug) }
    }

    private var seriesPoints: [SeriesPoint] {
        let cutoffDate: Date?
        let now = Date()

        switch rangeMode {
        case .lastYear:
            cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: now)
        case .last3Years:
            cutoffDate = Calendar.current.date(byAdding: .year, value: -3, to: now)
        case .career:
            cutoffDate = nil
        }

        return selectedPlayers.flatMap { player -> [SeriesPoint] in
            guard let history = player.indexHistory else { return [] }
            let sorted = history.sorted(by: { $0.date < $1.date })
            let filtered = cutoffDate != nil ? sorted.filter { $0.date >= cutoffDate! } : sorted
            return filtered.map { SeriesPoint(playerName: player.name, date: $0.date, index: $0.index) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Range Mode Selection - Large, clear, obvious
                        HStack(spacing: 10) {
                            ForEach(RangeMode.allCases) { mode in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        rangeMode = mode
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: 16))
                                            .foregroundStyle(rangeMode == mode ? .primary : .secondary)

                                        Text(mode.label)
                                            .font(.caption2.weight(rangeMode == mode ? .semibold : .regular))
                                            .foregroundStyle(rangeMode == mode ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(rangeMode == mode ? Color.accentColor.opacity(0.15) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(rangeMode == mode ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if selectedPlayers.isEmpty {
                            EmptyCompareState()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        } else if seriesPoints.isEmpty {
                            NoHistoryState()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        } else {
                            // Chart - THE STAR OF THE SHOW
                            Chart(seriesPoints) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Index", point.index)
                                )
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                .foregroundStyle(by: .value("Player", point.playerName))

                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Index", point.index)
                                )
                                .symbolSize(60)
                                .foregroundStyle(by: .value("Player", point.playerName))
                            }
                            .chartYScale(domain: .automatic(includesZero: false))
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let index = value.as(Double.self) {
                                            Text(formatIndex(index))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                                        .font(.caption2)
                                }
                            }
                            .chartLegend(.hidden)
                            .frame(height: 300)

                            // Legend - Beautiful and clear
                            VStack(spacing: 10) {
                                ForEach(selectedPlayers) { p in
                                    HStack(spacing: 12) {
                                        // Color indicator circle
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 10, height: 10)

                                        Text(p.name)
                                            .font(.subheadline.weight(.semibold))

                                        Spacer()

                                        if let index = p.currentIndex {
                                            Text(formatIndex(index))
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundStyle(.primary)
                                                .monospacedDigit()
                                        }

                                        if let count = p.indexHistory?.count {
                                            Text("• \(count) pts")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    if filteredPlayers.isEmpty {
                        HStack {
                            Spacer()
                            Text(searchText.isEmpty ? "No players with index history" : "No matching players")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(filteredPlayers) { player in
                            Button {
                                toggle(player)
                            } label: {
                                HStack(spacing: 14) {
                                    // Avatar - Beautiful gradient like in PlayersView
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )

                                        Text(initials(from: player.name))
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.primary.opacity(0.7))
                                    }
                                    .frame(width: 42, height: 42)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(player.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.primary)

                                        HStack(spacing: 6) {
                                            if let count = player.indexHistory?.count {
                                                HStack(spacing: 3) {
                                                    Image(systemName: "chart.xyaxis.line")
                                                        .font(.system(size: 10))
                                                    Text("\(count) points")
                                                        .font(.caption)
                                                }
                                                .foregroundStyle(.secondary)
                                            }

                                            if let index = player.currentIndex {
                                                Text("•")
                                                    .foregroundStyle(.secondary)
                                                    .font(.caption)

                                                Text(formatIndex(index))
                                                    .font(.caption.monospacedDigit().weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }

                                    Spacer()

                                    // Selection indicator - Clean and obvious
                                    if selectedSlugs.contains(player.slug) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundStyle(.tint)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.system(size: 24))
                                            .foregroundStyle(.secondary.opacity(0.3))
                                    }
                                }
                                .contentShape(Rectangle())
                                .opacity(!selectedSlugs.contains(player.slug) && selectedSlugs.count >= maxSelectable ? 0.4 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .disabled(!selectedSlugs.contains(player.slug) && selectedSlugs.count >= maxSelectable)
                        }
                    }
                } header: {
                    Text("Select Players (\(selectedSlugs.count)/\(maxSelectable))")
                } footer: {
                    Text("Tap players to compare their index trends over time. Only players with recorded index history are shown.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Trends")
            .searchable(text: $searchText, prompt: "Search players")
        }
        .task {
            allPlayers = RemotePlayersStore.shared.players()

            // Default to famous players if available
            if selectedSlugs.isEmpty {
                let famous = ["tiger-woods", "rory-mcilroy", "scottie-scheffler"]
                for slug in famous {
                    if playersWithHistory.contains(where: { $0.slug == slug }) {
                        selectedSlugs.insert(slug)
                        if selectedSlugs.count >= maxSelectable { break }
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            // Debounce search
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if searchText == newValue {
                    debouncedSearchText = newValue
                }
            }
        }
    }

    private func toggle(_ player: RemotePlayer) {
        if selectedSlugs.contains(player.slug) {
            selectedSlugs.remove(player.slug)
        } else {
            guard selectedSlugs.count < maxSelectable else { return }
            selectedSlugs.insert(player.slug)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first
        let last = parts.last?.first
        return [first, last].compactMap { $0 }.map { String($0) }.joined()
    }

    private func formatIndex(_ value: Double) -> String {
        // In golf: negative index = better than scratch = display as +6.4
        let formatted = String(format: "%.1f", abs(value))
        if value < 0 { return "+\(formatted)" }
        if value > 0 { return "\(formatted)" }
        return "0.0"
    }
}

private struct SeriesPoint: Identifiable {
    let id = UUID()
    let playerName: String
    let date: Date
    let index: Double
}

private struct EmptyCompareState: View {
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.accentColor.opacity(0.7))
            }

            Text("Select Players to Compare")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Choose up to 3 players below to view their handicap index trends over time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct NoHistoryState: View {
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.orange.opacity(0.7))
            }

            Text("No Data Available")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            Text("The selected players don't have index data for this time range. Try a different date range.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    TrendsView()
}
