import Foundation

// MARK: - Store

final class RemoteCoursesStore {
    static let shared = RemoteCoursesStore()
    private init() {}

    private let decoder = JSONDecoder()

    private let fileName = "remote_courses_cache.json"

    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func loadCachedPayload() -> CoursesResponse? {
        do {
            let data = try Data(contentsOf: cacheURL)
            return try decoder.decode(CoursesResponse.self, from: data)
        } catch {
            print("Failed to load cached courses: \(error)")
            return nil
        }
    }

    func fetchAndCache(from url: URL) async {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                print("Invalid HTTP response")
                return
            }

            // Validate decode before caching
            _ = try decoder.decode(CoursesResponse.self, from: data)

            try data.write(to: cacheURL, options: [.atomic])
            print("Cached \(url.lastPathComponent)")
        } catch {
            print("Failed to fetch courses: \(error)")
        }
    }

    func courses() -> [Course] {
        loadCachedPayload()?.courses ?? []
    }
}
