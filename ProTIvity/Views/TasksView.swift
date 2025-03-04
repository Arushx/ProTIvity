import Foundation
import SwiftUI

struct TasksView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var workspaceManager: WorkspaceManager
    var workspace: Workspace
    
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var refreshID = UUID() // Force refresh mechanism
    
    enum TaskFilter {
        case all, today, upcoming, completed
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
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
                .background(Color(.systemBackground))
                
                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(title: "All", systemImage: "list.bullet", isSelected: selectedFilter == .all) {
                            selectedFilter = .all
                        }
                        
                        FilterButton(title: "Today", systemImage: "calendar", isSelected: selectedFilter == .today) {
                            selectedFilter = .today
                        }
                        
                        FilterButton(title: "Upcoming", systemImage: "calendar.badge.clock", isSelected: selectedFilter == .upcoming) {
                            selectedFilter = .upcoming
                        }
                        
                        FilterButton(title: "Completed", systemImage: "checkmark.circle", isSelected: selectedFilter == .completed) {
                            selectedFilter = .completed
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                
                // Category filter
                if !workspace.categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryButton(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            
                            ForEach(workspace.categories, id: \.self) { category in
                                CategoryButton(title: category, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                }
                
                // Task list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            EnhancedTaskRowView(task: task, workspace: workspace, workspaceManager: workspaceManager)
                                .id("\(task.id)-\(refreshID)")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .overlay(
                    Group {
                        if filteredTasks.isEmpty {
                            EmptyTasksView(filter: selectedFilter, category: selectedCategory, searchText: searchText, showingAddTask: $showingAddTask)
                        }
                    }
                )
                .onAppear {
                    // Load data from UserDefaults when view appears
                    workspaceManager.loadFromUserDefaults()
                    print("📋 TasksView appeared - Loaded \(workspace.tasks.count) tasks")
                }
            }
        }
        .navigationTitle("Tasks")
        .navigationBarItems(
            trailing: Button(action: {
                showingAddTask = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
            }
        )
        .sheet(isPresented: $showingAddTask) {
            EnhancedAddTaskView(taskManager: taskManager, workspaceManager: workspaceManager, workspace: workspace)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkspaceDataChanged"))) { _ in
            // Force UI update when data changes
            refreshID = UUID()
            print("🔄 TasksView received data change notification - Refreshing UI")
        }
    }
    
    var filteredTasks: [Task] {
        var tasks = workspace.tasks
        
        // Apply search filter
        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) || 
                                  $0.notes.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            tasks = tasks.filter { $0.category == category }
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
}

struct EmptyTasksView: View {
    var filter: TasksView.TaskFilter
    var category: String?
    var searchText: String
    @Binding var showingAddTask: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyStateIcon())
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.6))
            
            Text(emptyStateMessage())
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if !searchText.isEmpty {
                Button(action: {
                    // This would clear the search text, but we can't directly modify it here
                    // You'd need to pass a binding to implement this
                }) {
                    Text("Clear Search")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
            } else {
                Button(action: {
                    showingAddTask = true
                }) {
                    Text("Add Your First Task")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding()
    }
    
    private func emptyStateIcon() -> String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        
        switch filter {
        case .all: return "checklist"
        case .today: return "calendar"
        case .upcoming: return "calendar.badge.clock"
        case .completed: return "checkmark.circle"
        }
    }
    
    private func emptyStateMessage() -> String {
        if !searchText.isEmpty {
            return "No tasks match your search for '\(searchText)'"
        }
        
        let categoryText = category != nil ? " in the '\(category!)' category" : ""
        
        switch filter {
        case .all:
            return "You don't have any tasks\(categoryText) yet.\nAdd your first task to get started!"
        case .today:
            return "No tasks due today\(categoryText).\nEnjoy your free time!"
        case .upcoming:
            return "No upcoming tasks\(categoryText).\nYour schedule is clear!"
        case .completed:
            return "No completed tasks\(categoryText) yet.\nComplete a task to see it here!"
        }
    }
}

struct FilterButton: View {
    var title: String
    var systemImage: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 3, x: 0, y: 2)
        }
    }
}

struct CategoryButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(8)
        }
    }
}

struct EnhancedTaskRowView: View {
    var task: Task
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button(action: {
                    // Use the enhanced method for better persistence
                    toggleTaskCompletion()
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    HStack {
                        Text(task.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(categoryColor(for: task.category).opacity(0.2))
                            .foregroundColor(categoryColor(for: task.category))
                            .cornerRadius(4)
                        
                        priorityView(for: task.priority)
                    }
                    
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }
                
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
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            if let dueDate = task.dueDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    
                    let isPastDue = dueDate < Date() && !task.isCompleted
                    
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(isPastDue ? .red : .secondary)
                    
                    if isPastDue {
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
                .padding(.top, 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .sheet(isPresented: $showingEditSheet) {
            EnhancedEditTaskView(task: task, workspace: workspace, workspaceManager: workspaceManager)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Task"),
                message: Text("Are you sure you want to delete '\(task.title)'? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteTask()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func toggleTaskCompletion() {
        // Find the workspace index
        if let workspaceIndex = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Find the task index
            if let taskIndex = workspaceManager.workspaces[workspaceIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                // Toggle completion
                var updatedTask = workspaceManager.workspaces[workspaceIndex].tasks[taskIndex]
                updatedTask.isCompleted.toggle()
                workspaceManager.workspaces[workspaceIndex].tasks[taskIndex] = updatedTask
                
                // Force save and update
                workspaceManager.saveToUserDefaults()
                workspaceManager.forceSaveAndUpdate()
                
                print("✅ Task completion toggled: \(task.title) - \(updatedTask.isCompleted ? "COMPLETED" : "NOT COMPLETED")")
            }
        }
    }
    
    private func deleteTask() {
        // Find the workspace index
        if let workspaceIndex = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Remove the task
            workspaceManager.workspaces[workspaceIndex].tasks.removeAll(where: { $0.id == task.id })
            
            // Force save and update
            workspaceManager.saveToUserDefaults()
            workspaceManager.forceSaveAndUpdate()
            
            print("🗑️ Task deleted: \(task.title)")
        }
    }
    
    private func priorityView(for priority: Task.Priority) -> some View {
        let color: Color
        switch priority {
        case .low:
            color = .blue
        case .medium:
            color = .orange
        case .high:
            color = .red
        }
        
        return Text(priority.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "work": return .blue
        case "personal": return .green
        case "shopping": return .orange
        case "health": return .red
        case "admin", "administration": return .purple
        case "meeting", "meetings": return .pink
        case "project", "projects": return .yellow
        case "learning", "education": return .teal
        case "finance", "financial": return .green
        case "home": return .brown
        default:
            // Generate a consistent color based on the category name
            let hash = abs(category.hashValue)
            let hue = Double(hash % 360) / 360.0
            return Color(hue: hue, saturation: 0.7, brightness: 0.9)
        }
    }
}

struct EnhancedAddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var workspaceManager: WorkspaceManager
    var workspace: Workspace
    
    @State private var title = ""
    @State private var category = ""
    @State private var priority: Task.Priority = .medium
    @State private var dueDate = Date()
    @State private var notes = ""
    @State private var showDueDate = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                        .font(.headline)
                    
                    Picker("Category", selection: $category) {
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(for: priority))
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Set Due Date", isOn: $showDueDate)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if showDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Notes")) {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add notes here...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .opacity(notes.isEmpty ? 0.25 : 1)
                    }
                }
                
                Section {
                    Button(action: saveTask) {
                        HStack {
                            Spacer()
                            
                            if isSaving {
                                ProgressView()
                                    .padding(.trailing, 10)
                            }
                            
                            Text(isSaving ? "Saving..." : "Save Task")
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty || category.isEmpty || isSaving)
                    .foregroundColor(title.isEmpty || category.isEmpty || isSaving ? .gray : .blue)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                if !availableCategories.isEmpty && category.isEmpty {
                    category = availableCategories[0]
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Task Added"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private var availableCategories: [String] {
        if workspace.categories.isEmpty {
            return ["General"]
        } else {
            return workspace.categories
        }
    }
    
    private func saveTask() {
        guard !title.isEmpty && !category.isEmpty else { return }
        
        isSaving = true
        
        let task = Task(
            title: title,
            isCompleted: false,
            category: category,
            priority: priority,
            dueDate: showDueDate ? dueDate : nil,
            notes: notes
        )
        
        // Find the workspace index
        if let workspaceIndex = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Ensure the workspace has the category
            if !workspaceManager.workspaces[workspaceIndex].categories.contains(category) {
                workspaceManager.workspaces[workspaceIndex].categories.append(category)
            }
            
            // Add the task
            workspaceManager.workspaces[workspaceIndex].tasks.append(task)
            
            // Force save and update
            workspaceManager.saveToUserDefaults()
            workspaceManager.forceSaveAndUpdate()
            
            print("✅ Task added: \(title)")
            
            // Show confirmation and dismiss
            alertMessage = "'\(title)' has been added to your tasks."
            
            // Simulate network delay for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSaving = false
                showAlert = true
            }
        }
    }
    
    private func priorityColor(for priority: Task.Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct EnhancedEditTaskView: View {
    var task: Task
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    
    @State private var title: String
    @State private var category: String
    @State private var priority: Task.Priority
    @State private var dueDate: Date
    @State private var notes: String
    @State private var showDueDate: Bool
    @State private var isCompleted: Bool
    @State private var showAlert = false
    @State private var isSaving = false
    
    @Environment(\.presentationMode) var presentationMode
    
    init(task: Task, workspace: Workspace, workspaceManager: WorkspaceManager) {
        self.task = task
        self.workspace = workspace
        self.workspaceManager = workspaceManager
        
        _title = State(initialValue: task.title)
        _category = State(initialValue: task.category)
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _notes = State(initialValue: task.notes)
        _showDueDate = State(initialValue: task.dueDate != nil)
        _isCompleted = State(initialValue: task.isCompleted)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                        .font(.headline)
                    
                    Picker("Category", selection: $category) {
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(for: priority))
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Set Due Date", isOn: $showDueDate)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if showDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                    
                    Toggle("Completed", isOn: $isCompleted)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }
                
                Section(header: Text("Notes")) {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add notes here...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .opacity(notes.isEmpty ? 0.25 : 1)
                    }
                }
                
                Section {
                    Button(action: updateTask) {
                        HStack {
                            Spacer()
                            
                            if isSaving {
                                ProgressView()
                                    .padding(.trailing, 10)
                            }
                            
                            Text(isSaving ? "Saving..." : "Save Changes")
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                    .foregroundColor(title.isEmpty || isSaving ? .gray : .blue)
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Task Updated"),
                    message: Text("Your task has been updated successfully."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private var availableCategories: [String] {
        if workspace.categories.isEmpty {
            return ["General"]
        } else {
            return workspace.categories
        }
    }
    
    private func updateTask() {
        guard !title.isEmpty else { return }
        
        isSaving = true
        
        var updatedTask = task
        updatedTask.title = title
        updatedTask.category = category
        updatedTask.priority = priority
        updatedTask.dueDate = showDueDate ? dueDate : nil
        updatedTask.notes = notes
        updatedTask.isCompleted = isCompleted
        
        // Find the workspace index
        if let workspaceIndex = workspaceManager.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Ensure the workspace has the category
            if !workspaceManager.workspaces[workspaceIndex].categories.contains(category) {
                workspaceManager.workspaces[workspaceIndex].categories.append(category)
            }
            
            // Find the task index
            if let taskIndex = workspaceManager.workspaces[workspaceIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                // Update the task
                workspaceManager.workspaces[workspaceIndex].tasks[taskIndex] = updatedTask
                
                // Force save and update
                workspaceManager.saveToUserDefaults()
                workspaceManager.forceSaveAndUpdate()
                
                print("✅ Task updated: \(updatedTask.title)")
            }
        }
        
        // Simulate network delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            showAlert = true
        }
    }
    
    private func priorityColor(for priority: Task.Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}
