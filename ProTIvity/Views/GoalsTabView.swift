//
//  GoalsTabView.swift
//  ProTIvity
//
//  Created by Arush Gupta on 2025-03-03.
//

import Foundation
import SwiftUI

// This is the main GoalsTabView used in the app's tab bar
struct MainGoalsTabView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    
    var body: some View {
        NavigationView {
            if let workspace = workspaceManager.selectedWorkspace {
                GoalsList(workspace: workspace, workspaceManager: workspaceManager)
            } else {
                WorkspaceSelectionView(workspaceManager: workspaceManager)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Helper view for displaying goals
struct GoalsList: View {
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    @State private var showingAddGoal = false
    @State private var newGoalTitle = ""
    
    var body: some View {
        List {
            ForEach(workspace.goals) { goal in
                GoalRowView(goal: goal, workspace: workspace, workspaceManager: workspaceManager)
            }
            
            Button(action: {
                showingAddGoal = true
            }) {
                Label("Add Goal", systemImage: "plus")
            }
        }
        .navigationTitle("Goals - \(workspace.name)")
        .alert("New Goal", isPresented: $showingAddGoal) {
            TextField("Goal Title", text: $newGoalTitle)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                if !newGoalTitle.isEmpty {
                    let newGoal = Goal(title: newGoalTitle)
                    workspaceManager.addGoal(newGoal, to: workspace)
                    newGoalTitle = ""
                }
            }
        }
    }
}

// Helper view for selecting a workspace
struct WorkspaceSelectionView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    
    var body: some View {
        VStack {
            Text("Select a Workspace")
                .font(.headline)
            
            List {
                ForEach(workspaceManager.workspaces) { workspace in
                    Button(action: {
                        workspaceManager.selectedWorkspace = workspace
                    }) {
                        HStack {
                            Image(systemName: workspace.icon)
                                .foregroundColor(workspace.color)
                            Text(workspace.name)
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .navigationTitle("Goals")
    }
}
