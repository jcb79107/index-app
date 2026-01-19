import Foundation
import SwiftUI
import Combine

@MainActor
final class PlayersViewModel: ObservableObject {

    // MARK: - Sort Mode

    enum SortMode: String, CaseIterable, Identifiable {
        case bestIndex = "Best Index"
        case recentlyActive = "Recently Active"
        case name = "Name"

        var id: String { rawValue }
    }

    // MARK: - State

    @Published var query: String = ""
    @Published var sortMode: SortMode = .bestIndex
    @Published var filters: PlayerFilters = PlayerFilters()
    @Published var debouncedQuery: String = ""

    @Published private(set) var allPlayers: [RemotePlayer] = []

    @AppStorage("favoritePlayerSlugs") private var favoritesData: Data = Data()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Favorites

    var favorites: Set<String> {
        get {
            (try? JSONDecoder().decode(Set<String>.self, from: favoritesData)) ?? []
        }
        set {
            favoritesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    func toggleFavorite(_ player: RemotePlayer) {
        var favs = favorites
        if favs.contains(player.slug) {
            favs.remove(player.slug)
        } else {
            favs.insert(player.slug)
        }
        favorites = favs
        objectWillChange.send()
    }

    func isFavorite(_ player: RemotePlayer) -> Bool {
        favorites.contains(player.slug)
    }

    // MARK: - Load

    init() {
        setupDebouncing()
    }

    func load() async {
        allPlayers = RemotePlayersStore.shared.players()
    }

    func refresh() async {
        let playersURL = URL(string: "https://jcb79107.github.io/index-data/players.json")!
        await RemotePlayersStore.shared.fetchAndCache(from: playersURL)
        allPlayers = RemotePlayersStore.shared.players()
    }

    private func setupDebouncing() {
        $query
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                self?.debouncedQuery = value
            }
            .store(in: &cancellables)
    }

    // MARK: - Derived Data

    var filtered: [RemotePlayer] {
        let q = debouncedQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var result = allPlayers

        // 1️⃣ Search
        if !q.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(q)
            }
        }

        // 2️⃣ Apply filters
        // Tour filter
        if let tour = filters.tour {
            result = result.filter { $0.tour == tour }
        }

        // Index range filter
        result = result.filter { player in
            guard let index = player.currentIndex else { return false }
            return index >= filters.indexMin && index <= filters.indexMax
        }

        // Activity filter
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: now)!

        switch filters.activity {
        case .all:
            break
        case .activeLastYear:
            result = result.filter { player in
                guard let lastRound = player.lastRoundDate else { return false }
                return lastRound >= oneYearAgo
            }
        case .activeLast2Years:
            result = result.filter { player in
                guard let lastRound = player.lastRoundDate else { return false }
                return lastRound >= twoYearsAgo
            }
        case .retired:
            result = result.filter { $0.tour == .retired }
        }

        // Favorites filter
        if filters.showFavoritesOnly {
            let favs = favorites
            result = result.filter { favs.contains($0.slug) }
        }

        // 3️⃣ Sort
        switch sortMode {

        case .bestIndex:
            result.sort {
                switch ($0.currentIndex, $1.currentIndex) {
                case let (a?, b?):
                    return a < b   // golf-correct
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return $0.name < $1.name
                }
            }

        case .recentlyActive:
            result.sort {
                switch ($0.lastRoundDate, $1.lastRoundDate) {
                case let (a?, b?):
                    return a > b
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return $0.name < $1.name
                }
            }

        case .name:
            result.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }

        return result
    }

    // MARK: - Grouping

    var groupedPlayers: [(String, [RemotePlayer])] {
        let players = filtered

        switch filters.groupBy {
        case .none:
            return [("", players)]

        case .tour:
            let grouped = Dictionary(grouping: players) { player -> String in
                player.tour?.rawValue ?? "Unknown"
            }
            return grouped.sorted { $0.key < $1.key }

        case .indexTier:
            let grouped = Dictionary(grouping: players) { player -> String in
                guard let index = player.currentIndex else { return "No Index" }
                if index < -5.0 {
                    return "Elite (< -5.0)"
                } else if index < -2.0 {
                    return "Great (-5.0 to -2.0)"
                } else if index < 2.0 {
                    return "Good (-2.0 to +2.0)"
                } else {
                    return "Average (+2.0 and up)"
                }
            }

            // Sort by tier order
            let tierOrder = ["Elite (< -5.0)", "Great (-5.0 to -2.0)", "Good (-2.0 to +2.0)", "Average (+2.0 and up)", "No Index"]
            return tierOrder.compactMap { tier in
                guard let players = grouped[tier] else { return nil }
                return (tier, players)
            }
        }
    }
}
