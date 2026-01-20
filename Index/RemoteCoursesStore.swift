import Foundation

// MARK: - Payload

struct RemoteCoursesPayload: Codable {
    let version: Int
    let updatedAt: Date
    let count: Int
    let courses: [Course]
}

// MARK: - Store

final class RemoteCoursesStore {
    static let shared = RemoteCoursesStore()
    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let fileName = "remote_courses_cache.json"

    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func loadCachedPayload() -> RemoteCoursesPayload? {
        do {
            let data = try Data(contentsOf: cacheURL)
            return try decoder.decode(RemoteCoursesPayload.self, from: data)
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
            _ = try decoder.decode(RemoteCoursesPayload.self, from: data)

            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            // Silent fail for MVP
        }
    }

    func courses() -> [Course] {
        loadCachedPayload()?.courses ?? []
    }
}
