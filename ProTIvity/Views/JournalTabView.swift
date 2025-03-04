//
//  JournalTabView.swift
//  ProTIvity
//
//  Created by Arush Gupta on 2025-03-03.
//

import Foundation
import SwiftUI

struct JournalTabView: View {
    @State private var entries: [JournalEntry] = []
    @State private var showingAddEntry = false
    
    // Group entries by week/year
    var entriesByWeek: [String: [JournalEntry]] {
        Dictionary(grouping: entries, by: { $0.weekYearKey })
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(entriesByWeek.keys.sorted(by: >), id: \.self) { weekKey in
                    Section(header: Text("Week \(weekKey)")) {
                        ForEach(entriesByWeek[weekKey] ?? []) { entry in
                            JournalEntryCard(entry: entry)
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEntry = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                NavigationView {
                    AddJournalEntryWithDateView { thoughts, date in
                        let newEntry = JournalEntry(thoughts: thoughts, date: date)
                        entries.append(newEntry)
                        showingAddEntry = false
                    }
                }
            }
        }
    }
}

struct JournalEntryCard: View {
    var entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.thoughts)
                .font(.body)
                .foregroundColor(.primary)
            Text(formattedDate(entry.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange, lineWidth: 1))
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AddJournalEntryWithDateView: View {
    @Environment(\.dismiss) var dismiss
    @State private var thoughts: String = ""
    @State private var entryDate: Date = Date()
    
    var onAdd: (String, Date) -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Thoughts")) {
                TextField("Enter your thoughts", text: $thoughts)
            }
            Section(header: Text("Date")) {
                DatePicker("Select Date", selection: $entryDate, displayedComponents: [.date])
            }
        }
        .navigationTitle("Add Journal Entry")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    if !thoughts.isEmpty {
                        onAdd(thoughts, entryDate)
                        dismiss()
                    }
                }
                .disabled(thoughts.isEmpty)
            }
        }
    }
}
