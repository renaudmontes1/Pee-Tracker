//
//  HistoryView.swift
//  Pee Tracker Watch App
//
//  Created by GitHub Copilot on 10/29/25.
//

import SwiftUI
import SwiftData

struct WatchHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<PeeSession> { session in
            session.endTime != nil
        },
        sort: \PeeSession.endTime,
        order: .reverse
    ) private var sessions: [PeeSession]
    @State private var refreshID = UUID()
    
    var completedSessions: [PeeSession] {
        // Limit to 50 most recent sessions on Watch to save memory
        Array(sessions.prefix(50))
    }
    
    var body: some View {
        NavigationStack {
            List {
                if completedSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Yet",
                        systemImage: "drop.circle",
                        description: Text("Sessions you track will appear here")
                    )
                } else {
                    ForEach(completedSessions.prefix(20)) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            SessionRowView(session: session)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .id(refreshID)
            .onAppear {
                // Force refresh when view appears
                refreshID = UUID()
            }
        }
    }
}

struct SessionRowView: View {
    let session: PeeSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let feeling = session.feeling {
                    Text(feeling.emoji)
                        .font(.title3)
                }
                
                if let startTime = session.startTime {
                    Text(startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let duration = session.duration {
                    Text(formatDuration(duration))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let symptoms = session.symptoms, !symptoms.isEmpty {
                HStack(spacing: 4) {
                    ForEach(symptoms, id: \.self) { symptom in
                        Text(symptom.icon)
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

struct SessionDetailView: View {
    let session: PeeSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Feeling
                if let feeling = session.feeling {
                    HStack {
                        Text("Feeling")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(feeling.emoji) \(feeling.rawValue)")
                            .font(.body)
                    }
                }
                
                Divider()
                
                // Duration
                if let duration = session.duration {
                    HStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatDuration(duration))
                            .font(.body)
                    }
                }
                
                Divider()
                
                // Time
                if let startTime = session.startTime {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.body)
                    }
                }
                
                // Symptoms
                if let symptoms = session.symptoms, !symptoms.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Symptoms")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ForEach(symptoms, id: \.self) { symptom in
                            HStack {
                                Text(symptom.icon)
                                Text(symptom.rawValue)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Notes
                if let notes = session.notes, !notes.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Session Details")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    WatchHistoryView()
        .modelContainer(ModelContainer.shared)
}
