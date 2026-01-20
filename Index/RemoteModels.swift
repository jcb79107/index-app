import Foundation

struct RemoteRoundsPayload: Codable {
    let version: Int
    let updatedAt: Date
    let players: [RemotePlayerRounds]
}

struct RemotePlayerRounds: Codable {
    let slug: String
    let rounds: [Round]
}
