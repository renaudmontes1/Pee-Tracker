//
//  HistoryView.swift
//  Uri Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct HistoryView: View {
    let sessions: [PeeSession]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncMonitor = SyncMonitor.shared
    @State private var searchText = ""
    @State private var filterFeeling: SessionFeeling?
    @State private var showingFilters = false
    @State private var selectedSession: PeeSession?
    
    var filteredSessions: [PeeSession] {
        var filtered = sessions.filter { $0.endTime != nil }
        
        if let feeling = filterFeeling {
            filtered = filtered.filter { $0.feeling == feeling }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { session in
                (session.notes ?? "").localizedCaseInsensitiveContains(searchText) ||
                (session.symptoms ?? []).contains { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered
    }
    
    var groupedSessions: [Date: [PeeSession]] {
        Dictionary(grouping: filteredSessions) { session in
            guard let startTime = session.startTime else { return Date.distantPast }
            return Calendar.current.startOfDay(for: startTime)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Yet",
                        systemImage: "drop.slash",
                        description: Text("Start tracking to see your history here")
                    )
                } else {
                    ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                        Section {
                            ForEach(groupedSessions[date] ?? []) { session in
                                SessionRowView(session: session)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedSession = session
                                    }
                            }
                            .onDelete { indexSet in
                                deleteSessionsInSection(date: date, offsets: indexSet)
                            }
                        } header: {
                            Text(formatSectionDate(date))
                        }
                    }
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search notes or symptoms")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: filterFeeling != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(selectedFeeling: $filterFeeling)
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .onAppear {
                // Clear badge when user views history
                SubscriptionManager.shared.markHistoryViewed()
            }
        }
    }
    
    private func deleteSessionsInSection(date: Date, offsets: IndexSet) {
        guard let sessionsForDate = groupedSessions[date] else { return }
        
        offsets.forEach { index in
            let session = sessionsForDate[index]
            modelContext.delete(session)
        }
        
        try? modelContext.save()
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.wide))
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: PeeSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Time
                if let startTime = session.startTime {
                    Text(startTime.formatted(date: .omitted, time: .shortened))
                        .font(.headline)
                }
                
                Spacer()
                
                // Feeling
                if let feeling = session.feeling {
                    Text(feeling.emoji)
                        .font(.title3)
                }
                
                // Duration
                if let duration = session.duration {
                    Text(formatDuration(duration))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            // Symptoms
            if let symptoms = session.symptoms, !symptoms.isEmpty {
                HStack(spacing: 6) {
                    ForEach(symptoms, id: \.self) { symptom in
                        HStack(spacing: 4) {
                            Text(symptom.icon)
                                .font(.caption2)
                            Text(symptom.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .cornerRadius(4)
                    }
                }
            }
            
            // Notes preview
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Session Detail View
struct SessionDetailView: View {
    let session: PeeSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var editedNotes: String = ""
    @State private var hasUnsavedChanges = false
    @FocusState private var notesFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section("Session Info") {
                    if let startTime = session.startTime {
                        LabeledContent("Date") {
                            Text(startTime.formatted(date: .long, time: .omitted))
                        }
                        
                        LabeledContent("Time") {
                            Text(startTime.formatted(date: .omitted, time: .shortened))
                        }
                    }
                    
                    if let duration = session.duration {
                        LabeledContent("Duration") {
                            Text(formatDuration(duration))
                        }
                    }
                    
                    if let feeling = session.feeling {
                        LabeledContent("Feeling") {
                            HStack {
                                Text(feeling.emoji)
                                Text(feeling.rawValue)
                            }
                        }
                    }
                }
                
                if let symptoms = session.symptoms, !symptoms.isEmpty {
                    Section("Symptoms") {
                        ForEach(symptoms, id: \.self) { symptom in
                            HStack {
                                Text(symptom.icon)
                                Text(symptom.rawValue)
                            }
                        }
                    }
                }
                
                // Notes Section - Always Editable
                Section("Notes") {
                    TextField("Add notes here...", text: $editedNotes, axis: .vertical)
                        .lineLimit(3...10)
                        .focused($notesFieldFocused)
                        .onChange(of: editedNotes) { oldValue, newValue in
                            hasUnsavedChanges = (newValue != (session.notes ?? ""))
                        }
                }
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        if hasUnsavedChanges {
                            saveChanges()
                        }
                        dismiss()
                    }
                }
                
                if hasUnsavedChanges {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            saveChanges()
                        }
                    }
                }
                
#if !os(watchOS)
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        notesFieldFocused = false
                    }
                }
#endif
            }
        }
        .onAppear {
            editedNotes = session.notes ?? ""
        }
    }
    
    private func saveChanges() {
        session.notes = editedNotes.isEmpty ? nil : editedNotes
        
        do {
            try modelContext.save()
            hasUnsavedChanges = false
            SyncMonitor.shared.logEvent("Session notes updated on iPhone", type: .success)
        } catch {
            print("❌ Failed to save changes: \(error)")
            SyncMonitor.shared.logEvent("Failed to update session: \(error.localizedDescription)", type: .error)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Binding var selectedFeeling: SessionFeeling?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Filter by Feeling") {
                    Button(action: {
                        selectedFeeling = nil
                    }) {
                        HStack {
                            Text("All")
                            Spacer()
                            if selectedFeeling == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    ForEach(SessionFeeling.allCases, id: \.self) { feeling in
                        Button(action: {
                            selectedFeeling = feeling
                        }) {
                            HStack {
                                Text(feeling.emoji)
                                Text(feeling.rawValue)
                                Spacer()
                                if selectedFeeling == feeling {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let container = ModelContainer.shared
    let context = ModelContext(container)
    
    // Create sample sessions
    let session1 = PeeSession(
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date().addingTimeInterval(-3540),
        duration: 60,
        feeling: .positive,
        notes: "Feeling good"
    )
    let session2 = PeeSession(
        startTime: Date().addingTimeInterval(-7200),
        endTime: Date().addingTimeInterval(-7140),
        duration: 60,
        feeling: .negative,
        symptoms: [.pain, .weakStream, .burning],
        notes: "Some discomfort"
    )
    
    context.insert(session1)
    context.insert(session2)
    
    return HistoryView(sessions: [session1, session2])
        .modelContainer(container)
}
