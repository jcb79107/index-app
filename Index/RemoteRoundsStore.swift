import Foundation

final class RemoteRoundsStore {
    static let shared = RemoteRoundsStore()
    private init() {}
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    private let fileName = "remote_rounds_cache.json"
    
    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }
    
    func loadCachedPayload() -> RemoteRoundsPayload? {
        do {
            let data = try Data(contentsOf: cacheURL)
            return try decoder.decode(RemoteRoundsPayload.self, from: data)
        } catch {
            return nil
        }
    }
    
    func fetchAndCache(from url: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                return
            }
            
            // Decode incoming payload to validate
            let incoming = try decoder.decode(RemoteRoundsPayload.self, from: data)
            
            // If we already have cached data, only overwrite if newer
            if let existing = loadCachedPayload() {
                if incoming.updatedAt <= existing.updatedAt {
                    return
                }
            }
            
            // Cache to disk
            try data.write(to: cacheURL, options: [.atomic])
            
        } catch {
            // Silent fail for MVP
            // App will continue using last good cached data
        }
    }
    
    func rounds(for slug: String) -> [Round] {
        guard let payload = loadCachedPayload() else { return [] }
        return payload.players.first(where: { $0.slug == slug })?.rounds ?? []
    }
}

