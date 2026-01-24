import SwiftUI
import Combine

struct TournamentDetailView: View {
    let tournament: RecentTournament
    let course: Course

    @StateObject private var viewModel: TournamentDetailViewModel

    init(tournament: RecentTournament, course: Course) {
        self.tournament = tournament
        self.course = course
        _viewModel = StateObject(wrappedValue: TournamentDetailViewModel(tournament: tournament, course: course))
    }

    var body: some View {
        List {
            // Tournament Info Section - Beautiful and prominent
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(tournament.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.accentColor)
                            Text(course.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                        }

                        if !course.displayLocation.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Text(course.displayLocation)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(tournament.dates)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Winner Section - Eye-catching and prominent
            if let winnerName = viewModel.winnerName {
                Section {
                    HStack(spacing: 16) {
                        // Trophy icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "trophy.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.yellow)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("WINNER")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)

                            Text(winnerName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        if let scoreDisplay = tournament.winningScoreDisplay {
                            Text(scoreDisplay)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.accentColor)
                                .monospacedDigit()
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            // Statistics Section - Visual and clear
            Section {
                HStack(spacing: 20) {
                    if let fieldSize = tournament.fieldSize {
                        StatCard(icon: "person.3.fill", title: "Field Size", value: "\(fieldSize)")
                    }

                    if let par = course.par {
                        StatCard(icon: "flag.fill", title: "Par", value: "\(par)")
                    }

                    if let fieldAvg = tournament.fieldAverage {
                        StatCard(icon: "chart.bar.fill", title: "Field Avg", value: String(format: "%.1f", fieldAvg))
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Tournament Statistics")
            }

            // Leaderboard Section
            if let leaderboard = tournament.leaderboard, !leaderboard.isEmpty {
                Section("Leaderboard") {
                    ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                        NavigationLink {
                            TournamentPlayerRoundsView(
                                playerSlug: entry.playerSlug,
                                tournamentName: tournament.name,
                                tournamentYear: tournament.year
                            )
                        } label: {
                            leaderboardRow(position: index + 1, entry: entry)
                        }
                    }
                }
            }
        }
        .navigationTitle("Tournament")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPlayerNames()
        }
    }

    private func leaderboardRow(position: Int, entry: LeaderboardEntry) -> some View {
        HStack(spacing: 14) {
            // Position badge - Eye-catching for top 3
            ZStack {
                if position <= 3 {
                    Circle()
                        .fill(positionColor(for: position).opacity(0.15))
                        .frame(width: 36, height: 36)
                }

                Text("\(position)")
                    .font(.system(size: position <= 3 ? 16 : 15, weight: position <= 3 ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(position <= 3 ? positionColor(for: position) : .secondary)
                    .monospacedDigit()
                    .frame(width: 36, alignment: .center)
            }

            // Player avatar and name - Beautiful like other views
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(initials(from: viewModel.playerNames[entry.playerSlug] ?? entry.playerSlug))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.7))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    if let playerName = viewModel.playerNames[entry.playerSlug] {
                        Text(playerName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    } else {
                        Text(entry.playerSlug)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("\(entry.rounds) rounds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Score - THE STAR OF THE ROW
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.scoreToParDisplay)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(for: entry.scoreToPar))
                    .monospacedDigit()

                Text("\(entry.totalScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 8)
    }

    // Position colors for top 3
    private func positionColor(for position: Int) -> Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }

    // Score color based on performance
    private func scoreColor(for scoreToPar: Int?) -> Color {
        guard let score = scoreToPar else { return .primary }
        if score < -10 { return .green }
        if score < 0 { return .blue }
        if score == 0 { return .primary }
        return .orange
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first
        let last = parts.last?.first
        return [first, last].compactMap { $0 }.map { String($0) }.joined()
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.accentColor)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - View Model

@MainActor
final class TournamentDetailViewModel: ObservableObject {
    @Published var playerNames: [String: String] = [:]
    @Published var winnerName: String?

    private let tournament: RecentTournament
    private let course: Course
    private let allPlayers: [RemotePlayer]

    init(tournament: RecentTournament, course: Course) {
        self.tournament = tournament
        self.course = course
        self.allPlayers = RemotePlayersStore.shared.players()
    }

    func loadPlayerNames() async {
        // Build slug -> name mapping
        var names: [String: String] = [:]

        for player in allPlayers {
            names[player.slug] = player.name
        }

        playerNames = names

        // Get winner name
        if let winner = allPlayers.first(where: { $0.slug == tournament.winnerSlug }) {
            winnerName = winner.name
        }
    }
}

// MARK: - Tournament Player Rounds View

struct TournamentPlayerRoundsView: View {
    let playerSlug: String
    let tournamentName: String
    let tournamentYear: Int

    @StateObject private var viewModel = TournamentPlayerRoundsViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.rounds.isEmpty {
                Section {
                    Text("No rounds found for this tournament")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(viewModel.rounds) { round in
                        roundRow(round)
                    }
                }
            }
        }
        .navigationTitle(viewModel.playerName ?? "Player Rounds")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadRounds(playerSlug: playerSlug, tournamentName: tournamentName, year: tournamentYear)
        }
    }

    private func roundRow(_ round: Round) -> some View {
        HStack(spacing: 16) {
            // Round number badge
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                VStack(spacing: 2) {
                    Text("R\(round.roundNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Round info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dateString(round.date))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer()

                    // Score - THE STAR
                    Text("\(round.score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(roundScoreColor(round.score, par: round.par))
                        .monospacedDigit()
                }

                HStack(spacing: 8) {
                    // Par info
                    Text("Par \(round.par)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    // Score to par
                    Text(formatScoreToPar(round.score, par: round.par))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let diff = round.differential {
                        Text("•")
                            .foregroundStyle(.secondary)
                            .font(.caption)

                        HStack(spacing: 3) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 9))
                            Text("\(formatDifferential(diff))")
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }

    private func roundScoreColor(_ score: Int, par: Int) -> Color {
        let diff = score - par
        if diff < -3 { return .green }
        if diff < 0 { return .blue }
        if diff == 0 { return .primary }
        return .orange
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDifferential(_ value: Double) -> String {
        // USGA format: -3.5 (good, better than CR), +5.0 (bad, worse than CR)
        let formatted = String(format: "%.1f", abs(value))
        if value > 0 { return "+\(formatted)" }
        if value < 0 { return "-\(formatted)" }
        return "0.0"
    }

    private func formatScoreToPar(_ score: Int, par: Int) -> String {
        let diff = score - par
        if diff < 0 { return "\(diff)" }
        if diff > 0 { return "+\(diff)" }
        return "E"
    }
}

// MARK: - Tournament Player Rounds View Model

@MainActor
final class TournamentPlayerRoundsViewModel: ObservableObject {
    @Published var rounds: [Round] = []
    @Published var playerName: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let roundsViewModel = PlayerRoundsViewModel()

    func loadRounds(playerSlug: String, tournamentName: String, year: Int) async {
        isLoading = true
        errorMessage = nil

        // Get player data (includes embedded rounds)
        let allPlayers = RemotePlayersStore.shared.players()
        if let player = allPlayers.first(where: { $0.slug == playerSlug }) {
            playerName = player.name
            roundsViewModel.loadRounds(from: player)
        }

        // Filter to tournament rounds
        let filtered = roundsViewModel.rounds.filter { round in
            round.tournament == tournamentName &&
            Calendar.current.component(.year, from: round.date) == year
        }

        rounds = filtered.sorted { $0.date < $1.date }
        isLoading = false

        if rounds.isEmpty && roundsViewModel.rounds.isEmpty {
            errorMessage = "No rounds data available for this player"
        }
    }
}

#Preview {
    NavigationStack {
        TournamentDetailView(
            tournament: RecentTournament(
                name: "Masters Tournament",
                year: 2024,
                dates: "2024-04-11 to 2024-04-14",
                winnerSlug: "scottie-scheffler",
                winningScore: -11,
                fieldSize: 89,
                fieldAverage: 74.2,
                leaderboard: nil
            ),
            course: Course(
                slug: "augusta-national",
                name: "Augusta National Golf Club",
                fullName: "Augusta National Golf Club - Augusta, GA, USA",
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
            )
        )
    }
}
