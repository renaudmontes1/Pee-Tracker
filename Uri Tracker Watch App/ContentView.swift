//
//  ContentView.swift
//  Uri Tracker Watch App
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData
import Combine
import WatchKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var store: SessionStore
    @StateObject private var syncMonitor = SyncMonitor.shared
    @State private var showingSessionEnd = false
    @State private var showingSyncDebug = false
    
    init() {
        // Note: modelContext will be injected by environment
        let context = ModelContext(ModelContainer.shared)
        _store = StateObject(wrappedValue: SessionStore(modelContext: context, platformName: "Watch"))
    }
    
    var body: some View {
        TabView {
            // Logging Tab
            NavigationStack {
                VStack(spacing: 12) {
                    if let session = store.currentSession {
                        // Active session view
                        ActiveSessionView(session: session, store: store, showingSessionEnd: $showingSessionEnd)
                    } else {
                        // Start session view
                        StartSessionView(store: store)
                    }
                }
                .navigationTitle("Log")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            showingSyncDebug = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .sheet(isPresented: $showingSessionEnd) {
                    if let session = store.currentSession {
                        SessionEndView(session: session, store: store, isPresented: $showingSessionEnd)
                    }
                }
                .sheet(isPresented: $showingSyncDebug) {
                    SyncDebugView()
                }
            }
            .tabItem {
                Label("Log", systemImage: "drop.fill")
            }
            
            // History Tab
            WatchHistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
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
    @State private var timerCancellable: AnyCancellable?
    @State private var hasShownTwoMinuteReminder = false
    @State private var extendedRuntimeSession: WKExtendedRuntimeSession?
    @Environment(\.scenePhase) private var scenePhase
    
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
                stopTimer()
                endExtendedRuntimeSession()
                
                // End the session NOW to capture accurate duration
                // (before showing the detail view)
                session.endSession()
                
                showingSessionEnd = true
            }) {
                Label("Stop", systemImage: "stop.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .onAppear {
            startTimer()
            startExtendedRuntimeSession()
        }
        .onDisappear {
            stopTimer()
            endExtendedRuntimeSession()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Re-start extended runtime if app comes back to foreground
            if newPhase == .active && store.currentSession != nil && extendedRuntimeSession == nil {
                startExtendedRuntimeSession()
            }
        }
    }
    
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if !showingSessionEnd, let start = session.startTime {
                    elapsedTime = Date().timeIntervalSince(start)
                    
                    // Check if 2 minutes have passed and we haven't reminded yet
                    if elapsedTime >= 120 && !hasShownTwoMinuteReminder {
                        hasShownTwoMinuteReminder = true
                        triggerTwoMinuteReminder()
                    }
                }
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func triggerTwoMinuteReminder() {
        // Haptic feedback - notification style (3 taps)
        WKInterfaceDevice.current().play(.notification)
        
        print("⏰ 2-minute reminder: Session still active")
    }
    
    private func startExtendedRuntimeSession() {
        #if os(watchOS)
        guard extendedRuntimeSession == nil else { return }
        
        let session = WKExtendedRuntimeSession()
        extendedRuntimeSession = session
        
        // Set up delegate if needed for more advanced handling
        session.start()
        
        print("✅ Extended runtime session started - screen will stay on like Workout app")
        #endif
    }
    
    private func endExtendedRuntimeSession() {
        #if os(watchOS)
        extendedRuntimeSession?.invalidate()
        extendedRuntimeSession = nil
        print("⏹️ Extended runtime session ended")
        #endif
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
                    
                    // Cancel Button
                    Button(action: {
                        // Cancel the session completely - don't save anything
                        store.cancelSession()
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
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
        
        // MUST use same container as iPhone app
        let containerIdentifier = "iCloud.rens-corp.Pee-Pee-Tracker"
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(containerIdentifier)
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ Watch: Shared ModelContainer initialized with CloudKit sync")
            print("📦 Container: \(containerIdentifier)")
            return container
        } catch {
            print("❌ Watch: Failed to create shared ModelContainer: \(error)")
            print("⚠️ CloudKit sync will NOT work. Check:")
            print("   1. iCloud capability enabled in Xcode")
            print("   2. Signed in with Apple ID")
            print("   3. Container '\(containerIdentifier)' exists")
            
            // Fallback to local-only
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                let container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("⚠️ Watch: Using local storage only (no sync)")
                return container
            } catch {
                fatalError("Watch: Could not create ModelContainer: \(error)")
            }
        }
    }()
}


#Preview {
    ContentView()
        .modelContainer(ModelContainer.shared)
}

