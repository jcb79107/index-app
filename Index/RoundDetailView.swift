import SwiftUI

struct RoundDetailView: View {
    let round: Round
    let playerName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Header Card
                heroCard

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
                    if let toPar = round.score - round.par, toPar != 0 {
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

            // Front 9 / Back 9 if available
            if let front9 = round.front9, let back9 = round.back9 {
                HStack(spacing: 16) {
                    nineBox(label: "FRONT 9", score: front9, par: 36)
                    nineBox(label: "BACK 9", score: back9, par: 36)
                }
            } else {
                Text("9-hole breakdown not available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Round Number Badge
            HStack {
                Image(systemName: "flag.circle.fill")
                    .foregroundStyle(.accentColor)
                Text("Round \(round.roundNumber)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(round.scoreType.capitalized)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(.accentColor)
                    .clipShape(Capsule())
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
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.accentColor)
                Text("Course Information")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                courseInfoRow(icon: "flag.fill", label: "Course", value: round.course)

                if round.yardage > 0 {
                    courseInfoRow(icon: "ruler.fill", label: "Yardage", value: "\(round.yardage) yards")
                }

                if round.courseRating > 0 {
                    courseInfoRow(icon: "star.fill", label: "Rating", value: String(format: "%.1f", round.courseRating))
                }

                if round.slope > 0 {
                    courseInfoRow(icon: "chart.line.uptrend.xyaxis", label: "Slope", value: "\(round.slope)")
                }

                courseInfoRow(icon: "circle.hexagongrid.fill", label: "Par", value: "\(round.par)")
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
                statCard(title: "Eagles", value: round.eagles > 0 ? "\(round.eagles)" : "-")
                statCard(title: "Birdies", value: round.birdies > 0 ? "\(round.birdies)" : "-")
                statCard(title: "Pars", value: round.pars > 0 ? "\(round.pars)" : "-")
                statCard(title: "Bogeys", value: round.bogeys > 0 ? "\(round.bogeys)" : "-")
                statCard(title: "Doubles+", value: round.doublePlus > 0 ? "\(round.doublePlus)" : "-")

                if round.fairwaysHit > 0 {
                    statCard(title: "Fairways", value: "\(round.fairwaysHit)/14")
                }

                if round.greensInRegulation > 0 {
                    statCard(title: "GIR", value: "\(round.greensInRegulation)/18")
                }

                if round.putts > 0 {
                    statCard(title: "Putts", value: "\(round.putts)")
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
        let formatted = String(format: "%.1f", abs(diff))
        if diff > 0 {
            return "+\(formatted)"
        } else if diff < 0 {
            return "-\(formatted)"
        }
        return formatted
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

    private func differentialColor(_ diff: Double) -> Color {
        if diff < 0 { return .green }
        if diff == 0 { return .primary }
        if diff <= 3 { return .orange }
        return .red
    }
}

#Preview {
    NavigationStack {
        RoundDetailView(
            round: Round(
                id: "1",
                date: Date(),
                tournament: "Masters Tournament",
                course: "Augusta National Golf Club",
                roundNumber: 1,
                score: 71,
                par: 72,
                courseRating: 76.2,
                slope: 137,
                yardage: 7545,
                scoreType: "competition",
                differential: -2.1,
                front9: 35,
                back9: 36,
                eagles: 1,
                birdies: 4,
                pars: 10,
                bogeys: 3,
                doublePlus: 0,
                fairwaysHit: 10,
                greensInRegulation: 13,
                putts: 28,
                notes: nil,
                source: "USGA"
            ),
            playerName: "Tiger Woods"
        )
    }
}
