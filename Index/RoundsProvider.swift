import Foundation

struct RoundsProvider {
    static func rounds(for slug: String) -> [Round] {
        let remote = RemoteRoundsStore.shared.rounds(for: slug)
        let bundle = DataStore.shared.loadRounds(for: slug)
        let source = remote.isEmpty ? bundle : remote
        return source.sorted(by: { $0.date > $1.date })
    }
}
