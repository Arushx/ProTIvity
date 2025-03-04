import SwiftUI

// Ensure there's only one TaskRowView struct definition
struct TaskRowView: View {
    var task: Task
    var onToggle: (Bool) -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                onToggle(!task.isCompleted)
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
                
                HStack {
                    Text(task.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    priorityView(for: task.priority)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
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
