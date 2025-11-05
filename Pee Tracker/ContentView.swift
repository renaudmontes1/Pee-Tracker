//
//  ContentView.swift
//  Pee Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PeeSession.startTime, order: .reverse) private var sessions: [PeeSession]
    @StateObject private var store: SessionStore
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _store = StateObject(wrappedValue: SessionStore(modelContext: context, platformName: "iPhone"))
    }
    
    var body: some View {
        TabView {
            // Logging Tab
            LoggingView(store: store)
                .tabItem {
                    Label("Log", systemImage: "drop.fill")
                }
            
            // History Tab
            HistoryView(sessions: sessions)
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
            
            // Insights Tab
            InsightsView(sessions: sessions)
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            // Settings Tab
            SettingsView(sessions: sessions)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// Extension to share ModelContainer
extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([PeeSession.self])
        
        // MUST use same container as Watch app
        let containerIdentifier = "iCloud.rens-corp.Pee-Pee-Tracker"
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(containerIdentifier)
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ iPhone: Shared ModelContainer initialized with CloudKit sync")
            print("📦 Container: \(containerIdentifier)")
            return container
        } catch {
            print("❌ iPhone: Failed to create shared ModelContainer: \(error)")
            print("⚠️ CloudKit sync will NOT work. Check:")
            print("   1. iCloud capability enabled in Xcode")
            print("   2. Signed in with Apple ID")
            print("   3. Container '\(containerIdentifier)' exists")
            
            // Fallback to local-only
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                let container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("⚠️ iPhone: Using local storage only (no sync)")
                return container
            } catch {
                fatalError("iPhone: Could not create ModelContainer: \(error)")
            }
        }
    }()
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.shared)
}

