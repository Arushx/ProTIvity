import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    private let saveKey = "tasks"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadTasks()
        
        // Set up autosave when tasks change
        $tasks
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveTasks()
            }
            .store(in: &cancellables)
    }
    
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
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
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
    
    // MARK: - Persistence
    
    private func saveTasks() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tasks)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save tasks: \(error.localizedDescription)")
        }
    }
    
    private func loadTasks() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            tasks = try decoder.decode([Task].self, from: data)
        } catch {
            print("Failed to load tasks: \(error.localizedDescription)")
        }
    }
}

