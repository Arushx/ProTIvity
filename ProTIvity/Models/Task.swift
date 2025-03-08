import Foundation
import SwiftUI

// Main Task model - ensure this is the only Task definition in the project
struct Task: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var category: String
    var priority: Priority = .medium
    var dueDate: Date?
    var notes: String = ""
    var isRecurring: Bool = false
    var recurrenceInterval: RecurrenceInterval?
    var isArchived: Bool = false
    var lastCompletedDate: Date?
    var goalId: UUID?
    
    enum RecurrenceInterval: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
    
    // Factory method to create a task with default values
    static func createDefault(title: String) -> Task {
        Task(title: title, category: "General")
    }
}

// Extension for Task-related functionality
extension Task {
    // Add any additional Task-related methods here
}

struct TaskCategory {
    static let defaultCategories = ["Work", "Personal", "Shopping", "Health", "Other"]
    
    static func color(for category: String) -> Color {
        switch category {
        case "Work": return .blue
        case "Personal": return .green
        case "Shopping": return .orange
        case "Health": return .red
        case "Other": return .purple
        default:
            let hash = category.hashValue
            let hue = Double(abs(hash) % 360) / 360.0
            return Color(hue: hue, saturation: 0.7, brightness: 0.9)
        }
    }
    
    static func icon(for category: String) -> String {
        switch category.lowercased() {
        case let c where c.contains("work"): return "briefcase.fill"
        case let c where c.contains("personal"): return "person.fill"
        case let c where c.contains("shopping"): return "cart.fill"
        case let c where c.contains("health"): return "heart.fill"
        case let c where c.contains("study"): return "book.fill"
        case let c where c.contains("home"): return "house.fill"
        default: return "tag.fill"
        }
    }
}
