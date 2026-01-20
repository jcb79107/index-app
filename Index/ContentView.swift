import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {

            PlayersView()
                .tabItem {
                    Label("Players", systemImage: "person.3.fill")
                }

            CoursesView()
                .tabItem {
                    Label("Courses", systemImage: "flag.fill")
                }

            TrendsView()
                .tabItem {
                    Label("Trends", systemImage: "chart.xyaxis.line")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}

