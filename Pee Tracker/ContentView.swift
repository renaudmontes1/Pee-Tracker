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
        _store = StateObject(wrappedValue: SessionStore(modelContext: context))
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
        
        // MUST use same container as app initialization
        let containerIdentifier = "iCloud.rens-corp.Pee-Pee-Tracker"
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(containerIdentifier)
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

