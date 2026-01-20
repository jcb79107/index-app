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
    let fieldAverage: Double?
    let fieldSize: Int?

    // Optional metadata for later
    let notes: String?
}

