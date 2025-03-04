import SwiftUI

struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var workspaceManager = WorkspaceManager()
    @State private var selectedTab = 0
    @State private var selectedWorkspace: Workspace? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tasks Tab
            NavigationView {
                TasksView(
                    taskManager: taskManager,
                    workspaceManager: workspaceManager,
                    workspace: workspaceManager.workspaces.first ?? Workspace(name: "Personal", icon: "person.fill", color: .blue, categories: ["Personal", "Health", "Shopping"])
                )
            }
            .tabItem {
                Label("Tasks", systemImage: "checklist")
            }
            .tag(0)
            
            // Goals Tab
            NavigationView {
                MainGoalsTabView(workspaceManager: workspaceManager)
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(1)
            
            // Journal Tab
            NavigationView {
                JournalTabView()
            }
            .tabItem {
                Label("Journal", systemImage: "book")
            }
            .tag(2)
            
            // Workspaces Tab
            NavigationView {
                WorkspaceListView(workspaceManager: workspaceManager, taskManager: taskManager, selectedWorkspace: $selectedWorkspace)
                if let workspace = selectedWorkspace {
                    WorkspaceDetailView(workspace: workspace, workspaceManager: workspaceManager, taskManager: taskManager)
                } else {
                    Text("Select a workspace or create a new one")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .tabItem {
                Label("Workspaces", systemImage: "folder")
            }
            .tag(3)
        }
    }
}
