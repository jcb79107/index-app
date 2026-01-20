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

            // Round Number Badge
            HStack {
                Image(systemName: "flag.circle.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Round \(round.roundNumber)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
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
                    .foregroundStyle(Color.accentColor)
                Text("Course Information")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                courseInfoRow(icon: "flag.fill", label: "Course", value: round.course)

                if let courseRating = round.courseRating, courseRating > 0 {
                    courseInfoRow(icon: "star.fill", label: "Rating", value: String(format: "%.1f", courseRating))
                }

                if let slope = round.slope, slope > 0 {
                    courseInfoRow(icon: "chart.line.uptrend.xyaxis", label: "Slope", value: "\(slope)")
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
                id: UUID(),
                date: Date(),
                tournament: "Masters Tournament",
                course: "Augusta National Golf Club",
                roundNumber: 1,
                score: 71,
                par: 72,
                differential: -2.1,
                courseRating: 76.2,
                slope: 137,
                fieldAverage: 73.5,
                fieldSize: 156,
                notes: nil
            ),
            playerName: "Tiger Woods"
        )
    }
}
