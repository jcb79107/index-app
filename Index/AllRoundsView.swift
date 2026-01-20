import SwiftUI

struct AllRoundsView: View {
    let playerName: String
    let slug: String
    
    private var rounds: [Round] {
        RoundsProvider.rounds(for: slug)
    }
    
    private var grouped: [(key: String, value: [Round])] {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        
        let dict = Dictionary(grouping: rounds) { r in
            f.string(from: r.date)
        }
        
        // Sort years descending
        return dict
            .map { ($0.key, $0.value.sorted(by: { $0.date > $1.date })) }
            .sorted(by: { $0.key > $1.key })
    }
    
    var body: some View {
        List {
            ForEach(grouped, id: \.key) { year, items in
                Section(year) {
                    ForEach(items) { r in
                        RoundRow(round: r)
                    }
                }
            }
        }
        .navigationTitle("Rounds")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct RoundRow: View {
    let round: Round
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(round.tournament)
                    .font(.subheadline.weight(.semibold))
                Text("\(round.course) • R\(round.roundNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(dateString(round.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(round.score)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Text("Par \(round.par)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

#Preview {
    NavigationStack {
        AllRoundsView(playerName: "Tiger Woods", slug: "tiger-woods")
    }
}
