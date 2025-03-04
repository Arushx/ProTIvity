import Foundation
import SwiftUI

struct JournalEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var thoughts: String
    var date: Date
    
    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    // Get week number for grouping
    var weekOfYear: Int {
        Calendar.current.component(.weekOfYear, from: date)
    }
    
    // Get year for grouping
    var year: Int {
        Calendar.current.component(.year, from: date)
    }
    
    // Combine week and year for unique grouping
    var weekYearKey: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.year, from: date)
        return "\(weekOfYear)/\(year)"
    }
}
