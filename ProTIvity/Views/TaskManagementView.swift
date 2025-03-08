import SwiftUI

struct TaskManagementView: View {
    let goal: Goal
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var goalManager: GoalManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    
    enum TaskFilter {
        case all, active, completed, recurring
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Goal Progress
                let progress = calculateProgress()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Goal Progress")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 8)
                                .opacity(0.3)
                                .foregroundColor(Color(.systemGray4))
                            
                            Rectangle()
                                .frame(width: geometry.size.width * progress, height: 8)
                                .foregroundColor(.blue)
                        }
                        .cornerRadius(4)
                    }
                    .frame(height: 8)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SharedFilterButton(title: "All", icon: "list.bullet", isSelected: selectedFilter == .all) {
                            selectedFilter = .all
                        }
                        
                        SharedFilterButton(title: "Active", icon: "circle", isSelected: selectedFilter == .active) {
                            selectedFilter = .active
                        }
                        
                        SharedFilterButton(title: "Completed", icon: "checkmark.circle.fill", isSelected: selectedFilter == .completed) {
                            selectedFilter = .completed
                        }
                        
                        SharedFilterButton(title: "Recurring", icon: "arrow.triangle.2.circlepath", isSelected: selectedFilter == .recurring) {
                            selectedFilter = .recurring
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Tasks list
                let filteredTasks = filterTasks(goalTasks)
                
                if filteredTasks.isEmpty {
                    SharedEmptyStateView(
                        iconName: emptyStateIcon,
                        message: emptyStateMessage,
                        buttonTitle: "Add Task",
                        buttonAction: { showingAddTask = true }
                    )
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task, taskManager: taskManager)
                        }
                    }
                }
            }
            .navigationTitle("Tasks for \(goal.title)")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    showingAddTask = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(
                    taskManager: taskManager,
                    goalId: goal.id
                )
            }
        }
    }
    
    private var goalTasks: [Task] {
        goal.tasks.compactMap { taskId in
            taskManager.tasks.first { $0.id == taskId }
        }
    }
    
    private func calculateProgress() -> Double {
        let tasks = goalTasks
        guard !tasks.isEmpty else { return 0.0 }
        let completedTasks = tasks.filter { $0.isCompleted }
        return Double(completedTasks.count) / Double(tasks.count)
    }
    
    private func filterTasks(_ tasks: [Task]) -> [Task] {
        switch selectedFilter {
        case .all:
            return tasks
        case .active:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter { $0.isCompleted }
        case .recurring:
            return tasks.filter { $0.isRecurring }
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "checklist"
        case .active: return "circle"
        case .completed: return "checkmark.circle"
        case .recurring: return "arrow.triangle.2.circlepath"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "No tasks yet.\nAdd your first task to get started!"
        case .active:
            return "No active tasks.\nAll tasks are completed!"
        case .completed:
            return "No completed tasks yet.\nComplete a task to see it here!"
        case .recurring:
            return "No recurring tasks.\nAdd a recurring task to see it here!"
        }
    }
}
