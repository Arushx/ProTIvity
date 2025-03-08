import Foundation
import Combine

class GoalManager: ObservableObject {
    @Published var goals: [Goal] = []
    private let saveKey = "goals"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadGoals()
        
        // Set up autosave when goals change
        $goals
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveGoals()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Goal Management
    
    func addGoal(_ goal: Goal) {
        goals.append(goal)
    }
    
    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
    }
    
    func toggleGoalCompletion(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            var updatedGoal = goals[index]
            updatedGoal.isCompleted.toggle()
            goals[index] = updatedGoal
        }
    }
    
    // MARK: - Task Management
    
    func addTaskToGoal(taskId: UUID, goalId: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            var updatedGoal = goals[index]
            if !updatedGoal.tasks.contains(taskId) {
                updatedGoal.tasks.append(taskId)
                goals[index] = updatedGoal
            }
        }
    }
    
    func removeTaskFromGoal(taskId: UUID, goalId: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            var updatedGoal = goals[index]
            updatedGoal.tasks.removeAll { $0 == taskId }
            goals[index] = updatedGoal
        }
    }
    
    func getTasksForGoal(_ goalId: UUID) -> [UUID] {
        if let goal = goals.first(where: { $0.id == goalId }) {
            return goal.tasks
        }
        return []
    }
    
    // MARK: - Goal Filtering
    
    func activeGoals() -> [Goal] {
        goals.filter { !$0.isCompleted }
    }
    
    func completedGoals() -> [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    func upcomingGoals() -> [Goal] {
        let today = Calendar.current.startOfDay(for: Date())
        return goals.filter { goal in
            if let deadline = goal.deadline {
                return deadline > today && !goal.isCompleted
            }
            return false
        }
    }
    
    // MARK: - Persistence
    
    private func saveGoals() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(goals)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save goals: \(error.localizedDescription)")
        }
    }
    
    private func loadGoals() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            goals = try decoder.decode([Goal].self, from: data)
        } catch {
            print("Failed to load goals: \(error.localizedDescription)")
        }
    }
}
