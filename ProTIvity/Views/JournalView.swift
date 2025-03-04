import SwiftUI

struct JournalView: View {
    @State private var showingAddEntry = false
    @State private var quickThought = ""
    @State private var entries: [JournalEntry] = []
    
    var entriesByWeek: [String: [JournalEntry]] {
        Dictionary(grouping: entries) { $0.weekYearKey }
            .sorted { $0.key > $1.key }
            .reduce(into: [:]) { result, element in
                result[element.key] = element.value.sorted { $0.date > $1.date }
            }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick thought entry
                HStack {
                    TextField("Write a quick thought...", text: $quickThought)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        if !quickThought.isEmpty {
                            let entry = JournalEntry(thoughts: quickThought, date: Date())
                            entries.append(entry)
                            quickThought = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .disabled(quickThought.isEmpty)
                }
                .padding(.horizontal)
                
                // Weekly sections
                ForEach(Array(entriesByWeek.keys.sorted().reversed()), id: \.self) { weekKey in
                    WeeklyJournalSection(weekKey: weekKey, entries: entriesByWeek[weekKey] ?? [])
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Journal")
        .toolbar {
            Button(action: { showingAddEntry = true }) {
                Image(systemName: "square.and.pencil")
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            NavigationView {
                AddJournalEntryView { thoughts in
                    let entry = JournalEntry(thoughts: thoughts, date: Date())
                    entries.append(entry)
                }
            }
        }
    }
}

struct WeeklyJournalSection: View {
    let weekKey: String
    let entries: [JournalEntry]
    
    var weekTitle: String {
        let components = weekKey.split(separator: "-")
        let year = components[0]
        let week = components[1]
        return "Week \(week), \(year)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(weekTitle)
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(entries) { entry in
                JournalEntryWidget(entry: entry)
            }
        }
    }
}

struct JournalEntryWidget: View {
    let entry: JournalEntry
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(entry.thoughts)
                .font(.body)
                .lineLimit(nil)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct AddJournalEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void
    
    @State private var thoughts = ""
    
    var body: some View {
        Form {
            Section(header: Text("Your Thoughts")) {
                TextEditor(text: $thoughts)
                    .frame(minHeight: 150)
            }
        }
        .navigationTitle("New Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if !thoughts.isEmpty {
                        onSave(thoughts)
                        dismiss()
                    }
                }
                .disabled(thoughts.isEmpty)
            }
        }
    }
}
