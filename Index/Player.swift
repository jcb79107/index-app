import Foundation

struct Player: Identifiable, Hashable {
    let id: UUID
    let name: String
    let era: String
    let currentIndex: Double
    
    // Used to load bundle JSON, e.g. "tiger-woods" -> tiger-woods.json
    let slug: String
    
    // UI trend points (still mock for now)
    let indexHistory: [IndexPoint]
}

struct IndexPoint: Identifiable, Hashable, Codable {
    var id: String { date.ISO8601Format() }
    let date: Date
    let index: Double
}

extension Player {
    static let mock: [Player] = [
        .init(
            id: UUID(),
            name: "Tiger Woods",
            era: "1996–Present",
            currentIndex: +7.4,
            slug: "tiger-woods",
            indexHistory: IndexPoint.mockTiger
        ),
        .init(
            id: UUID(),
            name: "Jack Nicklaus",
            era: "1961–2005",
            currentIndex: +6.8,
            slug: "jack-nicklaus",
            indexHistory: IndexPoint.mockJack
        ),
        .init(
            id: UUID(),
            name: "Rory McIlroy",
            era: "2007–Present",
            currentIndex: +6.2,
            slug: "rory-mcilroy",
            indexHistory: IndexPoint.mockRory
        ),
        .init(
            id: UUID(),
            name: "Scottie Scheffler",
            era: "2019–Present",
            currentIndex: +7.0,
            slug: "scottie-scheffler",
            indexHistory: IndexPoint.mockScottie
        ),
        .init(
            id: UUID(),
            name: "Ben Hogan",
            era: "1930–1971",
            currentIndex: +7.1,
            slug: "ben-hogan",
            indexHistory: IndexPoint.mockHogan
        ),
        .init(
            id: UUID(),
            name: "Annika Sörenstam",
            era: "1992–2008",
            currentIndex: +6.0,
            slug: "annika-sorenstam",
            indexHistory: IndexPoint.mockAnnika
        )
    ]
}

private extension IndexPoint {
    static func d(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return Calendar.current.date(from: c) ?? .now
    }
    
    // These are intentionally made-up “shape” data for UI.
    static let mockTiger: [IndexPoint] = [
        .init(date: d(1999, 1, 1), index: 6.2),
        .init(date: d(2000, 6, 1), index: 7.8),
        .init(date: d(2001, 8, 1), index: 8.1),
        .init(date: d(2002, 9, 1), index: 7.5),
        .init(date: d(2008, 5, 1), index: 7.9),
        .init(date: d(2019, 4, 1), index: 6.7),
        .init(date: d(2024, 7, 1), index: 5.9),
        .init(date: d(2025, 12, 1), index: 7.4)
    ]
    
    static let mockJack: [IndexPoint] = [
        .init(date: d(1965, 1, 1), index: 6.0),
        .init(date: d(1972, 6, 1), index: 7.1),
        .init(date: d(1975, 7, 1), index: 7.4),
        .init(date: d(1980, 8, 1), index: 6.6),
        .init(date: d(1986, 4, 1), index: 6.9),
        .init(date: d(1990, 1, 1), index: 6.3)
    ]
    
    static let mockRory: [IndexPoint] = [
        .init(date: d(2011, 6, 1), index: 6.7),
        .init(date: d(2012, 8, 1), index: 7.6),
        .init(date: d(2014, 8, 1), index: 7.9),
        .init(date: d(2019, 9, 1), index: 7.1),
        .init(date: d(2022, 7, 1), index: 6.8),
        .init(date: d(2025, 12, 1), index: 6.2)
    ]
    
    static let mockScottie: [IndexPoint] = [
        .init(date: d(2021, 1, 1), index: 5.8),
        .init(date: d(2022, 4, 1), index: 7.0),
        .init(date: d(2023, 4, 1), index: 7.6),
        .init(date: d(2024, 4, 1), index: 7.9),
        .init(date: d(2025, 12, 1), index: 7.0)
    ]
    
    static let mockHogan: [IndexPoint] = [
        .init(date: d(1946, 1, 1), index: 6.2),
        .init(date: d(1950, 6, 1), index: 7.4),
        .init(date: d(1953, 7, 1), index: 7.8),
        .init(date: d(1956, 8, 1), index: 7.1),
        .init(date: d(1960, 1, 1), index: 6.6)
    ]
    
    static let mockAnnika: [IndexPoint] = [
        .init(date: d(1997, 1, 1), index: 5.9),
        .init(date: d(2001, 6, 1), index: 6.8),
        .init(date: d(2004, 7, 1), index: 7.1),
        .init(date: d(2006, 8, 1), index: 6.6),
        .init(date: d(2008, 1, 1), index: 6.0)
    ]
}

