import SwiftUI
import Combine

@MainActor
final class CoursesViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var filterUSGAOnly: Bool = true
    @Published var filterCountry: String? = nil
    @Published var sortBy: SortOption = .name
    @Published var filteredCourses: [Course] = []

    private var allCourses: [Course] = []
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.3

    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case rounds = "Rounds Played"
        case difficulty = "Difficulty"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .name: return "textformat.abc"
            case .rounds: return "chart.bar.fill"
            case .difficulty: return "gauge.high"
            }
        }
    }

    init() {
        loadCourses()
        setupDebouncing()
    }

    private func loadCourses() {
        allCourses = RemoteCoursesStore.shared.courses()
        applyFilters()
    }

    func refresh() async {
        let coursesURL = URL(string: "https://jcb79107.github.io/index-data/courses.json")!
        await RemoteCoursesStore.shared.fetchAndCache(from: coursesURL)
        allCourses = RemoteCoursesStore.shared.courses()
        applyFilters()
    }

    private func setupDebouncing() {
        // Debounce search text changes
        $searchText
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)

        // Apply filters immediately for other changes
        Publishers.CombineLatest3($filterUSGAOnly, $filterCountry, $sortBy)
            .sink { [weak self] _, _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    func applyFilters() {
        var courses = allCourses

        // Filter by USGA rating
        if filterUSGAOnly {
            courses = courses.filter { $0.hasUSGARating }
        }

        // Filter by country
        if let country = filterCountry {
            courses = courses.filter { $0.country == country }
        }

        // Filter by search text
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            courses = courses.filter { course in
                course.name.lowercased().contains(lowercased) ||
                course.displayLocation.lowercased().contains(lowercased)
            }
        }

        // Sort
        switch sortBy {
        case .name:
            courses.sort { $0.name < $1.name }
        case .rounds:
            courses.sort { $0.roundCount > $1.roundCount }
        case .difficulty:
            courses.sort { ($0.slope ?? 0) > ($1.slope ?? 0) }
        }

        filteredCourses = courses
    }

    func toggleUSGAFilter() {
        filterUSGAOnly.toggle()
    }

    func clearFilters() {
        searchText = ""
        filterUSGAOnly = false
        filterCountry = nil
        sortBy = .name
    }

    var availableCountries: [String] {
        let countries = Set(allCourses.compactMap { $0.country })
        return countries.sorted()
    }

    var stats: String {
        let total = allCourses.count
        let usga = allCourses.filter { $0.hasUSGARating }.count
        return "\(filteredCourses.count) of \(total) courses (\(usga) USGA-rated)"
    }
}
