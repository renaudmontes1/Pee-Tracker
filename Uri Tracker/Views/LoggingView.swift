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
    @StateObject private var syncMonitor = SyncMonitor.shared
    @State private var showingSessionEnd = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timerCancellable: AnyCancellable?
    
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
            .onChange(of: showingSessionEnd) { oldValue, newValue in
                // If the sheet is dismissed and there's still a current session (user cancelled)
                // restart the timer. Otherwise, reset elapsed time.
                if !newValue {
                    if store.currentSession != nil {
                        startTimer()
                    } else {
                        elapsedTime = 0
                    }
                }
            }
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // Only update timer if session is active AND sheet is not showing
                if !showingSessionEnd, store.currentSession != nil, let start = store.currentSession?.startTime {
                    elapsedTime = Date().timeIntervalSince(start)
                }
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
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
                    // End the session NOW to capture accurate duration
                    // (before showing the detail view)
                    if let session = store.currentSession {
                        session.endSession()
                    }
                    
                    // Stop the timer to prevent it from continuing while entering notes
                    stopTimer()
                    
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
                    elapsedTime = 0
                }) {
                    Label("Cancel", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
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
                            Text("\(feelingOption.emoji) \(feelingOption.rawValue)")
                                .tag(feelingOption)
                        }
                    }
#if !os(watchOS)
                    .pickerStyle(.segmented)
#endif
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
                    TextField("Add notes here...", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
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
                        if let duration = session.duration {
                            Text(formatDuration(duration))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Time")
                        Spacer()
                        if let start = session.startTime {
                            Text(start.formatted(date: .omitted, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
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
                        // Cancel the session completely - don't save anything
                        store.cancelSession()
                        isPresented = false
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
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    let context = ModelContext(ModelContainer.shared)
    LoggingView(store: SessionStore(modelContext: context, platformName: "Preview"))
}
