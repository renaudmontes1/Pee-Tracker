//
//  ContentView.swift
//  Pee Pee Tracker Watch App
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var store: SessionStore
    @State private var showingSessionEnd = false
    
    init() {
        // Note: modelContext will be injected by environment
        let context = ModelContext(ModelContainer.shared)
        _store = StateObject(wrappedValue: SessionStore(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let session = store.currentSession {
                    // Active session view
                    ActiveSessionView(session: session, store: store, showingSessionEnd: $showingSessionEnd)
                } else {
                    // Start session view
                    StartSessionView(store: store)
                }
            }
            .navigationTitle("Pee Pee Tracker")
            .sheet(isPresented: $showingSessionEnd) {
                if let session = store.currentSession {
                    SessionEndView(session: session, store: store, isPresented: $showingSessionEnd)
                }
            }
            .onAppear {
                // Initialize store with environment context
                if let context = try? ModelContext(modelContext.container) {
                    // Store is already initialized
                }
            }
        }
    }
}

// MARK: - Start Session View
struct StartSessionView: View {
    @ObservedObject var store: SessionStore
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Button(action: {
                store.startSession()
            }) {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
    }
}

// MARK: - Active Session View
struct ActiveSessionView: View {
    let session: PeeSession
    @ObservedObject var store: SessionStore
    @Binding var showingSessionEnd: Bool
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)
            
            Text(formatTime(elapsedTime))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.blue)
            
            Button(action: {
                showingSessionEnd = true
            }) {
                Label("Stop", systemImage: "stop.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .onReceive(timer) { _ in
            elapsedTime = Date().timeIntervalSince(session.startTime)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Session End View
struct SessionEndView: View {
    let session: PeeSession
    @ObservedObject var store: SessionStore
    @Binding var isPresented: Bool
    
    @State private var feeling: SessionFeeling = .positive
    @State private var selectedSymptoms: Set<Symptom> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Feeling Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How did it feel?")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(SessionFeeling.allCases, id: \.self) { feelingOption in
                                Button(action: {
                                    feeling = feelingOption
                                    if feeling == .positive {
                                        selectedSymptoms.removeAll()
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Text(feelingOption.emoji)
                                            .font(.title)
                                        Text(feelingOption.rawValue)
                                            .font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(feeling == feelingOption ? Color.blue.opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Symptoms (only if negative)
                    if feeling == .negative {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Symptoms")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
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
                                                .font(.caption)
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // Save Button
                    Button(action: {
                        store.endSession(
                            feeling: feeling,
                            symptoms: Array(selectedSymptoms)
                        )
                        isPresented = false
                    }) {
                        Text("Save Session")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
            }
            .navigationTitle("Complete Session")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Extension to share ModelContainer
extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([PeeSession.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.shared)
}

