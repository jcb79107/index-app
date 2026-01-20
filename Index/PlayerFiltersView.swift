import SwiftUI

struct PlayerFilters: Equatable {
    var tour: RemotePlayer.Tour?
    var indexMin: Double = -20.0
    var indexMax: Double = 10.0
    var activity: ActivityFilter = .all
    var groupBy: GroupByOption = .none
    var showFavoritesOnly: Bool = false

    enum ActivityFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case activeLastYear = "Active Last Year"
        case activeLast2Years = "Active Last 2 Years"
        case retired = "Retired Only"

        var id: String { rawValue }
    }

    enum GroupByOption: String, CaseIterable, Identifiable {
        case none = "None"
        case tour = "By Tour"
        case indexTier = "By Index Tier"

        var id: String { rawValue }
    }
}

struct PlayerFiltersView: View {
    @Binding var filters: PlayerFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Tour section
                Section("Tour") {
                    Picker("Tour", selection: $filters.tour) {
                        Text("All Tours").tag(nil as RemotePlayer.Tour?)
                        ForEach(RemotePlayer.Tour.allCases, id: \.self) { tour in
                            Text(tour.displayName).tag(tour as RemotePlayer.Tour?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Index range section
                Section {
                    HStack {
                        Text("Min: \(String(format: "%+.1f", filters.indexMin))")
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        Slider(value: $filters.indexMin, in: -20...10, step: 0.5)
                    }

                    HStack {
                        Text("Max: \(String(format: "%+.1f", filters.indexMax))")
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        Slider(value: $filters.indexMax, in: -20...10, step: 0.5)
                    }
                } header: {
                    Text("Index Range")
                } footer: {
                    Text("Filter players by their handicap index range")
                }

                // Activity section
                Section("Activity") {
                    Picker("Activity", selection: $filters.activity) {
                        ForEach(PlayerFilters.ActivityFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Grouping section
                Section("Grouping") {
                    Picker("Group By", selection: $filters.groupBy) {
                        ForEach(PlayerFilters.GroupByOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Favorites section
                Section {
                    Toggle("Show Favorites Only", isOn: $filters.showFavoritesOnly)
                } footer: {
                    Text("Star your favorite players to quickly filter them")
                }

                // Reset button
                Section {
                    Button("Reset All Filters") {
                        filters = PlayerFilters()
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filter Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PlayerFiltersView(filters: .constant(PlayerFilters()))
}
