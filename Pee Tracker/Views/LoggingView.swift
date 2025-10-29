//
//  LoggingView.swift
//  Pee Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData
import Combine

struct LoggingView: View {
    @ObservedObject var store: SessionStore
    @State private var showingSessionEnd = false
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.1), .cyan.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if let session = store.currentSession {
                        // Active session
                        activeSessionView(session: session)
                    } else {
                        // Ready to start
                        readyToStartView
                    }
                }
                .padding()
            }
            .navigationTitle("Pee Pee Tracker")
            .sheet(isPresented: $showingSessionEnd) {
                if let session = store.currentSession {
                    SessionEndDetailView(session: session, store: store, isPresented: $showingSessionEnd)
                }
            }
        }
    }
    
    private var readyToStartView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(.blue)
            
            Text("Ready to Track")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Tap the button when you start")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(action: {
                store.startSession()
            }) {
                Label("Start Session", systemImage: "play.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
            }
            
            Spacer()
        }
    }
    
    private func activeSessionView(session: PeeSession) -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)
            
            VStack(spacing: 8) {
                Text("Session in Progress")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(formatTime(elapsedTime))
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingSessionEnd = true
                }) {
                    Label("Complete Session", systemImage: "checkmark.circle.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                }
                
                Button(action: {
                    store.cancelSession()
                }) {
                    Label("Cancel", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
        }
        .onReceive(timer) { _ in
            if store.currentSession != nil {
                elapsedTime = Date().timeIntervalSince(session.startTime)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Session End Detail View
struct SessionEndDetailView: View {
    let session: PeeSession
    @ObservedObject var store: SessionStore
    @Binding var isPresented: Bool
    
    @State private var feeling: SessionFeeling = .positive
    @State private var selectedSymptoms: Set<Symptom> = []
    @State private var notes: String = ""
    @FocusState private var notesFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                // Feeling Section
                Section {
                    Picker("How did it feel?", selection: $feeling) {
                        ForEach(SessionFeeling.allCases, id: \.self) { feelingOption in
                            HStack {
                                Text(feelingOption.emoji)
                                Text(feelingOption.rawValue)
                            }
                            .tag(feelingOption)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: feeling) { oldValue, newValue in
                        if newValue == .positive {
                            selectedSymptoms.removeAll()
                        }
                    }
                } header: {
                    Text("Overall Feeling")
                }
                
                // Symptoms Section (only if negative)
                if feeling == .negative {
                    Section {
                        ForEach(Symptom.allCases, id: \.self) { symptom in
                            Button(action: {
                                if selectedSymptoms.contains(symptom) {
                                    selectedSymptoms.remove(symptom)
                                } else {
                                    selectedSymptoms.insert(symptom)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedSymptoms.contains(symptom) ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(selectedSymptoms.contains(symptom) ? .blue : .gray)
                                    Text("\(symptom.icon) \(symptom.rawValue)")
                                    Spacer()
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    } header: {
                        Text("Symptoms")
                    }
                }
                
                // Notes Section
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .focused($notesFieldFocused)
                } header: {
                    Text("Notes (Optional)")
                } footer: {
                    Text("Add any relevant details like medications, activities, or observations.")
                }
                
                // Session Info
                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatDuration(Date().timeIntervalSince(session.startTime)))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(session.startTime.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Session Details")
                }
            }
            .navigationTitle("Complete Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.endSession(
                            feeling: feeling,
                            symptoms: Array(selectedSymptoms),
                            notes: notes
                        )
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        notesFieldFocused = false
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    let context = ModelContext(ModelContainer.shared)
    LoggingView(store: SessionStore(modelContext: context))
}
