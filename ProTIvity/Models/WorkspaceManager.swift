import Foundation
import SwiftUI
import Combine

class WorkspaceManager: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var selectedWorkspace: Workspace?
    @Published var selectedPage: Page?
    
    private let saveKey = "workspaces"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadWorkspaces()
        
        // If no workspaces exist, create default ones
        if workspaces.isEmpty {
            createDefaultWorkspaces()
        }
        
        // Set up autosave when workspaces change
        $workspaces
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveWorkspaces()
            }
            .store(in: &cancellables)
    }
    
    private func createDefaultWorkspaces() {
        let personalWorkspace = Workspace(
            name: "Personal",
            icon: "person.fill",
            color: .blue,
            categories: ["Personal", "Health", "Shopping"]
        )
        
        let workWorkspace = Workspace(
            name: "Work",
            icon: "briefcase.fill",
            color: .orange,
            categories: ["Meetings", "Projects", "Admin"]
        )
        
        let studyWorkspace = Workspace(
            name: "Study",
            icon: "book.fill",
            color: .green,
            categories: ["Assignments", "Exams", "Research"]
        )
        
        workspaces = [personalWorkspace, workWorkspace, studyWorkspace]
        selectedWorkspace = personalWorkspace
        saveWorkspaces()
    }
    
    func addWorkspace(_ workspace: Workspace) {
        workspaces.append(workspace)
    }
    
    func updateWorkspace(_ workspace: Workspace) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index] = workspace
        }
    }
    
    func deleteWorkspace(at indexSet: IndexSet) {
        workspaces.remove(atOffsets: indexSet)
    }
    
    func deleteWorkspace(_ workspace: Workspace) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces.remove(at: index)
            
            if selectedWorkspace?.id == workspace.id {
                selectedWorkspace = workspaces.first
                selectedPage = nil
            }
        }
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task, to workspace: Workspace) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index].tasks.append(task)
        }
    }
    
    func updateTask(_ task: Task, in workspace: Workspace) {
        if let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspace.id }),
           let taskIndex = workspaces[workspaceIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            workspaces[workspaceIndex].tasks[taskIndex] = task
        }
    }
    
    func deleteTask(_ task: Task, from workspace: Workspace) {
        if let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[workspaceIndex].tasks.removeAll(where: { $0.id == task.id })
        }
    }
    
    // MARK: - Goal Management
    
    func addGoal(_ goal: Goal, to workspace: Workspace) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index].goals.append(goal)
        }
    }
    
    func updateGoal(_ goal: Goal, in workspace: Workspace) {
        if let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspace.id }),
           let goalIndex = workspaces[workspaceIndex].goals.firstIndex(where: { $0.id == goal.id }) {
            workspaces[workspaceIndex].goals[goalIndex] = goal
        }
    }
    
    func deleteGoal(_ goal: Goal, from workspace: Workspace) {
        if let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[workspaceIndex].goals.removeAll(where: { $0.id == goal.id })
        }
    }
    
    // MARK: - Page Management
    
    func addPage(_ page: Page, to workspace: Workspace) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index].pages.append(page)
        }
    }
    
    func updatePage(_ page: Page, in workspace: Workspace) {
        if let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspace.id }),
           let pageIndex = workspaces[workspaceIndex].pages.firstIndex(where: { $0.id == page.id }) {
            workspaces[workspaceIndex].pages[pageIndex] = page
        }
    }
    
    func updatePage(_ page: Page, title: String, content: String) {
        guard let workspaceIndex = workspaces.firstIndex(where: { $0.id == selectedWorkspace?.id }) else { return }
        
        var updatedPage = page
        updatedPage.title = title
        updatedPage.content = content
        updatedPage.dateModified = Date()
        
        if let pageIndex = workspaces[workspaceIndex].pages.firstIndex(where: { $0.id == page.id }) {
            workspaces[workspaceIndex].pages[pageIndex] = updatedPage
        }
        
        if selectedPage?.id == page.id {
            selectedPage = updatedPage
        }
    }
    
    func deletePage(_ page: Page, from workspace: Workspace) {
        if let workspaceIndex = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[workspaceIndex].pages.removeAll(where: { $0.id == page.id })
        }
    }
    
    // MARK: - Workspace Creation
    
    func addWorkspace(name: String, icon: String, color: Color) {
        // Initialize with default categories based on workspace type
        var categories: [String] = []
        switch name.lowercased() {
        case let n where n.contains("work"):
            categories = ["Work", "Meetings", "Projects", "Tasks"]
        case let n where n.contains("study") || n.contains("school"):
            categories = ["Study", "Assignments", "Research", "Exams"]
        case let n where n.contains("personal"):
            categories = ["Personal", "Health", "Shopping", "Goals"]
        default:
            categories = ["General", "Tasks", "Notes"]
        }
        
        let newWorkspace = Workspace(name: name, icon: icon, color: color, categories: categories)
        workspaces.append(newWorkspace)
    }
    
    // MARK: - Category Management
    
    func getCategories(for workspace: Workspace) -> [String] {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            return workspaces[index].categories
        }
        return []
    }
    
    func addCategory(to workspace: Workspace, category: String) {
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }),
           !workspaces[index].categories.contains(category) {
            workspaces[index].categories.append(category)
        }
    }
    
    // MARK: - Persistence
    
    private func saveWorkspaces() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(workspaces)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save workspaces: \(error.localizedDescription)")
        }
    }
    
    private func loadWorkspaces() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            workspaces = try decoder.decode([Workspace].self, from: data)
        } catch {
            print("Failed to load workspaces: \(error.localizedDescription)")
        }
    }
}
