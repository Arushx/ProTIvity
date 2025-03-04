import SwiftUI

struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var workspaceManager: WorkspaceManager
    var workspace: Workspace
    
    @State private var title = ""
    @State private var category = ""
    @State private var priority: Task.Priority = .medium
    @State private var dueDate = Date()
    @State private var notes = ""
    @State private var showDueDate = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $category) {
                        ForEach(workspace.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    
                    Toggle("Set Due Date", isOn: $showDueDate)
                    
                    if showDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveTask()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty || category.isEmpty)
            )
            .onAppear {
                if !workspace.categories.isEmpty {
                    category = workspace.categories[0]
                }
            }
        }
    }
    
    private func saveTask() {
        let task = Task(
            title: title,
            isCompleted: false,
            category: category,
            priority: priority,
            dueDate: showDueDate ? dueDate : nil,
            notes: notes
        )
        
        workspaceManager.addTask(task, to: workspace)
    }
}
