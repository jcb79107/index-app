import Foundation

// MARK: - Payload

struct RemotePlayersPayload: Codable {
    let version: Int
    let updatedAt: Date
    let count: Int
    let players: [RemotePlayer]
}

// MARK: - Player Model (Schema-safe, forward compatible)

struct RemotePlayer: Codable, Identifiable, Hashable {
    var id: String { slug }

    let slug: String
    let name: String

    // Optional fields (may not exist in JSON yet)
    let currentIndex: Double?
    let lastRoundDate: Date?
    let tour: Tour?
    let roundCount: Int?
    let indexHistory: [IndexPoint]?
    let photoURL: String?

    enum CodingKeys: String, CodingKey {
        case slug, name, lastRoundDate, tour, roundCount, indexHistory, photoURL
        case currentIndex = "index"  // JSON field is "index", Swift property is "currentIndex"
    }

    enum Tour: String, Codable, CaseIterable {
        case pga = "PGA"
        case dpWorld = "DP World"
        case liv = "LIV"
        case amateur = "Amateur"
        case retired = "Retired"

        var displayName: String {
            switch self {
            case .pga: return "PGA Tour"
            case .dpWorld: return "DP World Tour"
            case .liv: return "LIV Golf"
            case .amateur: return "Amateur"
            case .retired: return "Retired"
            }
        }
    }
}

// MARK: - Store

final class RemotePlayersStore {
    static let shared = RemotePlayersStore()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let fileName = "remote_players_cache.json"

    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func loadCachedPayload() -> RemotePlayersPayload? {
        do {
            let data = try Data(contentsOf: cacheURL)
            return try decoder.decode(RemotePlayersPayload.self, from: data)
        } catch {
            return nil
        }
    }

    func fetchAndCache(from url: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return
            }

            // Validate decode before caching
            _ = try decoder.decode(RemotePlayersPayload.self, from: data)

            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            // Silent fail for MVP
        }
    }

    func players() -> [RemotePlayer] {
        loadCachedPayload()?.players ?? []
    }
}

