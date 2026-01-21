import SwiftUI

struct SimulationView: View {
    let preselectedCourse: Course
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SimulationViewModel

    init(preselectedCourse: Course) {
        self.preselectedCourse = preselectedCourse
        _viewModel = StateObject(wrappedValue: SimulationViewModel(course: preselectedCourse))
    }

    var body: some View {
        NavigationStack {
            Form {
                courseSection
                playerSection
                calculateSection
                resultsSection
            }
            .navigationTitle("Simulate Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var courseSection: some View {
        Section("Course") {
            VStack(alignment: .leading, spacing: 8) {
                Text(preselectedCourse.name)
                    .font(.headline)

                if let rating = preselectedCourse.courseRating,
                   let slope = preselectedCourse.slope,
                   let par = preselectedCourse.par {
                    courseStatsView(rating: rating, slope: slope, par: par)
                }
            }
        }
    }

    private func courseStatsView(rating: Double, slope: Int, par: Int) -> some View {
        HStack {
            Text("Rating: \(String(format: "%.1f", rating))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("•")
                .foregroundStyle(.secondary)
            Text("Slope: \(slope)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("•")
                .foregroundStyle(.secondary)
            Text("Par: \(par)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var playerSection: some View {
        Section("Player") {
            TextField("Search player", text: $viewModel.playerSearchText)
                .textInputAutocapitalization(.words)

            if !viewModel.filteredPlayers.isEmpty && !viewModel.playerSearchText.isEmpty {
                ForEach(viewModel.filteredPlayers.prefix(5)) { player in
                    playerRow(player)
                }
            }
        }
    }

    private func playerRow(_ player: RemotePlayer) -> some View {
        Button(action: { viewModel.selectPlayer(player) }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(player.name)
                        .foregroundStyle(.primary)
                    if let index = player.currentIndex {
                        Text("Index: \(formatIndex(index))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if viewModel.selectedPlayer?.id == player.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    @ViewBuilder
    private var calculateSection: some View {
        if viewModel.selectedPlayer != nil {
            Section {
                Button(action: viewModel.calculate) {
                    HStack {
                        Spacer()
                        Text("Calculate Expected Score")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if let result = viewModel.result {
            Section("Expected Score") {
                resultContent(result)
            }
        }
    }

    private func resultContent(_ result: SimulationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(format: "%.1f", result.expectedScore))
                    .font(.system(size: 48, weight: .bold))
                Text("≈ \(Int(result.expectedScore.rounded()))")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }

            Text(result.comparisonToPar)
                .font(.headline)
                .foregroundStyle(.secondary)

            Divider()

            formulaBreakdown(result.formulaSteps)
        }
        .padding(.vertical, 4)
    }

    private func formulaBreakdown(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Formula Breakdown")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(steps, id: \.self) { step in
                Text(step)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatIndex(_ value: Double) -> String {
        // In golf: negative index = better than scratch = display as +6.4
        let formatted = String(format: "%.1f", abs(value))
        if value < 0 { return "+\(formatted)" }
        if value > 0 { return formatted }
        return "0.0"
    }
}

// MARK: - View Model

@MainActor
final class SimulationViewModel: ObservableObject {
    @Published var playerSearchText: String = ""
    @Published var selectedPlayer: RemotePlayer?
    @Published var filteredPlayers: [RemotePlayer] = []
    @Published var result: SimulationResult?

    private let course: Course
    private let allPlayers: [RemotePlayer]
    private var cancellables = Set<AnyCancellable>()

    init(course: Course) {
        self.course = course
        self.allPlayers = RemotePlayersStore.shared.players()
        setupDebouncing()
    }

    private func setupDebouncing() {
        $playerSearchText
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.filterPlayers(searchText)
            }
            .store(in: &cancellables)
    }

    private func filterPlayers(_ searchText: String) {
        guard !searchText.isEmpty else {
            filteredPlayers = []
            return
        }

        let lowercased = searchText.lowercased()
        filteredPlayers = allPlayers
            .filter { $0.name.lowercased().contains(lowercased) }
            .filter { $0.currentIndex != nil }
            .sorted { $0.name < $1.name }
    }

    func selectPlayer(_ player: RemotePlayer) {
        selectedPlayer = player
        playerSearchText = player.name
        filteredPlayers = []
        result = nil
    }

    func calculate() {
        guard let player = selectedPlayer,
              let index = player.currentIndex,
              let rating = course.courseRating,
              let slope = course.slope,
              let par = course.par else {
            return
        }

        // WHS Formula: Expected Score = CR + (Index × Slope / 113)
        let adjustment = index * Double(slope) / 113.0
        let expectedScore = rating + adjustment

        let comparisonToPar: String
        let diff = expectedScore - Double(par)
        if diff < 0 {
            comparisonToPar = String(format: "%.1f under par", abs(diff))
        } else if diff > 0 {
            comparisonToPar = String(format: "%.1f over par", diff)
        } else {
            comparisonToPar = "Even par"
        }

        let formulaSteps = [
            "Course Rating: \(String(format: "%.1f", rating))",
            "Player Index: \(formatIndex(index))",
            "Slope: \(slope)",
            "Adjustment: \(String(format: "%.1f", index)) × (\(slope) / 113) = \(String(format: "%.1f", adjustment))",
            "Expected: \(String(format: "%.1f", rating)) + \(String(format: "%.1f", adjustment)) = \(String(format: "%.1f", expectedScore))"
        ]

        result = SimulationResult(
            expectedScore: expectedScore,
            comparisonToPar: comparisonToPar,
            formulaSteps: formulaSteps
        )
    }

    private func formatIndex(_ value: Double) -> String {
        // In golf: negative index = better than scratch = display as +6.4
        let formatted = String(format: "%.1f", abs(value))
        if value < 0 { return "+\(formatted)" }
        if value > 0 { return formatted }
        return "0.0"
    }
}

struct SimulationResult {
    let expectedScore: Double
    let comparisonToPar: String
    let formulaSteps: [String]
}

import Combine

#Preview {
    SimulationView(preselectedCourse: Course(
        slug: "augusta-national",
        name: "Augusta National Golf Club",
        fullName: "Augusta National Golf Club - Augusta, GA",
        city: "Augusta",
        state: "GA",
        country: "USA",
        hasUSGARating: true,
        courseRating: 78.1,
        slope: 137,
        par: 72,
        yardage: 7545,
        tournamentCount: 85,
        roundCount: 7241,
        firstPlayed: nil,
        lastPlayed: nil,
        recentTournaments: nil,
        versionHistory: nil
    ))
}
