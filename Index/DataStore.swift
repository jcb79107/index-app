import Foundation

final class DataStore {
    static let shared = DataStore()
    private init() {}
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    func loadRounds(for playerSlug: String) -> [Round] {
        // Looks for a file like: tiger-woods.json
        guard let url = Bundle.main.url(forResource: playerSlug, withExtension: "json") else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([Round].self, from: data)
        } catch {
            print("Failed to load rounds for \(playerSlug): \(error)")
            return []
        }
    }
}

