import SwiftUI
import Foundation
import Combine
import Charts

// MARK: - ViewModel

@MainActor
final class PlayerRoundsViewModel: ObservableObject {
    @Published var rounds: [Round] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var fullHistoryLoaded: Bool = false

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func loadRounds(from player: RemotePlayer) {
        // Use embedded recent rounds (last 20) for fast initial display
        rounds = player.recentRounds ?? []
        fullHistoryLoaded = false

        if rounds.isEmpty {
            errorMessage = nil  // Not an error, just no rounds
        }
    }

    func loadFullHistory(for slug: String) async {
        guard !fullHistoryLoaded else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let url = URL(string: "https://jcb79107.github.io/index-data/rounds/\(slug).json")!

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                errorMessage = "Failed to load full history"
                return
            }

            let payload = try decoder.decode(RemoteRoundsPayloadV1.self, from: data)
            rounds = payload.rounds.sorted(by: { $0.date > $1.date })
            fullHistoryLoaded = true

        } catch {
            errorMessage = "Failed to load full history: \(error.localizedDescription)"
        }
    }
}

// MARK: - Remote payload for individual round files

struct RemoteRoundsPayloadV1: Codable {
    let version: Int
    let updatedAt: Date
    let slug: String
    let roundCount: Int
    let rounds: [Round]
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
    @State private var selectedDate: Date?
    @State private var selectedRoundIndex: Int?
    @State private var isRefreshing = false

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
        .onAppear {
            vm.loadRounds(from: player)
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
                    .padding(.vertical, 40)
            } else if rangeMode == .career {
                // Career mode: Scrollable horizontal chart
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Handicap Index")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 50)
                        Spacer()
                    }

                    ScrollView(.horizontal, showsIndicators: true) {
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

                        if let selected = selectedDate {
                            RuleMark(x: .value("Selected", selected))
                                .foregroundStyle(.gray.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        }
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
                        AxisMarks(values: .stride(by: .month, count: 3)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.secondary.opacity(0.3))
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    VStack(alignment: .center, spacing: 1) {
                                        Text(date, format: .dateTime.month(.abbreviated))
                                            .font(.system(size: 10, weight: .medium))
                                        Text(date, format: .dateTime.year(.twoDigits))
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .chartAngleSelection(value: $selectedDate)
                    .chartYScale(domain: .automatic(includesZero: false, reversed: true))
                    .frame(width: max(CGFloat(chartPoints.count) * 30, 400), height: 240)
                    }

                    Text("Date")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }

                if let selected = selectedDate,
                   let point = chartPoints.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selected) }) {
                    HStack {
                        Text(point.date, format: .dateTime.month().day().year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Index: \(formatChartIndex(point.index))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            } else {
                // Recent mode: Last 20 rounds
                VStack(alignment: .leading, spacing: 4) {
                    Text("Handicap Index")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 50)

                    Chart(chartPoints) {
                    LineMark(
                        x: .value("Round", $0.roundIndex),
                        y: .value("Index", $0.index)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Round", $0.roundIndex),
                        y: .value("Index", $0.index)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbol(.circle)
                    .symbolSize(60)

                    if let selected = selectedRoundIndex {
                        RuleMark(x: .value("Selected", selected))
                            .foregroundStyle(.gray.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    }
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
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.3))
                        AxisValueLabel {
                            if let idx = value.as(Int.self) {
                                Text("\(idx)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                    .chartAngleSelection(value: $selectedRoundIndex)
                    .chartYScale(domain: .automatic(includesZero: false, reversed: true))
                    .frame(height: 240)

                    Text("Round Number (Most Recent 20)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }

                if let selected = selectedRoundIndex,
                   let point = chartPoints.first(where: { $0.roundIndex == selected }) {
                    HStack {
                        Text("Round \(point.roundIndex)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(point.date, format: .dateTime.month().day().year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Index: \(formatChartIndex(point.index))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
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
                        RoundsListView(
                            title: player.name,
                            slug: player.slug,
                            initialRounds: vm.rounds,
                            viewModel: vm,
                            player: player
                        )
                    }
                }
            }

            if vm.isLoading && vm.rounds.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else if vm.rounds.isEmpty {
                Text("No rounds found")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
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
        if rangeMode == .recent {
            // Recent mode: Show last 20 rounds with round index
            let last20 = Array(vm.rounds.prefix(20))
            return last20.enumerated().map { idx, round in
                // Calculate hypothetical index for each round
                // (In reality, we'd need to recalculate index at each point)
                // For now, use index history if available, otherwise interpolate
                let roundDate = round.date

                // Try to find closest index history point
                if let history = player.indexHistory {
                    let closest = history.min(by: { abs($0.date.timeIntervalSince(roundDate)) < abs($1.date.timeIntervalSince(roundDate)) })
                    return IndexPointLite(
                        date: roundDate,
                        index: closest?.index ?? player.currentIndex ?? 0,
                        roundIndex: idx + 1
                    )
                }

                return IndexPointLite(
                    date: roundDate,
                    index: player.currentIndex ?? 0,
                    roundIndex: idx + 1
                )
            }
        } else {
            // Career mode: Show all index history
            guard let history = player.indexHistory else { return [] }
            let sorted = history.sorted { $0.date < $1.date }

            return sorted.enumerated().map { idx, point in
                IndexPointLite(date: point.date, index: point.index, roundIndex: idx + 1)
            }
        }
    }

    private func roundRow(_ r: Round) -> some View {
        NavigationLink {
            RoundDetailView(round: r, playerName: player.name, player: player)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(r.tournament)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        // Position badge for notable finishes
                        if let position = r.position, shouldShowPositionBadge(position) {
                            positionBadge(position)
                        }
                    }

                    Text("\(r.course) • R\(r.roundNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

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
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func shouldShowPositionBadge(_ position: String) -> Bool {
        // Only show badge for top 10 finishes or winner
        if position == "CUT" || position == "MC" || position == "WD" {
            return false
        }
        let numStr = position.replacingOccurrences(of: "T", with: "")
        guard let num = Int(numStr) else { return false }
        return num <= 10
    }

    private func positionBadge(_ position: String) -> some View {
        let numStr = position.replacingOccurrences(of: "T", with: "")
        let displayText = position.hasPrefix("T") ? "T\(numStr)" : numStr

        return Text(displayText)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(positionBadgeColor(position))
            }
    }

    private func positionBadgeColor(_ position: String) -> Color {
        let numStr = position.replacingOccurrences(of: "T", with: "")
        guard let num = Int(numStr) else { return .gray }

        switch num {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .orange
        case 4...10:
            return .blue
        default:
            return .secondary
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
    let roundIndex: Int
}
// MARK: - Rounds List View

struct RoundsListView: View {
    let title: String
    let slug: String
    let initialRounds: [Round]
    @ObservedObject var viewModel: PlayerRoundsViewModel
    let player: RemotePlayer?  // For career stats

    private var grouped: [(key: String, value: [Round])] {
        let f = DateFormatter()
        f.dateFormat = "yyyy"

        let dict = Dictionary(grouping: viewModel.rounds) { r in
            f.string(from: r.date)
        }

        // Sort years descending
        return dict
            .map { ($0.key, $0.value.sorted(by: { $0.date > $1.date })) }
            .sorted(by: { $0.key > $1.key })
    }

    var body: some View {
        List {
            if viewModel.isLoading && !viewModel.fullHistoryLoaded {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading full history...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }

            ForEach(grouped, id: \.key) { year, items in
                Section(year) {
                    ForEach(items) { r in
                        RoundRowDetail(round: r, playerName: title, player: player)
                    }
                }
            }

            if viewModel.fullHistoryLoaded {
                Section {
                    Text("Showing all \(viewModel.rounds.count) rounds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Rounds")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.fullHistoryLoaded {
                await viewModel.loadFullHistory(for: slug)
            }
        }
    }
}

private struct RoundRowDetail: View {
    let round: Round
    let playerName: String
    let player: RemotePlayer?

    var body: some View {
        NavigationLink {
            RoundDetailView(round: round, playerName: playerName, player: player)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(round.tournament)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(round.course) • R\(round.roundNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(dateString(round.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(round.score)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
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

