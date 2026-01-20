import SwiftUI

struct PlayersView: View {
    @StateObject private var vm = PlayersViewModel()
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sortModeHeader
                    .background(Color(.systemBackground))

                // Last refresh indicator
                if let lastRefresh = vm.lastRefreshDate {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                        Text("Updated \(formatRelativeTime(lastRefresh))")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                    .background(Color(.systemGroupedBackground))
                }

                // List with beautiful, spacious player rows
                List {
                    // Show favorites first (if any and not filtered)
                    if !vm.favoritePlayers.isEmpty && !vm.filters.showFavoritesOnly && vm.filters.groupBy == .none {
                        Section {
                            ForEach(vm.favoritePlayers) { player in
                                playerRow(player, showFavoriteStar: false)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            vm.toggleFavorite(player)
                                        } label: {
                                            Label("Unfavorite", systemImage: "star.slash")
                                        }
                                        .tint(.orange)
                                    }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Favorites")
                            }
                            .foregroundStyle(.yellow)
                            .font(.headline)
                        }
                    }

                    // Grouped or flat list
                    if vm.filters.groupBy == .none {
                        // Show non-favorites (or all if showing favorites only)
                        let playersToShow = vm.filters.showFavoritesOnly ? vm.favoritePlayers : vm.nonFavoritePlayers

                        ForEach(playersToShow) { player in
                            playerRow(player)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        vm.toggleFavorite(player)
                                    } label: {
                                        Label(vm.isFavorite(player) ? "Unfavorite" : "Favorite",
                                              systemImage: vm.isFavorite(player) ? "star.slash" : "star.fill")
                                    }
                                    .tint(.yellow)
                                }
                        }
                    } else {
                        ForEach(vm.groupedPlayers, id: \.0) { groupName, players in
                            Section(groupName.isEmpty ? "Players" : groupName) {
                                ForEach(players) { player in
                                    playerRow(player)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button {
                                                vm.toggleFavorite(player)
                                            } label: {
                                                Label(vm.isFavorite(player) ? "Unfavorite" : "Favorite",
                                                      systemImage: vm.isFavorite(player) ? "star.slash" : "star.fill")
                                            }
                                            .tint(.yellow)
                                        }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await vm.refresh()
                }
                .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search players")
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundStyle(hasActiveFilters ? Color.accentColor : Color.primary)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                PlayerFiltersView(filters: $vm.filters)
            }
        }
        .task {
            await vm.load()
        }
    }

    // MARK: - Sort Mode Header

    private var sortModeHeader: some View {
        VStack(spacing: 16) {
            // Sort Mode Selection - Large, clear, obvious
            HStack(spacing: 12) {
                ForEach(PlayersViewModel.SortMode.allCases) { mode in
                    sortModeButton(for: mode)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private func sortModeButton(for mode: PlayersViewModel.SortMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                vm.sortMode = mode
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.title3)
                    .foregroundStyle(vm.sortMode == mode ? .primary : .secondary)

                Text(mode.rawValue)
                    .font(.caption.weight(vm.sortMode == mode ? .semibold : .regular))
                    .foregroundStyle(vm.sortMode == mode ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(vm.sortMode == mode ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(vm.sortMode == mode ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Player Row - Redesigned for beauty and clarity

    private func playerRow(_ player: RemotePlayer, showFavoriteStar: Bool = true) -> some View {
        NavigationLink {
            PlayerDetailViewRemote(player: player)
        } label: {
            HStack(spacing: 16) {
                // Avatar - Now with actual photo!
                if let photoURL = player.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 2)
                            )
                    } placeholder: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .overlay {
                                Text(initials(from: player.name))
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary.opacity(0.7))
                            }
                    }
                } else {
                    // Fallback avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(initials(from: player.name))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.7))
                    }
                    .frame(width: 52, height: 52)
                }

                // Player info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(player.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)

                        // Favorite indicator - subtle but visible
                        if showFavoriteStar && vm.isFavorite(player) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                        }
                    }

                    Text(subtitle(for: player))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Index - THE STAR OF THE SHOW - Make it beautiful and prominent
                VStack(alignment: .trailing, spacing: 2) {
                    Text(indexText(for: player))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(indexColor(for: player.currentIndex))
                        .monospacedDigit()

                    Text("INDEX")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Helpers

    private var hasActiveFilters: Bool {
        vm.filters.tour != nil ||
        vm.filters.indexMin != -20.0 ||
        vm.filters.indexMax != 10.0 ||
        vm.filters.activity != .all ||
        vm.filters.groupBy != .none ||
        vm.filters.showFavoritesOnly
    }

    private func subtitle(for player: RemotePlayer) -> String {
        if let date = player.lastRoundDate {
            let f = DateFormatter()
            f.dateStyle = .medium
            return "Last played \(f.string(from: date))"
        } else {
            return "No recorded rounds"
        }
    }

    private func indexText(for player: RemotePlayer) -> String {
        guard let index = player.currentIndex else { return "—" }
        let formatted = String(format: "%.1f", abs(index))
        if index < 0 { return "+\(formatted)" }
        if index > 0 { return formatted }
        return "0.0"
    }

    private func indexColor(for index: Double?) -> Color {
        guard let index = index else { return .secondary }
        // Elite players (better than +5) get special treatment
        if index <= -7.5 { return .green }
        if index <= -5.0 { return .blue }
        return .primary
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first
        let last = parts.last?.first
        return [first, last]
            .compactMap { $0 }
            .map(String.init)
            .joined()
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "1 day ago"
            } else if days < 7 {
                return "\(days) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return "on \(formatter.string(from: date))"
            }
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 min ago" : "\(minutes) mins ago"
        } else {
            return "just now"
        }
    }
}

// MARK: - Sort Mode Extension

extension PlayersViewModel.SortMode {
    var icon: String {
        switch self {
        case .bestIndex: return "trophy.fill"
        case .recentlyActive: return "clock.fill"
        case .name: return "textformat.abc"
        }
    }
}

#Preview {
    PlayersView()
}
