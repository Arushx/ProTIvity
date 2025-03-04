import Foundation
import SwiftUI

struct GoalsView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    @State private var showingAddGoal = false
    @State private var selectedFilter: GoalFilter = .all
    @State private var searchText = ""
    @State private var refreshID = UUID()
    
    enum GoalFilter {
        case all, active, completed, upcoming
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search goals...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemBackground))
            
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    GoalFilterButton(title: "All", icon: "list.bullet", isSelected: selectedFilter == .all) {
                        selectedFilter = .all
                    }
                    
                    GoalFilterButton(title: "Active", icon: "circle", isSelected: selectedFilter == .active) {
                        selectedFilter = .active
                    }
                    
                    GoalFilterButton(title: "Upcoming", icon: "calendar", isSelected: selectedFilter == .upcoming) {
                        selectedFilter = .upcoming
                    }
                    
                    GoalFilterButton(title: "Completed", icon: "checkmark.circle.fill", isSelected: selectedFilter == .completed) {
                        selectedFilter = .completed
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            if let workspace = workspaceManager.selectedWorkspace {
                let goals = filteredGoals(in: workspace)
                
                if goals.isEmpty {
                    // Empty state view
                    Spacer()
                    EmptyStateView(filter: selectedFilter, showAddGoal: $showingAddGoal)
                    Spacer()
                } else {
                    // Goals list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(goals) { goal in
                                GoalCard(goal: goal, workspace: workspace, workspaceManager: workspaceManager)
                                    .id("\(goal.id)-\(refreshID)")
                            }
                        }
                        .padding()
                    }
                }
            } else {
                // No workspace selected
                Spacer()
                WorkspacePrompt(workspaceManager: workspaceManager)
                Spacer()
            }
        }
        .navigationTitle("Goals")
        .navigationBarItems(trailing: Button(action: {
            showingAddGoal = true
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView(workspaceManager: workspaceManager)
        }
        .onAppear {
            workspaceManager.loadFromUserDefaults()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkspaceDataChanged"))) { _ in
            refreshID = UUID()
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    private func filteredGoals(in workspace: Workspace) -> [Goal] {
        var goals = workspace.goals
        
        // Apply search filter
        if !searchText.isEmpty {
            goals = goals.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply goal filter
        switch selectedFilter {
        case .all:
            return goals
        case .active:
            return goals.filter { !$0.isCompleted }
        case .completed:
            return goals.filter { $0.isCompleted }
        case .upcoming:
            let today = Calendar.current.startOfDay(for: Date())
            return goals.filter { goal in
                if let deadline = goal.deadline {
                    return deadline > today && !goal.isCompleted
                }
                return false
            }
        }
    }
}

struct GoalFilterButton: View {
    var title: String
    var icon: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
    }
}

struct EmptyStateView: View {
    var filter: GoalsView.GoalFilter
    @Binding var showAddGoal: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.6))
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showAddGoal = true
            }) {
                Text("Add Goal")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    var iconName: String {
        switch filter {
        case .all: return "target"
        case .active: return "circle"
        case .completed: return "checkmark.circle"
        case .upcoming: return "calendar"
        }
    }
    
    var message: String {
        switch filter {
        case .all:
            return "You don't have any goals yet.\nAdd your first goal to get started!"
        case .active:
            return "You don't have any active goals.\nAll your goals are completed!"
        case .completed:
            return "You don't have any completed goals yet.\nComplete a goal to see it here!"
        case .upcoming:
            return "You don't have any upcoming goals.\nAdd a goal with a future deadline!"
        }
    }
}

struct GoalCard: View {
    var goal: Goal
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    toggleCompletion()
                }) {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(goal.isCompleted ? .green : .gray)
                }
                
                Text(goal.title)
                    .font(.headline)
                    .strikethrough(goal.isCompleted)
                    .foregroundColor(goal.isCompleted ? .secondary : .primary)
                
                Spacer()
                
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            if !goal.description.isEmpty {
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if let deadline = goal.deadline {
                HStack {
                    Image(systemName: "calendar")
                    Text("Due: \(deadline, style: .date)")
                        .font(.caption)
                    
                    if deadline < Date() && !goal.isCompleted {
                        Text("OVERDUE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingEditSheet) {
            EditGoalView(goal: goal, workspace: workspace, workspaceManager: workspaceManager)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Goal"),
                message: Text("Are you sure you want to delete '\(goal.title)'?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteGoal()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func toggleCompletion() {
        if let workspaceIndex = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }),
           let goalIndex = workspaceManager.workspaces[workspaceIndex].goals.firstIndex(where: { $0.id == goal.id }) {
            workspaceManager.workspaces[workspaceIndex].goals[goalIndex].isCompleted.toggle()
            workspaceManager.saveToUserDefaults()
            workspaceManager.forceSaveAndUpdate()
        }
    }
    
    private func deleteGoal() {
        if let workspaceIndex = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaceManager.workspaces[workspaceIndex].goals.removeAll(where: { $0.id == goal.id })
            workspaceManager.saveToUserDefaults()
            workspaceManager.forceSaveAndUpdate()
        }
    }
}

struct WorkspacePrompt: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Select a Workspace")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please select a workspace to view and manage goals")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(workspaceManager.workspaces) { workspace in
                        Button(action: {
                            workspaceManager.selectedWorkspace = workspace
                            workspaceManager.saveToUserDefaults()
                        }) {
                            HStack {
                                Image(systemName: workspace.icon)
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(workspace.color)
                                    .cornerRadius(10)
                                
                                VStack(alignment: .leading) {
                                    Text(workspace.name)
                                        .font(.headline)
                                    
                                    Text("\(workspace.goals.count) goals, \(workspace.tasks.count) tasks")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

struct AddGoalView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Title", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description (optional)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                    
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveGoal()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveGoal() {
        guard let workspace = workspaceManager.selectedWorkspace, !title.isEmpty else { return }
        
        let newGoal = Goal(
            title: title,
            description: description,
            deadline: hasDeadline ? deadline : nil
        )
        
        if let index = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaceManager.workspaces[index].goals.append(newGoal)
            workspaceManager.saveToUserDefaults()
            workspaceManager.forceSaveAndUpdate()
            
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditGoalView: View {
    var goal: Goal
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var isCompleted: Bool
    
    init(goal: Goal, workspace: Workspace, workspaceManager: WorkspaceManager) {
        self.goal = goal
        self.workspace = workspace
        self.workspaceManager = workspaceManager
        
        _title = State(initialValue: goal.title)
        _description = State(initialValue: goal.description)
        _hasDeadline = State(initialValue: goal.deadline != nil)
        _deadline = State(initialValue: goal.deadline ?? Date())
        _isCompleted = State(initialValue: goal.isCompleted)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Title", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description (optional)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                    
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                    }
                    
                    Toggle("Completed", isOn: $isCompleted)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    updateGoal()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func updateGoal() {
        guard !title.isEmpty else { return }
        
        var updatedGoal = goal
        updatedGoal.title = title
        updatedGoal.description = description
        updatedGoal.deadline = hasDeadline ? deadline : nil
        updatedGoal.isCompleted = isCompleted
        
        if let workspaceIndex = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }),
           let goalIndex = workspaceManager.workspaces[workspaceIndex].goals.firstIndex(where: { $0.id == goal.id }) {
            workspaceManager.workspaces[workspaceIndex].goals[goalIndex] = updatedGoal
            workspaceManager.saveToUserDefaults()
            workspaceManager.forceSaveAndUpdate()
            
            presentationMode.wrappedValue.dismiss()
        }
    }
}
