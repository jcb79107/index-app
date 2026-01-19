import SwiftUI

struct CoursesView: View {
    @StateObject private var viewModel = CoursesViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with sort selection - Clean, prominent, beautiful
                VStack(spacing: 12) {
                    // Sort Mode Selection - Large, clear, obvious
                    HStack(spacing: 12) {
                        ForEach(CoursesViewModel.SortOption.allCases) { option in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.sortBy = option
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: option.icon)
                                        .font(.title3)
                                        .foregroundStyle(viewModel.sortBy == option ? .primary : .secondary)

                                    Text(option.rawValue)
                                        .font(.caption.weight(viewModel.sortBy == option ? .semibold : .regular))
                                        .foregroundStyle(viewModel.sortBy == option ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(viewModel.sortBy == option ? Color.accentColor.opacity(0.15) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(viewModel.sortBy == option ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Filter chips - Bigger, more prominent
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "USGA Rated",
                                icon: "star.fill",
                                isSelected: viewModel.filterUSGAOnly,
                                action: viewModel.toggleUSGAFilter
                            )

                            Menu {
                                Button("All Countries") {
                                    viewModel.filterCountry = nil
                                }

                                Divider()

                                ForEach(viewModel.availableCountries, id: \.self) { country in
                                    Button(country) {
                                        viewModel.filterCountry = country
                                    }
                                }
                            } label: {
                                FilterChip(
                                    title: viewModel.filterCountry ?? "All Countries",
                                    icon: "globe",
                                    isSelected: viewModel.filterCountry != nil,
                                    action: {}
                                )
                            }

                            if viewModel.filterUSGAOnly || viewModel.filterCountry != nil {
                                Button(action: viewModel.clearFilters) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Clear")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)

                    // Stats - Clean, subtle, not overlaying content
                    if !viewModel.filteredCourses.isEmpty {
                        Text(viewModel.stats)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                    }
                }
                .background(Color(.systemBackground))

                Divider()

                // Courses list - Beautiful, spacious course rows
                List {
                    ForEach(viewModel.filteredCourses) { course in
                        NavigationLink(destination: CourseDetailView(course: course)) {
                            CourseRow(course: course)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.refresh()
                }
                .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search courses")
            }
            .navigationTitle("Courses")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Course Row - Redesigned for beauty and clarity

struct CourseRow: View {
    let course: Course

    var body: some View {
        HStack(spacing: 16) {
            // Course info - Prominent and clear
            VStack(alignment: .leading, spacing: 6) {
                // Name with USGA badge
                HStack(spacing: 8) {
                    Text(course.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if course.hasUSGARating {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.yellow)
                    }
                }

                // Location
                Text(course.displayLocation)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Stats row - Clean and compact
                HStack(spacing: 8) {
                    // Rounds
                    HStack(spacing: 3) {
                        Image(systemName: "figure.golf")
                            .font(.system(size: 10))
                        Text("\(course.roundCount)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    // Tournaments
                    HStack(spacing: 3) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                        Text("\(course.tournamentCount)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)

                    if let par = course.par {
                        Text("•")
                            .foregroundStyle(.secondary)
                            .font(.caption)

                        Text("Par \(par)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Difficulty badge - THE STAR OF THE SHOW for USGA courses
            if course.hasUSGARating, let slope = course.slope {
                VStack(spacing: 4) {
                    // Slope rating - Large and prominent
                    Text("\(slope)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(slopeColor(for: slope))
                        .monospacedDigit()

                    // Difficulty label
                    Text(course.difficultyLevel.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(slopeColor(for: slope))
                        .tracking(0.5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(slopeColor(for: slope).opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(slopeColor(for: slope).opacity(0.3), lineWidth: 1.5)
                )
            }
        }
        .padding(.vertical, 12)
    }

    // Color coding for slope difficulty
    private func slopeColor(for slope: Int) -> Color {
        switch slope {
        case ..<113: return .green
        case 113..<125: return .blue
        case 125..<135: return .orange
        case 135...: return .red
        default: return .secondary
        }
    }
}

// MARK: - Filter Chip - Enhanced with icons

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CoursesView()
}
