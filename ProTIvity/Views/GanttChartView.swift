import SwiftUI

struct GanttChartView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var scrollOffset: CGFloat = 0
    @State private var timeScale: TimeScale = .week
    
    enum TimeScale: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Time scale picker
            Picker("Time Scale", selection: $timeScale) {
                ForEach(TimeScale.allCases, id: \.self) { scale in
                    Text(scale.rawValue).tag(scale)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Gantt chart
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Task names column
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Tasks")
                            .font(.headline)
                            .frame(width: 150, height: 40)
                            .background(Color(.systemBackground))
                            .border(Color.gray.opacity(0.2))
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(taskManager.tasks.filter { $0.dueDate != nil }) { task in
                                    Text(task.title)
                                        .frame(width: 150, height: 40, alignment: .leading)
                                        .padding(.horizontal, 8)
                                        .background(Color(.systemBackground))
                                        .border(Color.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: 0) {
                        timelineHeader
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(taskManager.tasks.filter { $0.dueDate != nil }) { task in
                                    taskTimelineRow(for: task)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Gantt Chart")
    }
    
    private var timelineHeader: some View {
        let dates = timelineDates()
        return HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                Text(formatDate(date))
                    .frame(width: columnWidth, height: 40)
                    .background(Color(.systemBackground))
                    .border(Color.gray.opacity(0.2))
            }
        }
    }
    
    private func taskTimelineRow(for task: Task) -> some View {
        let dates = timelineDates()
        return HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                taskCell(for: task, on: date)
            }
        }
        .frame(height: 40)
    }
    
    private func taskCell(for task: Task, on date: Date) -> some View {
        let isTaskDay = isDate(date, inRangeOf: task)
        return Rectangle()
            .fill(isTaskDay ? taskColor(for: task) : Color.clear)
            .frame(width: columnWidth, height: 40)
            .border(Color.gray.opacity(0.2))
    }
    
    private func taskColor(for task: Task) -> Color {
        if task.isCompleted {
            return .green.opacity(0.3)
        }
        switch task.priority {
        case .high:
            return .red.opacity(0.3)
        case .medium:
            return .orange.opacity(0.3)
        case .low:
            return .blue.opacity(0.3)
        }
    }
    
    private var columnWidth: CGFloat {
        switch timeScale {
        case .day:
            return 60
        case .week:
            return 100
        case .month:
            return 150
        }
    }
    
    private func timelineDates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let numberOfDays: Int
        
        switch timeScale {
        case .day:
            numberOfDays = 14
        case .week:
            numberOfDays = 28
        case .month:
            numberOfDays = 60
        }
        
        return (0..<numberOfDays).map { days in
            calendar.date(byAdding: .day, value: days, to: today) ?? today
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch timeScale {
        case .day:
            formatter.dateFormat = "d MMM"
        case .week:
            formatter.dateFormat = "d MMM"
        case .month:
            formatter.dateFormat = "MMM yyyy"
        }
        return formatter.string(from: date)
    }
    
    private func isDate(_ date: Date, inRangeOf task: Task) -> Bool {
        guard let taskDueDate = task.dueDate else { return false }
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        let taskDate = calendar.startOfDay(for: taskDueDate)
        return taskDate >= startDate && taskDate < endDate
    }
}
