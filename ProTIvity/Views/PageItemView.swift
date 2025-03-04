import SwiftUI

struct PageItemView: View {
    let page: Page
    let workspace: Workspace
    @ObservedObject var workspaceManager: WorkspaceManager
    @ObservedObject var taskManager: TaskManager
    
    var body: some View {
        NavigationLink(destination: PageContentEditorView(page: page, workspace: workspace, workspaceManager: workspaceManager)) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(workspace.color)
                Text(page.title)
                    .font(.subheadline)
            }
            .padding(.leading, 10)
        }
    }
} 