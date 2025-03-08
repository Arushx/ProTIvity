import SwiftUI

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var goalManager = GoalManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tasks Tab
            NavigationView {
                MainTasksView(taskManager: taskManager)
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(0)
            
            // Goals Tab
            NavigationView {
                GoalsView()
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(1)
        }
    }
}
