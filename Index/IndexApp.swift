import SwiftUI

@main
struct IndexApp: App {

    // GitHub Pages JSON endpoints
    private let roundsURL = URL(
        string: "https://jcb79107.github.io/index-data/rounds.json"
    )!

    private let playersURL = URL(
        string: "https://jcb79107.github.io/index-data/players.json"
    )!

    private let coursesURL = URL(
        string: "https://jcb79107.github.io/index-data/courses.json"
    )!

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Fetch data on app launch
                    await RemoteRoundsStore.shared.fetchAndCache(from: roundsURL)
                    await RemotePlayersStore.shared.fetchAndCache(from: playersURL)
                    await RemoteCoursesStore.shared.fetchAndCache(from: coursesURL)
                }
        }
    }
}

