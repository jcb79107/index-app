import SwiftUI

struct CourseDetailView: View {
    let course: Course
    @State private var showingSimulation = false
    @State private var selectedYear: Int?

    private var yearsAvailable: [Int] {
        guard let history = course.versionHistory else { return [] }
        var years: [Int] = []
        for version in history {
            for year in version.startYear...version.endYear {
                years.append(year)
            }
        }
        return years.sorted()
    }

    private var selectedVersion: CourseVersion? {
        guard let year = selectedYear else {
            return course.currentVersion
        }
        return course.version(for: year)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Course info card - Beautiful and prominent
                VStack(alignment: .leading, spacing: 16) {
                    // Course name with USGA badge
                    HStack(spacing: 12) {
                        Text(course.name)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.primary)

                        if course.hasUSGARating {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.yellow)
                        }
                    }

                    // Location
                    if !course.displayLocation.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.accentColor)
                            Text(course.displayLocation)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // USGA Rating Stats - Prominent and beautiful
                    if course.hasUSGARating {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                if let rating = course.courseRating {
                                    CourseStatBox(
                                        icon: "target",
                                        title: "Rating",
                                        value: String(format: "%.1f", rating),
                                        color: .blue
                                    )
                                }

                                if let slope = course.slope {
                                    CourseStatBox(
                                        icon: "gauge.high",
                                        title: "Slope",
                                        value: "\(slope)",
                                        color: slopeColor(for: slope)
                                    )
                                }

                                if let par = course.par {
                                    CourseStatBox(
                                        icon: "flag.fill",
                                        title: "Par",
                                        value: "\(par)",
                                        color: .green
                                    )
                                }
                            }

                            // Difficulty badge
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.yellow)
                                Text("USGA RATED")
                                    .font(.caption.weight(.bold))
                                    .tracking(0.5)
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(course.difficultyLevel.uppercased())
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(slopeColor(for: course.slope ?? 113))
                            }
                            .foregroundStyle(.secondary)
                        }
                    } else if let par = course.par {
                        HStack {
                            CourseStatBox(
                                icon: "flag.fill",
                                title: "Par",
                                value: "\(par)",
                                color: .green
                            )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Version History Timeline - THE COOL UX FEATURE!
                if course.hasVersionHistory {
                    versionHistorySection
                }

                // Simulate button - Eye-catching and prominent
                if course.hasUSGARating {
                    Button(action: { showingSimulation = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Simulate Score at This Course")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }

                // Statistics section - Beautiful and clear
                VStack(alignment: .leading, spacing: 16) {
                    Text("Course Statistics")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 16) {
                        // Tournaments
                        VStack(spacing: 10) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.yellow)

                            Text("\(course.tournamentCount)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("Tournaments")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)

                        // Rounds
                        VStack(spacing: 10) {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 24))
                                .foregroundStyle(.green)

                            Text("\(course.roundCount)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("Rounds")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                    }

                    if let firstPlayed = course.firstPlayed,
                       let lastPlayed = course.lastPlayed {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FIRST PLAYED")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)
                                Text(firstPlayed, style: .date)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("LAST PLAYED")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)
                                Text(lastPlayed, style: .date)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                    }
                }

                // Tournaments section - Beautiful and prominent
                if let tournaments = course.recentTournaments, !tournaments.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Tournaments")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)

                        ForEach(tournaments) { tournament in
                            NavigationLink {
                                TournamentDetailView(tournament: tournament, course: course)
                            } label: {
                                TournamentCard(tournament: tournament)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSimulation) {
            SimulationView(preselectedCourse: course)
        }
    }

    // MARK: - Version History Section

    private var versionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course History")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)

            // Year Timeline Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(yearsAvailable, id: \.self) { year in
                        YearButton(
                            year: year,
                            isSelected: selectedYear == year || (selectedYear == nil && year == yearsAvailable.last),
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedYear = year
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)

            // Stats Card for Selected Year
            if let version = selectedVersion {
                VStack(alignment: .leading, spacing: 16) {
                    // Yardage with comparison
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YARDAGE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(version.yardage)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)

                                Text("yards")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }

                            // Show delta if not the earliest version
                            if let increase = yardageChange(for: version) {
                                HStack(spacing: 4) {
                                    Image(systemName: increase > 0 ? "arrow.up.forward" : "arrow.down.forward")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("\(increase > 0 ? "+" : "")\(increase) yards since \(course.earliestVersion?.startYear ?? 2001)")
                                        .font(.caption.weight(.medium))
                                }
                                .foregroundStyle(increase > 0 ? .orange : .green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background((increase > 0 ? Color.orange : Color.green).opacity(0.15))
                                .cornerRadius(8)
                            }
                        }

                        Spacer()

                        // Year period
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(version.yearRange)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.accentColor)

                            Text("PERIOD")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)
                        }
                    }

                    // Notes/Description
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accentColor)

                        Text(version.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }

            // Version History Chart (if multiple versions)
            if let history = course.versionHistory, history.count > 1 {
                versionHistoryChart(history: history)
            }
        }
    }

    private func yardageChange(for version: CourseVersion) -> Int? {
        guard let earliest = course.earliestVersion?.yardage else { return nil }
        let current = version.yardage
        let change = current - earliest
        return change != 0 ? change : nil
    }

    private func versionHistoryChart(history: [CourseVersion]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yardage Evolution")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            // Simple bar chart representation
            VStack(spacing: 8) {
                ForEach(history) { version in
                    let maxYardage = history.map(\.yardage).max() ?? 7500
                    let minYardage = history.map(\.yardage).min() ?? 6500
                    let range = maxYardage - minYardage
                    let normalizedWidth = range > 0 ? CGFloat(version.yardage - minYardage) / CGFloat(range) : 1.0
                    let width = 0.5 + (normalizedWidth * 0.5) // Scale between 0.5 and 1.0

                    HStack(spacing: 12) {
                        Text(version.yearRange)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .leading)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * width)
                        }
                        .frame(height: 24)

                        Text("\(version.yardage)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // Color coding for slope difficulty
    private func slopeColor(for slope: Int) -> Color {
        switch slope {
        case ..<113: return .green
        case 113..<125: return .blue
        case 125..<135: return .orange
        case 135...: return .red
        default: return .secondary
        }
    }
}

// MARK: - Course Stat Box - Beautiful component for course stats

struct CourseStatBox: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Year Button - For timeline selector

struct YearButton: View {
    let year: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(year)")
                .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tournament Card - Beautiful and prominent

struct TournamentCard: View {
    let tournament: RecentTournament

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(tournament.dates)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Year badge
                Text("\(tournament.year)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(8)
            }

            Divider()

            // Stats row
            HStack(spacing: 16) {
                if let winningScore = tournament.winningScoreDisplay {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.yellow)
                        Text(winningScore)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }
                }

                if let fieldSize = tournament.fieldSize {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 10))
                        Text("\(fieldSize)")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }

                if let fieldAvg = tournament.fieldAverage {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", fieldAvg))
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: Course(
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
            firstPlayed: "2001-04-05T00:00:00Z",
            lastPlayed: "2024-04-14T00:00:00Z",
            recentTournaments: [
                RecentTournament(
                    name: "Masters Tournament",
                    year: 2024,
                    dates: "2024-04-11 to 2024-04-14",
                    winnerSlug: "scottie-scheffler",
                    winningScore: -11,
                    fieldSize: 89,
                    fieldAverage: 74.2,
                    leaderboard: nil
                )
            ],
            versionHistory: [
                CourseVersion(startYear: 2001, endYear: 2001, yardage: 6985, notes: "Pre-Tiger proofing"),
                CourseVersion(startYear: 2002, endYear: 2005, yardage: 7270, notes: "First major lengthening"),
                CourseVersion(startYear: 2006, endYear: 2018, yardage: 7435, notes: "Further expansions"),
                CourseVersion(startYear: 2019, endYear: 2024, yardage: 7545, notes: "Current championship setup")
            ]
        ))
    }
}
