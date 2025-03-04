import SwiftUI

struct WorkspaceCreationView: View {
    @ObservedObject var workspaceManager: WorkspaceManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var icon = "folder.fill"
    @State private var color = Color.blue
    
    let icons = ["folder.fill", "briefcase.fill", "book.fill", "person.fill", "house.fill", 
                "heart.fill", "star.fill", "tag.fill", "doc.fill", "tray.fill"]
    
    let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .yellow, .gray]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workspace Details")) {
                    TextField("Name", text: $name)
                    
                    Picker("Icon", selection: $icon) {
                        ForEach(icons, id: \.self) { icon in
                            Label("", systemImage: icon)
                                .tag(icon)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    ColorPicker("Color", selection: $color)
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.title)
                        Text(name.isEmpty ? "New Workspace" : name)
                            .font(.headline)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Workspace")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Create") {
                    if !name.isEmpty {
                        workspaceManager.addWorkspace(name: name, icon: icon, color: color)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

// For backward compatibility
typealias AddWorkspaceView = WorkspaceCreationView
