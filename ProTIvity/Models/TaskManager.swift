import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var archivedTasks: [Task] = []
    private let tasksKey = "tasks"
    private let archivedTasksKey = "archivedTasks"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTasks()
        loadArchivedTasks()
        
        // Set up autosave when tasks or archived tasks change
        Publishers.CombineLatest($tasks, $archivedTasks)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.saveTasks()
                self?.saveArchivedTasks()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func deleteTask(at indexSet: IndexSet) {
        tasks.remove(atOffsets: indexSet)
    }
    
    func tasksForCategory(_ category: String) -> [Task] {
        tasks.filter { $0.category == category }
    }
    
    func tasksForToday() -> [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return Calendar.current.isDate(dueDate, inSameDayAs: today)
            }
            return false
        }
    }
    
    func upcomingTasks() -> [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { task in
            if let dueDate = task.dueDate {
                return dueDate > today && !Calendar.current.isDate(dueDate, inSameDayAs: today)
            }
            return false
        }
    }
    
    func completedTasks() -> [Task] {
        tasks.filter { $0.isCompleted }
    }
    
    // MARK: - Recurring Tasks
    
    func handleRecurringTask(_ task: Task) {
        guard task.isRecurring, let interval = task.recurrenceInterval else { return }
        
        var nextDueDate: Date?
        if let currentDueDate = task.dueDate {
            let calendar = Calendar.current
            switch interval {
            case .daily:
                nextDueDate = calendar.date(byAdding: .day, value: 1, to: currentDueDate)
            case .weekly:
                nextDueDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDueDate)
            case .monthly:
                nextDueDate = calendar.date(byAdding: .month, value: 1, to: currentDueDate)
            case .yearly:
                nextDueDate = calendar.date(byAdding: .year, value: 1, to: currentDueDate)
            }
        }
        
        // Create next occurrence
        if nextDueDate != nil {
            var newTask = task
            newTask.id = UUID()
            newTask.isCompleted = false
            newTask.dueDate = nextDueDate
            newTask.lastCompletedDate = nil
            addTask(newTask)
        }
    }
    
    // MARK: - Archive Management
    
    func archiveTask(_ task: Task) {
        if !task.isRecurring {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                var archivedTask = tasks[index]
                archivedTask.isArchived = true
                archivedTask.lastCompletedDate = Date()
                archivedTasks.append(archivedTask)
                tasks.remove(at: index)
            }
        }
    }
    
    func unarchiveTask(_ task: Task) {
        if let index = archivedTasks.firstIndex(where: { $0.id == task.id }) {
            var unarchivedTask = archivedTasks[index]
            unarchivedTask.isArchived = false
            tasks.append(unarchivedTask)
            archivedTasks.remove(at: index)
        }
    }
    
    // MARK: - Goal-Related Tasks
    
    func tasksForGoal(_ goalId: UUID) -> [Task] {
        tasks.filter { $0.goalId == goalId }
    }
    
    func completionPercentageForGoal(_ goalId: UUID) -> Double {
        let goalTasks = tasksForGoal(goalId)
        guard !goalTasks.isEmpty else { return 0.0 }
        let completedTasks = goalTasks.filter { $0.isCompleted }
        return Double(completedTasks.count) / Double(goalTasks.count) * 100.0
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            updatedTask.isCompleted.toggle()
            updatedTask.lastCompletedDate = updatedTask.isCompleted ? Date() : nil
            tasks[index] = updatedTask
            
            if updatedTask.isCompleted {
                if updatedTask.isRecurring {
                    handleRecurringTask(updatedTask)
                } else {
                    archiveTask(updatedTask)
                }
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tasks)
            UserDefaults.standard.set(data, forKey: tasksKey)
        } catch {
            print("Failed to save tasks: \(error.localizedDescription)")
        }
    }
    
    private func saveArchivedTasks() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(archivedTasks)
            UserDefaults.standard.set(data, forKey: archivedTasksKey)
        } catch {
            print("Failed to save archived tasks: \(error.localizedDescription)")
        }
    }
    
    private func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: tasksKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            tasks = try decoder.decode([Task].self, from: data)
        } catch {
            print("Failed to load tasks: \(error.localizedDescription)")
        }
    }
    
    private func loadArchivedTasks() {
        guard let data = UserDefaults.standard.data(forKey: archivedTasksKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            archivedTasks = try decoder.decode([Task].self, from: data)
        } catch {
            print("Failed to load archived tasks: \(error.localizedDescription)")
        }
    }
}

