import SwiftUI

struct RoundDetailView: View {
    let round: Round
    let playerName: String
    let player: RemotePlayer?  // Optional - for career stats

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Header Card
                heroCard

                // Player Career Stats (if available)
                if let player = player {
                    playerStatsCard(player)
                }

                // Tournament Result Card (only if position/earnings available)
                if hasTournamentContext {
                    tournamentResultCard
                }

                // Score Breakdown
                scoreBreakdownCard

                // Course Details
                courseDetailsCard

                // Stats Grid
                statsGrid
            }
            .padding()
        }
        .navigationTitle("Round Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Player Career Stats Card

    private func playerStatsCard(_ player: RemotePlayer) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                Text("Player Stats")
                    .font(.headline)
            }

            HStack(spacing: 16) {
                // Career Earnings
                if let careerEarnings = calculateCareerEarnings(player) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Career Earnings", systemImage: "dollarsign.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .labelStyle(.iconOnly)
                            .font(.body)
                            .foregroundStyle(.green)
                        +
                        Text(" Career Earnings")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(formatEarnings(careerEarnings))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // FedEx Cup Rank (placeholder for future)
                VStack(alignment: .leading, spacing: 6) {
                    Label("FedEx Rank", systemImage: "chart.bar.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .labelStyle(.iconOnly)
                        .font(.body)
                        .foregroundStyle(.blue)
                    +
                    Text(" FedEx Rank")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("—")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 16) {
                // World Ranking (placeholder for future)
                VStack(alignment: .leading, spacing: 6) {
                    Label("World Rank", systemImage: "globe")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .labelStyle(.iconOnly)
                        .font(.body)
                        .foregroundStyle(.orange)
                    +
                    Text(" World Rank")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("—")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Handicap Index
                if let index = player.currentIndex {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Index", systemImage: "figure.golf")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .labelStyle(.iconOnly)
                            .font(.body)
                            .foregroundStyle(Color.accentColor)
                        +
                        Text(" Handicap")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(formatHandicapIndex(index))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    private func calculateCareerEarnings(_ player: RemotePlayer) -> Double? {
        guard let rounds = player.recentRounds else { return nil }
        let total = rounds.compactMap { $0.earnings }.reduce(0, +)
        return total > 0 ? total : nil
    }

    private func formatHandicapIndex(_ index: Double) -> String {
        let formatted = String(format: "%.1f", abs(index))
        return index < 0 ? "+\(formatted)" : formatted
    }

    // MARK: - Tournament Result Card

    private var hasTournamentContext: Bool {
        round.position != nil || round.earnings != nil || round.fedexPoints != nil
    }

    private var tournamentResultCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                Text("Tournament Result")
                    .font(.headline)
            }

            // Position - THE STAR OF THE SHOW
            if let position = round.position {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FINISH")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formatPosition(position))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(positionColor(position))
                            .monospacedDigit()

                        Text(positionSuffix(position))
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(positionColor(position).opacity(0.7))
                    }

                    Text(positionDescription(position))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            }

            Divider()
                .opacity(0.5)

            // Earnings & FedEx Points Grid
            HStack(spacing: 20) {
                if let earnings = round.earnings {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                            Text("Prize Money")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Text(formatEarnings(earnings))
                            .font(.title.weight(.bold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let fedexPoints = round.fedexPoints {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            Text("FedEx Cup")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(formatFedExPoints(fedexPoints))
                                .font(.title.weight(.bold))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                            Text("pts")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemGroupedBackground),
                            Color(.secondarySystemGroupedBackground).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: positionShadowColor, radius: 12, x: 0, y: 6)
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Tournament & Date
            VStack(alignment: .leading, spacing: 4) {
                Text(round.tournament)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text(formatDate(round.date))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Massive Score Display
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCORE")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(1)

                    Text("\(round.score)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor(round.score, par: round.par))
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    // To Par
                    let toPar = round.score - round.par
                    if toPar != 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TO PAR")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(1)
                            Text(formatToPar(toPar))
                                .font(.title.weight(.bold))
                                .foregroundStyle(toParColor(toPar))
                                .monospacedDigit()
                        }
                    }

                    // Differential
                    if let diff = round.differential {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("DIFFERENTIAL")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(1)
                            Text(formatDifferential(diff))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(differentialColor(diff))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Score Breakdown

    private var scoreBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                // Round Number
                HStack {
                    Image(systemName: "flag.circle.fill")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)
                    Text("Round")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(round.roundNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                // Player name
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)
                    Text("Player")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(playerName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Course Details

    private var courseDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.golf")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                Text("Course Information")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                courseInfoRow(icon: "flag.2.crossed.fill", label: "Course", value: parsedCourseName)

                if !parsedLocation.isEmpty {
                    courseInfoRow(icon: "mappin.circle.fill", label: "Location", value: parsedLocation)
                }

                courseInfoRow(icon: "circle.hexagongrid.fill", label: "Par", value: "\(round.par)")

                if let yardage = round.yardage, yardage > 0 {
                    courseInfoRow(icon: "ruler.fill", label: "Yardage", value: formatYardage(yardage))
                }

                if let courseRating = round.courseRating, courseRating > 0 {
                    courseInfoRow(icon: "star.fill", label: "Rating", value: String(format: "%.1f", courseRating))
                }

                if let slope = round.slope, slope > 0 {
                    courseInfoRow(icon: "chart.line.uptrend.xyaxis", label: "Slope", value: "\(slope)")
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Round Statistics")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let fieldAverage = round.fieldAverage {
                    statCard(title: "Field Avg", value: String(format: "%.1f", fieldAverage))
                }
                
                if let fieldSize = round.fieldSize {
                    statCard(title: "Field Size", value: "\(fieldSize)")
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Helper Views

    private func nineBox(label: String, score: Int, par: Int) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            Text("\(score)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor(score, par: par))
                .monospacedDigit()

            let diff = score - par
            if diff != 0 {
                Text(formatToPar(diff))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(toParColor(diff))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
    }

    private func courseInfoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
    }

    // MARK: - Computed Properties

    private var parsedCourseName: String {
        // Parse "Course Name - City, State, Country" format
        if let dashIndex = round.course.firstIndex(of: "-") {
            let name = round.course[..<dashIndex].trimmingCharacters(in: .whitespaces)
            return name
        }
        return round.course
    }

    private var parsedLocation: String {
        // Parse "Course Name - City, State, Country" format
        if let dashIndex = round.course.firstIndex(of: "-") {
            let afterDash = round.course[round.course.index(after: dashIndex)...].trimmingCharacters(in: .whitespaces)
            return String(afterDash)
        }
        return ""
    }

    private func performanceSummary(toPar: Int) -> String {
        if toPar < -5 { return "Exceptional (\(formatToPar(toPar)))" }
        if toPar < -2 { return "Excellent (\(formatToPar(toPar)))" }
        if toPar < 0 { return "Very Good (\(formatToPar(toPar)))" }
        if toPar == 0 { return "Even Par" }
        if toPar <= 2 { return "Good (\(formatToPar(toPar)))" }
        if toPar <= 5 { return "Solid (\(formatToPar(toPar)))" }
        return "Challenging (\(formatToPar(toPar)))"
    }

    // MARK: - Formatting & Colors

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private func formatToPar(_ toPar: Int) -> String {
        if toPar > 0 {
            return "+\(toPar)"
        } else if toPar < 0 {
            return "\(toPar)"  // Already has minus sign
        }
        return "E"
    }

    private func formatDifferential(_ diff: Double) -> String {
        // USGA format: -3.5 (good, better than CR), +5.0 (bad, worse than CR)
        let formatted = String(format: "%.1f", abs(diff))
        if diff > 0 {
            return "+\(formatted)"
        } else if diff < 0 {
            return "-\(formatted)"
        }
        return "0.0"
    }

    private func scoreColor(_ score: Int, par: Int) -> Color {
        let diff = score - par
        if diff < 0 { return .green }
        if diff == 0 { return .primary }
        if diff <= 2 { return .orange }
        return .red
    }

    private func toParColor(_ toPar: Int) -> Color {
        if toPar < 0 { return .green }
        if toPar == 0 { return .primary }
        if toPar <= 2 { return .orange }
        return .red
    }

    private func formatYardage(_ yardage: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: yardage)) ?? "\(yardage)"
        return "\(formatted) yards"
    }

    private func differentialColor(_ diff: Double) -> Color {
        if diff < 0 { return .green }
        if diff == 0 { return .primary }
        if diff <= 3 { return .orange }
        return .red
    }

    // MARK: - Tournament Context Formatting

    private func formatPosition(_ position: String) -> String {
        // Extract numeric part from "T5" or "1" or "CUT"
        if position == "CUT" || position == "MC" {
            return "MC"
        }
        if position == "WD" {
            return "WD"
        }
        // Remove T prefix for display
        return position.replacingOccurrences(of: "T", with: "")
    }

    private func positionSuffix(_ position: String) -> String {
        // Add ordinal suffix (1st, 2nd, 3rd, etc.)
        if position == "CUT" || position == "MC" {
            return ""
        }
        if position == "WD" {
            return ""
        }

        let numStr = position.replacingOccurrences(of: "T", with: "")
        guard let num = Int(numStr) else { return "" }

        let suffix: String
        switch num % 10 {
        case 1 where num % 100 != 11:
            suffix = "st"
        case 2 where num % 100 != 12:
            suffix = "nd"
        case 3 where num % 100 != 13:
            suffix = "rd"
        default:
            suffix = "th"
        }

        return suffix
    }

    private func positionDescription(_ position: String) -> String {
        if position == "CUT" || position == "MC" {
            return "Missed the cut"
        }
        if position == "WD" {
            return "Withdrew from tournament"
        }

        let isTied = position.hasPrefix("T")
        let numStr = position.replacingOccurrences(of: "T", with: "")
        guard let num = Int(numStr) else { return "" }

        if num == 1 {
            return isTied ? "Tied for first place" : "Tournament Winner 🏆"
        } else if num <= 3 {
            return isTied ? "Tied for top 3 finish" : "Top 3 finish"
        } else if num <= 10 {
            return isTied ? "Tied for top 10 finish" : "Top 10 finish"
        } else if num <= 25 {
            return isTied ? "Tied for top 25" : "Top 25 finish"
        } else {
            return isTied ? "Tied finish" : ""
        }
    }

    private func positionColor(_ position: String) -> Color {
        if position == "CUT" || position == "MC" || position == "WD" {
            return .secondary
        }

        let numStr = position.replacingOccurrences(of: "T", with: "")
        guard let num = Int(numStr) else { return .primary }

        switch num {
        case 1:
            return .yellow  // Gold for winner
        case 2:
            return .gray    // Silver for 2nd
        case 3:
            return .orange  // Bronze for 3rd
        case 4...10:
            return .blue    // Blue for top 10
        case 11...25:
            return .green   // Green for top 25
        default:
            return .primary
        }
    }

    private var positionShadowColor: Color {
        guard let position = round.position else { return .clear }

        let numStr = position.replacingOccurrences(of: "T", with: "")
        guard let num = Int(numStr) else { return .clear }

        if num == 1 {
            return .yellow.opacity(0.2)
        } else if num <= 3 {
            return .orange.opacity(0.15)
        }
        return .clear
    }

    private func formatEarnings(_ earnings: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: earnings)) ?? "$\(Int(earnings))"
    }

    private func formatFedExPoints(_ points: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: points)) ?? "\(Int(points))"
    }
}

#Preview {
    NavigationStack {
        RoundDetailView(
            round: Round(
                id: UUID(),
                date: Date(),
                tournament: "Masters Tournament",
                course: "Augusta National Golf Club - Augusta, GA",
                roundNumber: 4,
                score: 71,
                par: 72,
                differential: -2.1,
                courseRating: 76.2,
                slope: 137,
                yardage: 7545,
                fieldAverage: 73.5,
                fieldSize: 156,
                position: "T5",
                earnings: 450000.0,
                fedexPoints: 110.0,
                worldRanking: nil,
                notes: nil
            ),
            playerName: "Tiger Woods",
            player: RemotePlayer(
                slug: "tiger-woods",
                name: "Tiger Woods",
                currentIndex: -4.1,
                lastRoundDate: Date(),
                tour: .pga,
                roundCount: 1059,
                indexHistory: nil,
                photoURL: nil,
                recentRounds: [
                    Round(
                        id: UUID(),
                        date: Date(),
                        tournament: "Masters Tournament",
                        course: "Augusta National Golf Club - Augusta, GA",
                        roundNumber: 4,
                        score: 71,
                        par: 72,
                        differential: -2.1,
                        courseRating: 76.2,
                        slope: 137,
                        yardage: 7545,
                        fieldAverage: 73.5,
                        fieldSize: 156,
                        position: "T5",
                        earnings: 450000.0,
                        fedexPoints: 110.0,
                        worldRanking: nil,
                        notes: nil
                    )
                ]
            )
        )
    }
}
