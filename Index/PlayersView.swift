import SwiftUI

struct PlayersView: View {
    @StateObject private var vm = PlayersViewModel()
    @State private var showingFilters = false
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            // List with beautiful, spacious player rows
            List {
                // Sort mode header - now inside List so it scrolls
                Section {
                    HStack(spacing: 12) {
                        ForEach(PlayersViewModel.SortMode.allCases) { mode in
                            sortModeButton(for: mode)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                    // Show favorites first (if any and not filtered)
                    if !vm.favoritePlayers.isEmpty && !vm.filters.showFavoritesOnly && vm.filters.groupBy == .none {
                        Section {
                            ForEach(vm.favoritePlayers) { player in
                                playerRow(player)
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

                    // Empty state or grouped/flat list
                    if vm.filtered.isEmpty {
                        Section {
                            emptyStateView
                        }
                        .listRowBackground(Color.clear)
                    } else if vm.filters.groupBy == .none {
                        // Show non-favorites (or all if showing favorites only)
                        let playersToShow = vm.filters.showFavoritesOnly ? vm.favoritePlayers : vm.nonFavoritePlayers

                        ForEach(playersToShow) { player in
                            playerRow(player)
                        }
                    } else {
                        ForEach(vm.groupedPlayers, id: \.0) { groupName, players in
                            Section(groupName.isEmpty ? "Players" : groupName) {
                                ForEach(players) { player in
                                    playerRow(player)
                                }
                            }
                        }
                    }
            }
            .listStyle(.plain)
            .refreshable {
                isRefreshing = true
                await vm.refresh()
                try? await Task.sleep(nanoseconds: 500_000_000) // Keep visible for 0.5s
                isRefreshing = false
            }
            .overlay(alignment: .top) {
                if isRefreshing, let lastRefresh = vm.lastRefreshDate {
                    Text("Updated \(formatRelativeTime(lastRefresh))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search players")
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

    // MARK: - Sort Mode Button

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

    private func playerRow(_ player: RemotePlayer) -> some View {
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

            // Player info - wrapped in NavigationLink
            NavigationLink {
                PlayerDetailViewRemote(player: player)
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text(subtitle(for: player))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Index display
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
            }

            // Favorite button - always visible and tappable
            Button {
                vm.toggleFavorite(player)
            } label: {
                Image(systemName: vm.isFavorite(player) ? "star.fill" : "star")
                    .font(.system(size: 20))
                    .foregroundStyle(vm.isFavorite(player) ? .yellow : .secondary.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No Players Found")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if hasActiveFilters {
                Button {
                    // Reset filters
                    vm.filters = PlayerFilters()
                } label: {
                    Text("Clear Filters")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateMessage: String {
        if !vm.query.isEmpty {
            return "No players match '\(vm.query)'"
        } else if hasActiveFilters {
            return "Try adjusting your filters to see more players"
        } else {
            return "No players available"
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
