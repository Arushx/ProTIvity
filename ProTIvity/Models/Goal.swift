import Foundation
import SwiftUI

// Main Goal model - ensure this is the only Goal definition in the project
struct Goal: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var description: String = ""
    var deadline: Date?
    var isCompleted: Bool = false
    var tasks: [UUID] = [] // References to task IDs
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id
    }
    
    // Factory method to create a goal with default values
    static func createDefault(title: String) -> Goal {
        Goal(title: title)
    }
}

// Extension for Goal-related functionality
extension Goal {
    // Add any additional Goal-related methods here
}
