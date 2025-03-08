import SwiftUI

struct GoalsTabView: View {
    @StateObject private var goalManager = GoalManager()
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddGoal = false
    @State private var selectedFilter: GoalFilter = .all
    
    enum GoalFilter {
        case all, active, completed, upcoming
        
        var title: String {
            switch self {
            case .all: return "All Goals"
            case .active: return "Active"
            case .completed: return "Completed"
            case .upcoming: return "Upcoming"
            }
        }
        
        var icon: String {
            switch self {
            case .all: return "target"
            case .active: return "circle"
            case .completed: return "checkmark.circle"
            case .upcoming: return "calendar"
            }
        }
    }
    
    var body: some View {
        VStack {
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([GoalFilter.all, .active, .upcoming, .completed], id: \.self) { filter in
                        SharedFilterButton(
                            title: filter.title,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Goals list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredGoals) { goal in
                        GoalCard(goal: goal, goalManager: goalManager, taskManager: taskManager)
                    }
                }
                .padding()
            }
            .overlay(Group {
                if filteredGoals.isEmpty {
                    SharedEmptyStateView(
                        iconName: emptyStateIcon,
                        message: emptyStateMessage,
                        buttonTitle: "Add Goal",
                        buttonAction: { showingAddGoal = true }
                    )
                }
            })
        }
        .navigationTitle("Goals")
        .navigationBarItems(trailing: Button(action: {
            showingAddGoal = true
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView(goalManager: goalManager)
        }
    }
    
    private var filteredGoals: [Goal] {
        switch selectedFilter {
        case .all:
            return goalManager.goals
        case .active:
            return goalManager.activeGoals()
        case .completed:
            return goalManager.completedGoals()
        case .upcoming:
            return goalManager.upcomingGoals()
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "target"
        case .active: return "circle"
        case .completed: return "checkmark.circle"
        case .upcoming: return "calendar"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "You don't have any goals yet.\nAdd your first goal to get started!"
        case .active:
            return "You don't have any active goals.\nAll your goals are completed!"
        case .completed:
            return "You don't have any completed goals yet.\nComplete a goal to see it here!"
        case .upcoming:
            return "You don't have any upcoming goals.\nAdd a goal with a future deadline!"
        }
    }
}
