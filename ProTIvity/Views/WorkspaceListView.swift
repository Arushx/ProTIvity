import Foundation
import SwiftUI

struct WorkspaceListView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    @ObservedObject var taskManager: TaskManager
    @Binding var selectedWorkspace: Workspace?
    @State private var showingAddWorkspace = false
    @State private var showingAddPage = false
    @State private var newItemName = ""
    @State private var selectedPageType = PageType.notes
    
    enum PageType: String, CaseIterable {
        case notes = "Notes"
        case tasks = "Tasks"
        case goals = "Goals"
        case journal = "Journal"
        
        var icon: String {
            switch self {
            case .notes: return "doc.text"
            case .tasks: return "checklist"
            case .goals: return "target"
            case .journal: return "book"
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(workspaceManager.workspaces) { workspace in
                WorkspaceSection(
                    workspace: workspace,
                    workspaceManager: workspaceManager,
                    taskManager: taskManager,
                    selectedWorkspace: $selectedWorkspace,
                    showingAddPage: $showingAddPage
                )
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Workspaces")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddWorkspace = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddWorkspace) {
            WorkspaceCreationView(workspaceManager: workspaceManager)
        }
        .alert("New Page", isPresented: $showingAddPage) {
            TextField("Page Title", text: $newItemName)
            Picker("Page Type", selection: $selectedPageType) {
                ForEach(PageType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                if !newItemName.isEmpty, let workspace = workspaceManager.selectedWorkspace {
                    let initialContent = selectedPageType == .tasks || 
                                       selectedPageType == .goals || 
                                       selectedPageType == .journal ? "[]" : ""
                    let newPage = Page(title: newItemName, content: initialContent)
                    workspaceManager.addPage(newPage, to: workspace)
                    newItemName = ""
                }
            }
        }
    }
}

struct WorkspaceSection: View {
    let workspace: Workspace
    @ObservedObject var workspaceManager: WorkspaceManager
    @ObservedObject var taskManager: TaskManager
    @Binding var selectedWorkspace: Workspace?
    @Binding var showingAddPage: Bool
    
    var body: some View {
        Section(header: WorkspaceSectionHeader(
            workspace: workspace,
            workspaceManager: workspaceManager,
            showingAddPage: $showingAddPage
        )) {
            Button(action: {
                selectedWorkspace = workspace
                workspaceManager.selectedWorkspace = workspace
            }) {
                HStack {
                    Image(systemName: workspace.icon)
                        .foregroundColor(workspace.color)
                    Text(workspace.name)
                    Spacer()
                    if selectedWorkspace?.id == workspace.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            ForEach(workspace.pages) { page in
                PageItemView(
                    page: page,
                    workspace: workspace,
                    workspaceManager: workspaceManager,
                    taskManager: taskManager
                )
            }
        }
    }
}

struct WorkspaceSectionHeader: View {
    let workspace: Workspace
    @ObservedObject var workspaceManager: WorkspaceManager
    @Binding var showingAddPage: Bool
    
    var body: some View {
        HStack {
            Image(systemName: workspace.icon)
                .foregroundColor(workspace.color)
            Text(workspace.name)
                .font(.headline)
            Spacer()
            Menu {
                Button(action: {
                    workspaceManager.selectedWorkspace = workspace
                    showingAddPage = true
                }) {
                    Label("Add Page", systemImage: "doc.badge.plus")
                }
                
                Divider()
                
                Button(role: .destructive, action: {
                    workspaceManager.deleteWorkspace(workspace)
                }) {
                    Label("Delete Workspace", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

// Remove duplicate PageItemView and AddWorkspaceView declarations
// They will be defined in separate files
