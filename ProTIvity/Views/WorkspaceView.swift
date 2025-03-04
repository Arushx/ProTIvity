import SwiftUI

struct WorkspaceView: View {
    var workspace: Workspace
    @ObservedObject var workspaceManager: WorkspaceManager
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            // Workspace header
            HStack {
                Image(systemName: workspace.icon)
                    .foregroundColor(workspace.color)
                    .font(.largeTitle)
                Text(workspace.name)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            // Tab view for different sections
            TabView(selection: $selectedTab) {
                // Tasks tab
                TasksListView(workspace: workspace, workspaceManager: workspaceManager)
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                    .tag(0)
                
                // Goals tab
                GoalsListView(workspace: workspace, workspaceManager: workspaceManager)
                    .tabItem {
                        Label("Goals", systemImage: "target")
                    }
                    .tag(1)
                
                // Pages tab
                WorkspacePagesView(workspace: workspace, workspaceManager: workspaceManager)
                    .tabItem {
                        Label("Pages", systemImage: "doc.text")
                    }
                    .tag(2)
            }
        }
    }
}

// Tasks list view
struct TasksListView: View {
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    @State private var showingAddTask = false
    
    var body: some View {
        List {
            ForEach(workspace.tasks) { task in
                TaskRowView(task: task, onToggle: { isCompleted in
                    var updatedTask = task
                    updatedTask.isCompleted = isCompleted
                    workspaceManager.updateTask(updatedTask, in: workspace)
                }, onDelete: {
                    workspaceManager.deleteTask(task, from: workspace)
                })
            }
            
            Button(action: {
                showingAddTask = true
            }) {
                Label("Add Task", systemImage: "plus")
            }
        }
        .navigationTitle("Tasks")
    }
}

// Goals list view
struct GoalsListView: View {
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    @State private var showingAddGoal = false
    
    var body: some View {
        List {
            ForEach(workspace.goals) { goal in
                GoalRowView(goal: goal, workspace: workspace, workspaceManager: workspaceManager)
            }
            
            Button(action: {
                showingAddGoal = true
            }) {
                Label("Add Goal", systemImage: "plus")
            }
        }
        .navigationTitle("Goals")
    }
}

// Pages view
struct WorkspacePagesView: View {
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    @State private var showingAddPage = false
    @State private var newPageTitle = ""
    
    var body: some View {
        List {
            ForEach(workspace.pages) { page in
                NavigationLink(destination: PageContentEditorView(page: page, workspace: workspace, workspaceManager: workspaceManager)) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(workspace.color)
                        VStack(alignment: .leading) {
                            Text(page.title)
                                .font(.headline)
                            Text("Modified: \(page.dateModified, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Button(action: {
                showingAddPage = true
            }) {
                Label("Add Page", systemImage: "plus")
            }
        }
        .navigationTitle("Pages")
        .alert("New Page", isPresented: $showingAddPage) {
            TextField("Page Title", text: $newPageTitle)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                if !newPageTitle.isEmpty {
                    let newPage = Page(title: newPageTitle)
                    workspaceManager.addPage(newPage, to: workspace)
                    newPageTitle = ""
                }
            }
        }
    }
}
