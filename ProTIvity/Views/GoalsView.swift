import SwiftUI

struct GoalsView: View {
    @StateObject private var goalManager = GoalManager()
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddGoal = false
    @State private var selectedFilter: GoalFilter = .all
    @State private var searchText = ""
    
    enum GoalFilter {
        case all, active, completed, upcoming
        
        var title: String {
            switch self {
            case .all: return "All"
            case .active: return "Active"
            case .completed: return "Completed"
            case .upcoming: return "Upcoming"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .active: return "circle"
            case .completed: return "checkmark.circle.fill"
            case .upcoming: return "calendar"
            }
        }
    }
    
    var body: some View {
        NavigationView {
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
                
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach([GoalFilter.all, .active, .upcoming, .completed], id: \.self) { filter in
                            SharedFilterButton(
                                title: filter.title,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Goals list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredGoals) { goal in
                            GoalCard(goal: goal, goalManager: goalManager, taskManager: taskManager)
                        }
                    }
                    .padding()
                }
                .overlay(Group {
                    if filteredGoals.isEmpty {
                        SharedEmptyStateView(
                            iconName: emptyStateIcon,
                            message: emptyStateMessage,
                            buttonTitle: "Add Goal",
                            buttonAction: { showingAddGoal = true }
                        )
                    }
                })
            }
            .navigationTitle("Goals")
            .navigationBarItems(trailing: Button(action: {
                showingAddGoal = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(goalManager: goalManager)
            }
        }
    }
    
    private var filteredGoals: [Goal] {
        var goals = goalManager.goals
        
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
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "target"
        case .active: return "circle"
        case .completed: return "checkmark.circle"
        case .upcoming: return "calendar"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "No goals match your search for '\(searchText)'"
        }
        
        switch selectedFilter {
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
    let goal: Goal
    @ObservedObject var goalManager: GoalManager
    @ObservedObject var taskManager: TaskManager
    @State private var showingTaskManagement = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Button(action: {
                    goalManager.toggleGoalCompletion(goal)
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
            
            // Task Progress
            let goalTasks = goal.tasks.compactMap { taskId in
                taskManager.tasks.first { $0.id == taskId }
            }
            let completedTasks = goalTasks.filter { $0.isCompleted }
            let progress = goalTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(goalTasks.count)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(completedTasks.count)/\(goalTasks.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 6)
                            .opacity(0.3)
                            .foregroundColor(Color(.systemGray4))
                        
                        Rectangle()
                            .frame(width: geometry.size.width * progress, height: 6)
                            .foregroundColor(.blue)
                    }
                    .cornerRadius(3)
                }
                .frame(height: 6)
            }
            
            // Tasks Button
            Button(action: {
                showingTaskManagement = true
            }) {
                HStack {
                    Image(systemName: "checklist")
                    Text("Manage Tasks")
                }
                .font(.caption)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(6)
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
        .sheet(isPresented: $showingTaskManagement) {
            TaskManagementView(
                goal: goal,
                taskManager: taskManager,
                goalManager: goalManager
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            EditGoalView(goal: goal, goalManager: goalManager)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Goal"),
                message: Text("Are you sure you want to delete '\(goal.title)'?"),
                primaryButton: .destructive(Text("Delete")) {
                    goalManager.deleteGoal(goal)
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct AddGoalView: View {
    @ObservedObject var goalManager: GoalManager
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
        let newGoal = Goal(
            title: title,
            description: description,
            deadline: hasDeadline ? deadline : nil
        )
        
        goalManager.addGoal(newGoal)
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditGoalView: View {
    let goal: Goal
    @ObservedObject var goalManager: GoalManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String
    @State private var description: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var isCompleted: Bool
    
    init(goal: Goal, goalManager: GoalManager) {
        self.goal = goal
        self.goalManager = goalManager
        
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
        var updatedGoal = goal
        updatedGoal.title = title
        updatedGoal.description = description
        updatedGoal.deadline = hasDeadline ? deadline : nil
        updatedGoal.isCompleted = isCompleted
        
        goalManager.updateGoal(updatedGoal)
        presentationMode.wrappedValue.dismiss()
    }
}
