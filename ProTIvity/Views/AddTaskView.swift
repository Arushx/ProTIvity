import SwiftUI

struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    var goalId: UUID?
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var category = "General"
    @State private var priority: Task.Priority = .medium
    @State private var dueDate = Date()
    @State private var notes = ""
    @State private var showDueDate = false
    @State private var isRecurring = false
    @State private var recurrenceInterval: Task.RecurrenceInterval = .daily
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    TextField("Category", text: $category)
                    
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
                    
                    if showDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                    
                    Toggle("Recurring Task", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Recurrence", selection: $recurrenceInterval) {
                            ForEach(Task.RecurrenceInterval.allCases, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
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
            }
            .navigationTitle("Add Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveTask()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveTask() {
        let task = Task(
            title: title,
            isCompleted: false,
            category: category,
            priority: priority,
            dueDate: showDueDate ? dueDate : nil,
            notes: notes,
            isRecurring: isRecurring,
            recurrenceInterval: isRecurring ? recurrenceInterval : nil,
            goalId: goalId
        )
        
        taskManager.addTask(task)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func priorityColor(for priority: Task.Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}
