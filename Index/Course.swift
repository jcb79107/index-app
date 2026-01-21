import Foundation

// MARK: - Course Version History

struct CourseVersion: Codable, Identifiable, Hashable {
    let startYear: Int
    let endYear: Int
    let yardage: Int
    let notes: String

    var id: String { "\(startYear)-\(endYear)" }

    var yearRange: String {
        if startYear == endYear {
            return "\(startYear)"
        }
        return "\(startYear)-\(endYear)"
    }
}

// MARK: - Course Model

struct Course: Codable, Identifiable, Hashable {
    var id: String { slug }

    let slug: String
    let name: String
    let fullName: String
    let city: String?
    let state: String?
    let country: String?
    let hasUSGARating: Bool
    let courseRating: Double?
    let slope: Int?
    let par: Int?
    let yardage: Int?
    let tournamentCount: Int
    let roundCount: Int
    let firstPlayed: String?
    let lastPlayed: String?
    let recentTournaments: [RecentTournament]?
    let versionHistory: [CourseVersion]?

    // Computed property for display location
    var displayLocation: String {
        var parts: [String] = []
        if let city = city { parts.append(city) }
        if let state = state { parts.append(state) }
        if let country = country { parts.append(country) }
        return parts.joined(separator: ", ")
    }

    // Computed property for short location
    var locationShort: String {
        if let state = state {
            return "\(city ?? ""), \(state)"
        }
        return city ?? country ?? "Unknown"
    }

    // Computed property for USGA rating display
    var ratingDisplay: String? {
        guard let rating = courseRating, let slope = slope else { return nil }
        return "Rating: \(String(format: "%.1f", rating)) | Slope: \(slope)"
    }

    // Computed property for difficulty badge
    var difficultyLevel: String {
        guard let slope = slope else { return "Unknown" }

        switch slope {
        case ..<113: return "Easy"
        case 113..<125: return "Moderate"
        case 125..<135: return "Difficult"
        case 135...: return "Very Difficult"
        default: return "Unknown"
        }
    }

    // Version history helpers
    var hasVersionHistory: Bool {
        versionHistory != nil && !(versionHistory?.isEmpty ?? true)
    }

    var currentVersion: CourseVersion? {
        versionHistory?.last
    }

    var earliestVersion: CourseVersion? {
        versionHistory?.first
    }

    var yardageIncrease: Int? {
        guard let earliest = earliestVersion?.yardage,
              let current = currentVersion?.yardage else {
            return nil
        }
        return current - earliest
    }

    func version(for year: Int) -> CourseVersion? {
        versionHistory?.first { version in
            year >= version.startYear && year <= version.endYear
        }
    }
}

// MARK: - Recent Tournament Model

struct RecentTournament: Codable, Identifiable, Hashable {
    var id: String { "\(name)-\(year)" }

    let name: String
    let year: Int
    let dates: String
    let winnerSlug: String
    let winningScore: Int?
    let fieldSize: Int?
    let fieldAverage: Double?
    let leaderboard: [LeaderboardEntry]?

    // Computed property for winning score display
    var winningScoreDisplay: String? {
        guard let score = winningScore else { return nil }
        if score < 0 {
            return "\(score)"
        } else if score > 0 {
            return "+\(score)"
        } else {
            return "E"
        }
    }
}

// MARK: - Leaderboard Entry Model

struct LeaderboardEntry: Codable, Identifiable, Hashable {
    var id: String { playerSlug }

    let playerSlug: String
    let totalScore: Int
    let scoreToPar: Int?
    let rounds: Int

    // Computed property for score to par display
    var scoreToParDisplay: String {
        guard let score = scoreToPar else { return "E" }
        if score < 0 {
            return "\(score)"
        } else if score > 0 {
            return "+\(score)"
        } else {
            return "E"
        }
    }
}

// MARK: - Courses Response

struct CoursesResponse: Codable {
    let version: Int
    let updatedAt: String
    let count: Int
    let courses: [Course]
}
