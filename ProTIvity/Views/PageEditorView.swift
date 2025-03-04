import SwiftUI

struct PageContentEditorView: View {
    var page: Page
    var workspace: Workspace
    var workspaceManager: WorkspaceManager
    
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var isSaving = false
    @State private var showSavedConfirmation = false
    @State private var lastSavedTime = Date()
    
    // For auto-save functionality
    @State private var timer: Timer?
    @State private var hasUnsavedChanges = false
    
    init(page: Page, workspace: Workspace, workspaceManager: WorkspaceManager) {
        self.page = page
        self.workspace = workspace
        self.workspaceManager = workspaceManager
        _editedTitle = State(initialValue: page.title)
        _editedContent = State(initialValue: page.content)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Title field with styling
                HStack {
                    TextField("Title", text: $editedTitle)
                        .font(.system(size: 24, weight: .bold))
                        .padding()
                        .onChange(of: editedTitle) { _ in
                            hasUnsavedChanges = true
                            startAutoSaveTimer()
                        }
                    
                    if hasUnsavedChanges {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .padding(.trailing)
                    }
                }
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4)),
                    alignment: .bottom
                )
                
                // Editor with toolbar
                ZStack(alignment: .topLeading) {
                    // Background
                    Color(.systemBackground)
                    
                    // Content editor
                    TextEditor(text: $editedContent)
                        .padding()
                        .onChange(of: editedContent) { _ in
                            hasUnsavedChanges = true
                            startAutoSaveTimer()
                        }
                }
                
                // Bottom toolbar
                HStack {
                    Text("Last saved: \(formattedSaveTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: savePageContent) {
                        HStack {
                            Image(systemName: isSaving ? "clock" : "arrow.down.doc")
                            Text(isSaving ? "Saving..." : "Save")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(hasUnsavedChanges ? Color.blue : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isSaving || !hasUnsavedChanges)
                }
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray4)),
                    alignment: .top
                )
            }
            
            // Save confirmation overlay
            if showSavedConfirmation {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Saved successfully")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showSavedConfirmation = false
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: 
            Menu {
                Button(action: savePageContent) {
                    Label("Save", systemImage: "arrow.down.doc")
                }
                
                Button(action: {
                    // Share functionality
                    // This is a placeholder for actual sharing implementation
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                Button(role: .destructive, action: {
                    // Delete functionality
                    workspaceManager.deletePage(page, from: workspace)
                }) {
                    Label("Delete Page", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        )
        .onAppear {
            // Force refresh from the workspaceManager when view appears
            if let updatedPage = workspaceManager.getPage(withID: page.id, in: workspace) {
                editedTitle = updatedPage.title
                editedContent = updatedPage.content
            }
        }
        .onDisappear {
            // Save content when view disappears if there are unsaved changes
            if hasUnsavedChanges {
                savePageContentImmediately()
            }
            
            // Invalidate timer when view disappears
            timer?.invalidate()
            timer = nil
        }
    }
    
    private var formattedSaveTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSavedTime, relativeTo: Date())
    }
    
    private func startAutoSaveTimer() {
        // Invalidate existing timer if any
        timer?.invalidate()
        
        // Create new timer that will save after 3 seconds of inactivity
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            savePageContent()
        }
    }
    
    private func savePageContent() {
        guard hasUnsavedChanges else { return }
        
        isSaving = true
        
        // Simulate network delay for better UX feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            savePageContentImmediately()
        }
    }
    
    private func savePageContentImmediately() {
        print("💾 SAVING PAGE CONTENT IMMEDIATELY: \(editedTitle)")
        
        // Create an updated page with the new content
        var updatedPage = page
        updatedPage.title = editedTitle
        updatedPage.content = editedContent
        
        // Use the enhanced update method for better persistence
        workspaceManager.updatePageWithPersistence(updatedPage, in: workspace)
        
        // Update local state
        lastSavedTime = Date()
        hasUnsavedChanges = false
        isSaving = false
        
        // Show save confirmation
        withAnimation {
            showSavedConfirmation = true
        }
        
        print("✅ PAGE CONTENT SAVED SUCCESSFULLY: \(editedTitle)")
    }
}

// For backward compatibility
typealias PageEditorView = PageContentEditorView
typealias WorkspacePageEditorView = PageContentEditorView

// Extension to WorkspaceManager to add robust data persistence
extension WorkspaceManager {
    // CRITICAL DATA PERSISTENCE METHODS
    
    // Force save all data and update UI
    func forceSaveAndUpdate() {
        print("🔄 FORCE SAVING DATA AND UPDATING UI")
        
        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
            
            // Save to UserDefaults for persistence
            self.saveToUserDefaults()
            
            // Post notification for other views to refresh
            NotificationCenter.default.post(name: NSNotification.Name("WorkspaceDataChanged"), object: nil)
            
            print("✅ UI UPDATE COMPLETED")
        }
    }
    
    // Save to UserDefaults
    func saveToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.workspaces)
            UserDefaults.standard.set(data, forKey: "ProTIvity_Workspaces")
            print("✅ SUCCESSFULLY SAVED \(self.workspaces.count) WORKSPACES TO USERDEFAULTS")
            
            // Verify data was saved by reading it back
            if let savedData = UserDefaults.standard.data(forKey: "ProTIvity_Workspaces") {
                print("✓ Verification: Data exists in UserDefaults (\(savedData.count) bytes)")
            } else {
                print("⚠️ Verification FAILED: No data found in UserDefaults after saving")
            }
            
            // Force UserDefaults to synchronize
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ FAILED TO SAVE WORKSPACES TO USERDEFAULTS: \(error.localizedDescription)")
        }
    }
    
    // Load from UserDefaults
    func loadFromUserDefaults() {
        print("🔍 ATTEMPTING TO LOAD DATA FROM USERDEFAULTS")
        
        if let data = UserDefaults.standard.data(forKey: "ProTIvity_Workspaces") {
            do {
                let decoder = JSONDecoder()
                let loadedWorkspaces = try decoder.decode([Workspace].self, from: data)
                
                if loadedWorkspaces.isEmpty {
                    print("⚠️ LOADED WORKSPACES ARRAY IS EMPTY, ADDING DEFAULT DATA")
                    self.addDefaultWorkspacesIfNeeded()
                } else {
                    self.workspaces = loadedWorkspaces
                    print("✅ SUCCESSFULLY LOADED \(loadedWorkspaces.count) WORKSPACES FROM USERDEFAULTS")
                }
                
                // Force UI update
                self.objectWillChange.send()
            } catch {
                print("❌ FAILED TO DECODE WORKSPACES FROM USERDEFAULTS: \(error.localizedDescription)")
                self.addDefaultWorkspacesIfNeeded()
            }
        } else {
            print("⚠️ NO DATA FOUND IN USERDEFAULTS, ADDING DEFAULT DATA")
            self.addDefaultWorkspacesIfNeeded()
        }
    }
    
    // Add default workspaces with pre-made tasks and goals if none exist
    func addDefaultWorkspacesIfNeeded() {
        print("🏗️ CREATING DEFAULT WORKSPACES WITH PRE-MADE TASKS AND GOALS")
        
        // Only add default data if no workspaces exist
        if self.workspaces.isEmpty {
            // Create Work workspace with pre-made tasks and goals
            var workWorkspace = Workspace(name: "Work", icon: "briefcase.fill", color: .blue, categories: ["Meetings", "Projects", "Admin", "Learning"])
            
            // Add pre-made tasks to Work workspace
            workWorkspace.tasks = [
                Task(title: "Prepare quarterly report", isCompleted: false, category: "Admin", priority: .high, dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), notes: "Include sales figures and team performance metrics"),
                Task(title: "Team meeting", isCompleted: false, category: "Meetings", priority: .medium, dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), notes: "Discuss project timeline and resource allocation"),
                Task(title: "Update project documentation", isCompleted: false, category: "Projects", priority: .medium, dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()), notes: "Ensure all technical specifications are current"),
                Task(title: "Review job applications", isCompleted: true, category: "Admin", priority: .low, dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), notes: "For the senior developer position"),
                Task(title: "Complete online course", isCompleted: false, category: "Learning", priority: .low, dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()), notes: "SwiftUI Advanced Techniques")
            ]
            
            // Add pre-made goals to Work workspace
            workWorkspace.goals = [
                Goal(title: "Increase team productivity by 15%", description: "Implement new project management tools and methodologies", deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date())),
                Goal(title: "Complete certification", description: "Finish all required courses and pass the exam", deadline: Calendar.current.date(byAdding: .month, value: 2, to: Date())),
                Goal(title: "Launch new product feature", description: "Coordinate with design and development teams to release on schedule", deadline: Calendar.current.date(byAdding: .month, value: 1, to: Date()))
            ]
            
            // Add pre-made pages to Work workspace
            workWorkspace.pages = [
                Page(title: "Project Ideas", content: "1. Mobile app for team collaboration\n2. AI-powered analytics dashboard\n3. Customer feedback integration system"),
                Page(title: "Meeting Notes", content: "## Team Meeting - \(Date().formatted(date: .abbreviated, time: .omitted))\n\n- Discussed project timeline\n- Assigned tasks to team members\n- Set next meeting for next week")
            ]
            
            // Create Personal workspace with pre-made tasks and goals
            var personalWorkspace = Workspace(name: "Personal", icon: "house.fill", color: .green, categories: ["Health", "Shopping", "Home", "Finance"])
            
            // Add pre-made tasks to Personal workspace
            personalWorkspace.tasks = [
                Task(title: "Grocery shopping", isCompleted: false, category: "Shopping", priority: .medium, dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), notes: "Don't forget milk and eggs"),
                Task(title: "Pay utility bills", isCompleted: false, category: "Finance", priority: .high, dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), notes: "Electricity and internet"),
                Task(title: "Morning run", isCompleted: true, category: "Health", priority: .medium, dueDate: Date(), notes: "30 minutes minimum"),
                Task(title: "Clean garage", isCompleted: false, category: "Home", priority: .low, dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()), notes: "Organize tools and donate unused items"),
                Task(title: "Schedule dentist appointment", isCompleted: false, category: "Health", priority: .medium, dueDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()), notes: "Ask about teeth whitening options")
            ]
            
            // Add pre-made goals to Personal workspace
            personalWorkspace.goals = [
                Goal(title: "Save $5000 for vacation", description: "Set aside 10% of monthly income", deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date())),
                Goal(title: "Read 12 books this year", description: "Mix of fiction and non-fiction", deadline: Calendar.current.date(byAdding: .month, value: 12, to: Date())),
                Goal(title: "Run a half marathon", description: "Follow training schedule and gradually increase distance", deadline: Calendar.current.date(byAdding: .month, value: 4, to: Date()))
            ]
            
            // Add pre-made pages to Personal workspace
            personalWorkspace.pages = [
                Page(title: "Vacation Ideas", content: "1. Beach resort in Mexico\n2. Hiking trip in Colorado\n3. European city tour\n\nBudget: $3000-5000\nBest time: September-October"),
                Page(title: "Recipes to Try", content: "## Pasta Carbonara\n\nIngredients:\n- Spaghetti\n- Eggs\n- Pancetta\n- Parmesan cheese\n- Black pepper\n\nInstructions:\n1. Cook pasta\n2. Mix eggs and cheese\n3. Combine with hot pasta\n4. Add pancetta and pepper")
            ]
            
            // Add the workspaces to the manager
            self.workspaces = [workWorkspace, personalWorkspace]
            
            // Set the selected workspace
            self.selectedWorkspace = workWorkspace
            
            // Save the default data
            self.saveToUserDefaults()
            
            print("✅ CREATED \(self.workspaces.count) DEFAULT WORKSPACES WITH PRE-MADE CONTENT")
        }
    }
    
    // ENHANCED CRUD OPERATIONS WITH GUARANTEED PERSISTENCE
    
    // Add a task with guaranteed persistence
    func addTaskWithPersistence(_ task: Task, to workspace: Workspace) {
        print("➕ ADDING TASK: \(task.title) TO WORKSPACE: \(workspace.name)")
        
        // Find the workspace index
        if let index = self.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Add the task
            self.workspaces[index].tasks.append(task)
            
            // Force save and update
            self.saveToUserDefaults()
            self.forceSaveAndUpdate()
            
            print("✅ TASK ADDED AND SAVED: \(task.title)")
        } else {
            print("❌ FAILED TO ADD TASK: WORKSPACE NOT FOUND")
        }
    }
    
    // Add a goal with guaranteed persistence
    func addGoalWithPersistence(_ goal: Goal, to workspace: Workspace) {
        print("➕ ADDING GOAL: \(goal.title) TO WORKSPACE: \(workspace.name)")
        
        // Find the workspace index
        if let index = self.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Add the goal
            self.workspaces[index].goals.append(goal)
            
            // Force save and update
            self.saveToUserDefaults()
            self.forceSaveAndUpdate()
            
            print("✅ GOAL ADDED AND SAVED: \(goal.title)")
        } else {
            print("❌ FAILED TO ADD GOAL: WORKSPACE NOT FOUND")
        }
    }
    
    // Update a page with guaranteed persistence
    func updatePageWithPersistence(_ page: Page, in workspace: Workspace) {
        print("🔄 UPDATING PAGE: \(page.title) IN WORKSPACE: \(workspace.name)")
        
        // Find the workspace index
        if let workspaceIndex = self.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Find the page index
            if let pageIndex = self.workspaces[workspaceIndex].pages.firstIndex(where: { $0.id == page.id }) {
                // Update the page
                self.workspaces[workspaceIndex].pages[pageIndex] = page
                
                // Force save and update
                self.saveToUserDefaults()
                self.forceSaveAndUpdate()
                
                print("✅ PAGE UPDATED AND SAVED: \(page.title)")
            } else {
                // Page doesn't exist, add it
                self.workspaces[workspaceIndex].pages.append(page)
                
                // Force save and update
                self.saveToUserDefaults()
                self.forceSaveAndUpdate()
                
                print("✅ NEW PAGE ADDED AND SAVED: \(page.title)")
            }
        } else {
            print("❌ FAILED TO UPDATE PAGE: WORKSPACE NOT FOUND")
        }
    }
    
    // Toggle task completion with guaranteed persistence
    func toggleTaskCompletionWithPersistence(_ task: Task, in workspace: Workspace) {
        print("🔄 TOGGLING TASK COMPLETION: \(task.title) IN WORKSPACE: \(workspace.name)")
        
        // Find the workspace index
        if let workspaceIndex = self.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Find the task index
            if let taskIndex = self.workspaces[workspaceIndex].tasks.firstIndex(where: { $0.id == task.id }) {
                // Toggle completion
                var updatedTask = self.workspaces[workspaceIndex].tasks[taskIndex]
                updatedTask.isCompleted.toggle()
                self.workspaces[workspaceIndex].tasks[taskIndex] = updatedTask
                
                // Force save and update
                self.saveToUserDefaults()
                self.forceSaveAndUpdate()
                
                print("✅ TASK COMPLETION TOGGLED AND SAVED: \(task.title) - \(updatedTask.isCompleted ? "COMPLETED" : "NOT COMPLETED")")
            } else {
                print("❌ FAILED TO TOGGLE TASK COMPLETION: TASK NOT FOUND")
            }
        } else {
            print("❌ FAILED TO TOGGLE TASK COMPLETION: WORKSPACE NOT FOUND")
        }
    }
    
    // Toggle goal completion with guaranteed persistence
    func toggleGoalCompletionWithPersistence(_ goal: Goal, in workspace: Workspace) {
        print("🔄 TOGGLING GOAL COMPLETION: \(goal.title) IN WORKSPACE: \(workspace.name)")
        
        // Find the workspace index
        if let workspaceIndex = self.workspaces.firstIndex(where: { $0.id == workspace.id }) {
            // Find the goal index
            if let goalIndex = self.workspaces[workspaceIndex].goals.firstIndex(where: { $0.id == goal.id }) {
                // Toggle completion
                var updatedGoal = self.workspaces[workspaceIndex].goals[goalIndex]
                updatedGoal.isCompleted.toggle()
                self.workspaces[workspaceIndex].goals[goalIndex] = updatedGoal
                
                // Force save and update
                self.saveToUserDefaults()
                self.forceSaveAndUpdate()
                
                print("✅ GOAL COMPLETION TOGGLED AND SAVED: \(goal.title) - \(updatedGoal.isCompleted ? "COMPLETED" : "NOT COMPLETED")")
            } else {
                print("❌ FAILED TO TOGGLE GOAL COMPLETION: GOAL NOT FOUND")
            }
        } else {
            print("❌ FAILED TO TOGGLE GOAL COMPLETION: WORKSPACE NOT FOUND")
        }
    }
    
    // Get a page by ID with guaranteed data
    func getPage(withID id: UUID, in workspace: Workspace) -> Page? {
        // Load latest data first
        self.loadFromUserDefaults()
        
        // Then find the page
        return workspace.pages.first(where: { $0.id == id })
    }
}
