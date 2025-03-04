//
//  WorkspaceDetailView.swift
//  ProTIvity
//
//  Created by Arush Gupta on 2025-03-04.
//

import Foundation
import SwiftUI

struct WorkspaceDetailView: View {
    var workspace: Workspace
    @ObservedObject var workspaceManager: WorkspaceManager
    @ObservedObject var taskManager: TaskManager
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: workspace.icon)
                    .foregroundColor(workspace.color)
                    .font(.largeTitle)
                Text(workspace.name)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            
            TabView(selection: $selectedTab) {
                // Tasks
                TasksView(taskManager: taskManager, workspaceManager: workspaceManager, workspace: workspace)
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                    .tag(0)
                
                // Goals
                WorkspaceGoalsView(workspace: workspace, workspaceManager: workspaceManager)
                    .tabItem {
                        Label("Goals", systemImage: "target")
                    }
                    .tag(1)
                
                // Pages
                PagesView(workspace: workspace, workspaceManager: workspaceManager)
                    .tabItem {
                        Label("Pages", systemImage: "doc.text")
                    }
                    .tag(2)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Renamed to avoid conflicts with GoalsView in other files
struct WorkspaceGoalsView: View {
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    
    var body: some View {
        List {
            ForEach(workspace.goals) { goal in
                GoalRowView(goal: goal, workspace: workspace, workspaceManager: workspaceManager)
            }
            
            Button(action: {
                // Add new goal
                let newGoal = Goal(title: "New Goal")
                workspaceManager.addGoal(newGoal, to: workspace)
            }) {
                Label("Add Goal", systemImage: "plus")
            }
        }
        .navigationTitle("Goals")
    }
}

struct GoalRowView: View {
    var goal: Goal
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    var updatedGoal = goal
                    updatedGoal.isCompleted.toggle()
                    workspaceManager.updateGoal(updatedGoal, in: workspace)
                }) {
                    Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(goal.isCompleted ? .green : .gray)
                }
                
                Text(goal.title)
                    .font(.headline)
                    .strikethrough(goal.isCompleted)
                
                Spacer()
                
                Button(action: {
                    workspaceManager.deleteGoal(goal, from: workspace)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            if !goal.description.isEmpty {
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let deadline = goal.deadline {
                Text("Deadline: \(deadline, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PagesView: View {
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    @State private var showingAddPage = false
    @State private var newPageTitle = ""
    
    var body: some View {
        List {
            ForEach(workspace.pages) { page in
                NavigationLink(destination: PageContentEditorView(page: page, workspace: workspace, workspaceManager: workspaceManager)) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(workspace.color)
                        VStack(alignment: .leading) {
                            Text(page.title)
                                .font(.headline)
                            Text("Modified: \(page.dateModified, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Button(action: {
                showingAddPage = true
            }) {
                Label("Add Page", systemImage: "plus")
            }
        }
        .navigationTitle("Pages")
        .alert("New Page", isPresented: $showingAddPage) {
            TextField("Page Title", text: $newPageTitle)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                if !newPageTitle.isEmpty {
                    let newPage = Page(title: newPageTitle)
                    workspaceManager.addPage(newPage, to: workspace)
                    newPageTitle = ""
                }
            }
        }
    }
}
