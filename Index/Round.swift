import Foundation

struct Round: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let tournament: String
    let course: String
    let roundNumber: Int
    let score: Int
    let par: Int
    let differential: Double?
    let courseRating: Double?
    let slope: Int?
    let yardage: Int?
    let fieldAverage: Double?
    let fieldSize: Int?

    // Tournament context (position in tournament after this round)
    let position: String?        // "1", "T5", "MC" (missed cut), "WD" (withdrawn)
    let earnings: Double?        // Prize money in USD (tournament total, not per-round)
    let fedexPoints: Double?     // FedEx Cup points earned (tournament total)
    let worldRanking: Int?       // Official World Golf Ranking at time of round

    // Optional metadata
    let notes: String?
}

