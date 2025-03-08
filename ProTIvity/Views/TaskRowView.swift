import SwiftUI

// Ensure there's only one TaskRowView struct definition
struct TaskRowView: View {
    var task: Task
    @ObservedObject var taskManager: TaskManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            Button(action: {
                taskManager.toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                HStack(spacing: 6) {
                    Text(task.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    if task.isRecurring {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(task.recurrenceInterval?.rawValue ?? "")
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                    }
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastCompleted = task.lastCompletedDate {
                        Text("Last: \(lastCompleted, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    priorityView(for: task.priority)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Task"),
                    message: Text("Are you sure you want to delete this task?"),
                    primaryButton: .destructive(Text("Delete")) {
                        taskManager.deleteTask(task)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .padding(.vertical, 8)
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
}
