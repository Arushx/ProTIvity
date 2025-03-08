import SwiftUI

struct MainTasksView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var showingAddTask = false
    @State private var showingGanttChart = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    
    enum TaskFilter {
        case all, today, upcoming, completed
        
        var title: String {
            switch self {
            case .all: return "All"
            case .today: return "Today"
            case .upcoming: return "Upcoming"
            case .completed: return "Completed"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "calendar"
            case .upcoming: return "calendar.badge.clock"
            case .completed: return "checkmark.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search tasks...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([TaskFilter.all, .today, .upcoming, .completed], id: \.self) { filter in
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
            
            // Tasks list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task, taskManager: taskManager)
                    }
                }
                .padding()
            }
            .overlay(Group {
                if filteredTasks.isEmpty {
                    SharedEmptyStateView(
                        iconName: emptyStateIcon,
                        message: emptyStateMessage,
                        buttonTitle: "Add Task",
                        buttonAction: { showingAddTask = true }
                    )
                }
            })
        }
        .navigationTitle("Tasks")
        .navigationBarItems(
            trailing: HStack(spacing: 16) {
                Button(action: {
                    showingGanttChart = true
                }) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Button(action: {
                    showingAddTask = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        )
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager)
        }
        .sheet(isPresented: $showingGanttChart) {
            GanttChartView(taskManager: taskManager)
        }
    }
    
    private var filteredTasks: [Task] {
        var tasks = taskManager.tasks
        
        // Apply search filter
        if !searchText.isEmpty {
            tasks = tasks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply task filter
        switch selectedFilter {
        case .all:
            return tasks
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            return tasks.filter { task in
                if let dueDate = task.dueDate {
                    return Calendar.current.isDate(dueDate, inSameDayAs: today)
                }
                return false
            }
        case .upcoming:
            let today = Calendar.current.startOfDay(for: Date())
            return tasks.filter { task in
                if let dueDate = task.dueDate {
                    return dueDate > today && !Calendar.current.isDate(dueDate, inSameDayAs: today)
                }
                return false
            }
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "checklist"
        case .today: return "calendar"
        case .upcoming: return "calendar.badge.clock"
        case .completed: return "checkmark.circle"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "No tasks match your search for '\(searchText)'"
        }
        
        switch selectedFilter {
        case .all:
            return "You don't have any tasks yet.\nAdd your first task to get started!"
        case .today:
            return "No tasks due today.\nEnjoy your free time!"
        case .upcoming:
            return "No upcoming tasks.\nYour schedule is clear!"
        case .completed:
            return "No completed tasks yet.\nComplete a task to see it here!"
        }
    }
}
